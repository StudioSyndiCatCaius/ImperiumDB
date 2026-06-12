## CSV Script to PDF Converter for Godot 4.6
## Pure GDScript implementation - NO external dependencies
##
## Usage:
##   var converter = CsvScriptToPdf.new()
##   var err = converter.CsvScriptToPDF("Title", "Summary", csv_string, "user://output.pdf")
##   if err == OK:
##       print("PDF saved!")

class_name CsvScriptToPdf
extends RefCounted

#region Constants
const PAGE_WIDTH := 612.0  # Letter size in points (8.5 inches)
const PAGE_HEIGHT := 792.0  # Letter size in points (11 inches)
const MARGIN_LEFT := 50.0
const MARGIN_RIGHT := 50.0
const MARGIN_TOP := 50.0
const MARGIN_BOTTOM := 50.0
const LINE_HEIGHT := 14.0
const HEADER_ROW_HEIGHT := 24.0
const DATA_ROW_HEIGHT := 18.0
const CELL_PADDING := 4.0

# Font sizes
const TITLE_FONT_SIZE := 24.0
const SUMMARY_FONT_SIZE := 12.0
const HEADER_FONT_SIZE := 10.0
const CELL_FONT_SIZE := 9.0
#endregion

#region Column Configuration
class ColumnConfig:
	var text_size: float = CELL_FONT_SIZE
	var text_bold: bool = false
	var text_color: Color = Color.BLACK
	var cell_color: Color = Color(-1, -1, -1)  # Invalid = use default alternating
	var size_ratio: float = 1.0
	
	func has_custom_cell_color() -> bool:
		return cell_color.r >= 0.0

var _column_configs: Dictionary = {}  # column_name (lowercase) -> ColumnConfig
#endregion

#region PDF Building State
var _objects: Array[String] = []
var _object_offsets: Array[int] = []
var _current_offset := 0
var _page_contents: Array[String] = []
var _page_ids: Array[int] = []
var _content_ids: Array[int] = []
var _output: PackedByteArray
#endregion

#region Main Public Function
## Convert CSV script to PDF
## @param title: Document title (large text)
## @param summary: Document summary (medium text)  
## @param csv_string: CSV data as string
## @param config: Optional styling config dictionary (see example below)
## @param output_path: Where to save the PDF (default: user://script_output.pdf)
## @return Error code (OK on success)
##
## Config example:
##   {
##       columns = {
##           character = { text_bold = true, text_size = 9, cell_color = "#abbeff" },
##           dialogue = { size_ratio = 2.0 },
##           direction = { cell_color = "#ffd86e", text_color = "#52481b" }
##       }
##   }
##
## Column config options:
##   - text_size: float (default 9.0)
##   - text_bold: bool (default false)
##   - text_color: String hex color like "#ff0000" (default black)
##   - cell_color: String hex color (default alternating gray/white)
##   - size_ratio: float multiplier for column width (default 1.0, all columns equal)

func CsvScriptToPDF(title: String, summary: String, csv_string: String, config: Dictionary = {}, output_path: String = "user://script_output.pdf") -> Error:
	print("[CsvScriptToPdf] Starting PDF generation...")
	print("[CsvScriptToPdf] Title: ", title)
	print("[CsvScriptToPdf] Output path: ", output_path)
	
	# Reset state
	_objects.clear()
	_object_offsets.clear()
	_page_contents.clear()
	_page_ids.clear()
	_content_ids.clear()
	_column_configs.clear()
	_current_offset = 0
	_output = PackedByteArray()
	
	# Validate inputs
	if title.strip_edges().is_empty():
		push_warning("[CsvScriptToPdf] Warning: Title is empty")
	
	if csv_string.strip_edges().is_empty():
		push_error("[CsvScriptToPdf] Error: CSV string is empty")
		return ERR_INVALID_DATA
	
	# Parse config
	if not config.is_empty():
		print("[CsvScriptToPdf] Parsing config with %d column settings..." % config.get("columns", {}).size())
	_parse_config(config)
	
	# Parse CSV
	print("[CsvScriptToPdf] Parsing CSV data...")
	var rows := _parse_csv(csv_string)
	if rows.is_empty():
		push_error("[CsvScriptToPdf] Error: CSV parsing resulted in no valid rows")
		return ERR_INVALID_DATA
	
	print("[CsvScriptToPdf] Parsed %d rows" % rows.size())
	
	# Store header names for column config lookup
	var headers: PackedStringArray = rows[0] if rows.size() > 0 else PackedStringArray()
	print("[CsvScriptToPdf] Columns: ", headers)
	
	if rows.size() < 2:
		push_warning("[CsvScriptToPdf] Warning: CSV has headers but no data rows")
	
	# Calculate column widths (applying size_ratio from config)
	var col_widths := _calculate_column_widths(rows, headers)
	if col_widths.is_empty():
		push_error("[CsvScriptToPdf] Error: Failed to calculate column widths")
		return ERR_INVALID_DATA
	
	# Generate page content
	print("[CsvScriptToPdf] Generating page content...")
	_generate_pages(title, summary, rows, col_widths, headers)
	
	if _page_contents.is_empty():
		push_error("[CsvScriptToPdf] Error: No pages were generated")
		return ERR_INVALID_DATA
	
	print("[CsvScriptToPdf] Generated %d page(s)" % _page_contents.size())
	
	# Build PDF structure
	print("[CsvScriptToPdf] Building PDF structure...")
	var pdf_data := _build_pdf()
	
	if pdf_data.is_empty():
		push_error("[CsvScriptToPdf] Error: PDF data is empty after building")
		return ERR_INVALID_DATA
	
	print("[CsvScriptToPdf] PDF data size: %d bytes" % pdf_data.length())
	
	# Ensure output directory exists
	var dir_path := output_path.get_base_dir()
	if not dir_path.is_empty():
		var dir := DirAccess.open("user://")
		if dir == null:
			push_error("[CsvScriptToPdf] Error: Cannot access user:// directory")
			return ERR_CANT_CREATE
		
		# Try to create directory if needed (for paths like user://subfolder/file.pdf)
		if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(dir_path)):
			var err := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))
			if err != OK:
				push_error("[CsvScriptToPdf] Error: Failed to create output directory '%s', error code: %d" % [dir_path, err])
				return err
	
	# Write to file
	print("[CsvScriptToPdf] Writing to file: ", output_path)
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		var err := FileAccess.get_open_error()
		push_error("[CsvScriptToPdf] Error: Failed to open file for writing '%s', error code: %d" % [output_path, err])
		match err:
			ERR_FILE_NOT_FOUND:
				push_error("[CsvScriptToPdf] -> File path not found or invalid")
			ERR_FILE_NO_PERMISSION:
				push_error("[CsvScriptToPdf] -> No permission to write to this location")
			ERR_FILE_ALREADY_IN_USE:
				push_error("[CsvScriptToPdf] -> File is already in use by another process")
			ERR_CANT_OPEN:
				push_error("[CsvScriptToPdf] -> Cannot open file (check path and permissions)")
			_:
				push_error("[CsvScriptToPdf] -> Unknown file error")
		return err
	
	file.store_buffer(pdf_data.to_utf8_buffer())
	file.close()
	
	# Verify file was written
	if not FileAccess.file_exists(output_path):
		push_error("[CsvScriptToPdf] Error: File was not created after writing")
		return ERR_CANT_CREATE
	
	var final_size := FileAccess.open(output_path, FileAccess.READ).get_length()
	print("[CsvScriptToPdf] Success! PDF created: %s (%d bytes)" % [output_path, final_size])
	print("[CsvScriptToPdf] Full path: ", ProjectSettings.globalize_path(output_path))
	
	return OK


## Parse the config dictionary and populate _column_configs
func _parse_config(config: Dictionary) -> void:
	if config.is_empty():
		return
	
	if not config.has("columns"):
		push_warning("[CsvScriptToPdf] Config provided but missing 'columns' key")
		return
	
	var columns_dict = config["columns"]
	if not columns_dict is Dictionary:
		push_error("[CsvScriptToPdf] Error: 'columns' must be a Dictionary")
		return
	
	for col_name in columns_dict.keys():
		# Skip blank/empty column names
		if str(col_name).strip_edges().is_empty():
			push_warning("[CsvScriptToPdf] Skipping blank column name in config")
			continue
		
		var settings = columns_dict[col_name]
		if not settings is Dictionary:
			push_warning("[CsvScriptToPdf] Skipping column '%s': settings must be a Dictionary" % col_name)
			continue
		
		var col_config := ColumnConfig.new()
		
		if settings.has("text_size"):
			var size = settings["text_size"]
			if size is float or size is int:
				col_config.text_size = float(size)
			else:
				push_warning("[CsvScriptToPdf] Column '%s': text_size must be a number, using default" % col_name)
		
		if settings.has("text_bold"):
			col_config.text_bold = bool(settings["text_bold"])
		
		if settings.has("text_color"):
			var color_str = str(settings["text_color"])
			if color_str.begins_with("#") and (color_str.length() == 7 or color_str.length() == 9):
				col_config.text_color = Color.html(color_str)
			else:
				push_warning("[CsvScriptToPdf] Column '%s': invalid text_color '%s', use hex format like '#FF0000'" % [col_name, color_str])
		
		if settings.has("cell_color"):
			var color_str = str(settings["cell_color"])
			if color_str.begins_with("#") and (color_str.length() == 7 or color_str.length() == 9):
				col_config.cell_color = Color.html(color_str)
			else:
				push_warning("[CsvScriptToPdf] Column '%s': invalid cell_color '%s', use hex format like '#FF0000'" % [col_name, color_str])
		
		if settings.has("size_ratio"):
			var ratio = settings["size_ratio"]
			if ratio is float or ratio is int:
				if float(ratio) > 0:
					col_config.size_ratio = float(ratio)
				else:
					push_warning("[CsvScriptToPdf] Column '%s': size_ratio must be positive, using default" % col_name)
			else:
				push_warning("[CsvScriptToPdf] Column '%s': size_ratio must be a number, using default" % col_name)
		
		_column_configs[str(col_name).to_lower()] = col_config
		print("[CsvScriptToPdf] Configured column '%s': size=%.1f, bold=%s, ratio=%.1f" % [col_name, col_config.text_size, col_config.text_bold, col_config.size_ratio])


## Get column config for a header name (returns null if not configured or blank)
func _get_column_config(header_name: String) -> ColumnConfig:
	# Exclude blank/empty column names
	if header_name.strip_edges().is_empty():
		return null
	
	var key := header_name.to_lower()
	if _column_configs.has(key):
		return _column_configs[key]
	return null
#endregion

#region CSV Parsing
func _parse_csv(csv_string: String) -> Array[PackedStringArray]:
	var rows: Array[PackedStringArray] = []
	var current_row: PackedStringArray = []
	var current_field := ""
	var in_quotes := false
	var i := 0
	var line_num := 1
	
	while i < csv_string.length():
		var c := csv_string[i]
		
		if c == '"':
			if in_quotes and i + 1 < csv_string.length() and csv_string[i + 1] == '"':
				# Escaped quote
				current_field += '"'
				i += 1
			else:
				in_quotes = not in_quotes
		elif c == ',' and not in_quotes:
			current_row.append(current_field.strip_edges())
			current_field = ""
		elif (c == '\n' or c == '\r') and not in_quotes:
			# Handle \r\n or \r or \n line endings
			if c == '\r' and i + 1 < csv_string.length() and csv_string[i + 1] == '\n':
				i += 1  # Skip the \n in \r\n
			
			# Finish current field and row
			current_row.append(current_field.strip_edges())
			current_field = ""
			
			# Only add non-empty rows (skip rows that are just commas or whitespace)
			if _is_row_valid(current_row):
				rows.append(current_row)
			current_row = []
			line_num += 1
		else:
			current_field += c
		
		i += 1
	
	# Don't forget the last field/row
	if not current_field.is_empty() or current_row.size() > 0:
		current_row.append(current_field.strip_edges())
		if _is_row_valid(current_row):
			rows.append(current_row)
	
	# Check for unclosed quotes
	if in_quotes:
		push_warning("[CsvScriptToPdf] Warning: CSV has unclosed quote - data may be malformed")
	
	# Remove trailing empty columns (caused by trailing commas)
	rows = _remove_trailing_empty_columns(rows)
	
	return rows


## Check if a row has any actual content (not just empty strings)
func _is_row_valid(row: PackedStringArray) -> bool:
	for field in row:
		if not field.strip_edges().is_empty():
			return true
	return false


## Remove columns from the end that are empty across all rows
func _remove_trailing_empty_columns(rows: Array[PackedStringArray]) -> Array[PackedStringArray]:
	if rows.is_empty():
		return rows
	
	# Find max column count
	var max_cols := 0
	for row in rows:
		max_cols = max(max_cols, row.size())
	
	# Check each column from the end to find trailing empty ones
	var last_non_empty_col := -1
	for col_idx in range(max_cols - 1, -1, -1):
		var col_has_content := false
		for row in rows:
			if col_idx < row.size() and not row[col_idx].strip_edges().is_empty():
				col_has_content = true
				break
		if col_has_content:
			last_non_empty_col = col_idx
			break
	
	# If all columns are empty or no trimming needed, return as-is
	if last_non_empty_col < 0:
		return rows
	if last_non_empty_col == max_cols - 1:
		return rows
	
	# Trim each row to remove trailing empty columns
	var trimmed_rows: Array[PackedStringArray] = []
	for row in rows:
		var trimmed_row: PackedStringArray = []
		for col_idx in range(min(row.size(), last_non_empty_col + 1)):
			trimmed_row.append(row[col_idx])
		trimmed_rows.append(trimmed_row)
	
	return trimmed_rows
#endregion

#region Column Width Calculation
func _calculate_column_widths(rows: Array[PackedStringArray], headers: PackedStringArray) -> PackedFloat64Array:
	if rows.is_empty():
		return PackedFloat64Array([PAGE_WIDTH - MARGIN_LEFT - MARGIN_RIGHT])
	
	var num_cols := 0
	for row in rows:
		num_cols = max(num_cols, row.size())
	
	if num_cols == 0:
		return PackedFloat64Array([PAGE_WIDTH - MARGIN_LEFT - MARGIN_RIGHT])
	
	# All columns start with equal ratio (1.0) unless config specifies otherwise
	var size_ratios: Array[float] = []
	size_ratios.resize(num_cols)
	for i in num_cols:
		size_ratios[i] = 1.0
		if i < headers.size():
			var cfg := _get_column_config(headers[i])
			if cfg != null:
				size_ratios[i] = cfg.size_ratio
	
	# Calculate total ratio
	var total_ratio := 0.0
	for ratio in size_ratios:
		total_ratio += ratio
	
	# Distribute available width based on ratios
	var available_width := PAGE_WIDTH - MARGIN_LEFT - MARGIN_RIGHT
	var widths := PackedFloat64Array()
	
	for i in num_cols:
		var proportion: float = size_ratios[i] / total_ratio if total_ratio > 0 else 1.0 / num_cols
		var width: float = proportion * available_width
		widths.append(width)
	
	return widths
#endregion

#region Page Content Generation
func _generate_pages(title: String, summary: String, rows: Array[PackedStringArray], col_widths: PackedFloat64Array, headers: PackedStringArray) -> void:
	var content := ""
	var y := PAGE_HEIGHT - MARGIN_TOP
	var page_num := 0
	var row_index := 0
	var is_first_page := true
	
	# Get headers (first row)
	var data_rows := rows.slice(1) if rows.size() > 1 else []
	
	while is_first_page or row_index < data_rows.size():
		content = ""
		y = PAGE_HEIGHT - MARGIN_TOP
		var table_start_y := y
		
		if is_first_page:
			# Draw title
			content += _draw_text(title, MARGIN_LEFT, y, TITLE_FONT_SIZE, true)
			y -= TITLE_FONT_SIZE + 20
			
			# Draw summary (with word wrap)
			if not summary.is_empty():
				var summary_lines := _wrap_text(summary, PAGE_WIDTH - MARGIN_LEFT - MARGIN_RIGHT, SUMMARY_FONT_SIZE)
				for line in summary_lines:
					content += _draw_text(line, MARGIN_LEFT, y, SUMMARY_FONT_SIZE, false)
					y -= LINE_HEIGHT
				y -= 20
			
			is_first_page = false
		
		# Remember where the table starts
		table_start_y = y
		
		# Draw table header
		content += _draw_table_header(headers, col_widths, y)
		y -= HEADER_ROW_HEIGHT
		
		# Draw data rows until page is full or no more data
		var rows_on_page := 0
		while row_index < data_rows.size():
			var row: PackedStringArray = data_rows[row_index]
			var row_height := _calculate_row_height(row, col_widths, headers)
			
			if y - row_height < MARGIN_BOTTOM:
				break  # Need new page
			
			var is_alt := (row_index % 2) == 1
			content += _draw_table_row(row, col_widths, y, row_height, is_alt, headers)
			y -= row_height
			row_index += 1
			rows_on_page += 1
		
		# Draw table border
		var table_height := table_start_y - y
		content += _draw_table_border(col_widths, table_start_y, table_height)
		
		_page_contents.append(content)
		page_num += 1
		
		# Safety: if no rows processed but more remain, skip one to prevent infinite loop
		if rows_on_page == 0 and row_index < data_rows.size():
			push_warning("[CsvScriptToPdf] Warning: Row %d too tall for page, skipping" % (row_index + 1))
			row_index += 1
#endregion

#region Text Drawing
func _draw_text(text: String, x: float, y: float, font_size: float, bold: bool, text_color: Color = Color.BLACK) -> String:
	var escaped := _escape_pdf_string(text)
	var font := "/F2" if bold else "/F1"
	var color_str := "%s %s %s rg\n" % [_float_str(text_color.r), _float_str(text_color.g), _float_str(text_color.b)]
	return color_str + "BT\n%s %s Tf\n%s %s Td\n(%s) Tj\nET\n" % [font, _float_str(font_size), _float_str(x), _float_str(y), escaped]


func _wrap_text(text: String, max_width: float, font_size: float) -> PackedStringArray:
	var lines: PackedStringArray = []
	var char_width := font_size * 0.55  # Conservative estimate for mixed case
	var max_chars := int(max_width / char_width)
	
	var words := text.split(" ")
	var current_line := ""
	
	for word in words:
		var test_line := (current_line + " " + word).strip_edges() if not current_line.is_empty() else word
		if test_line.length() > max_chars and not current_line.is_empty():
			lines.append(current_line)
			current_line = word
		else:
			current_line = test_line
	
	if not current_line.is_empty():
		lines.append(current_line)
	
	return lines


func _escape_pdf_string(text: String) -> String:
	var result := text
	result = result.replace("\\", "\\\\")
	result = result.replace("(", "\\(")
	result = result.replace(")", "\\)")
	result = result.replace("\n", "\\n")
	result = result.replace("\r", "\\r")
	result = result.replace("\t", "\\t")
	return result


func _float_str(value: float) -> String:
	# Format float without excessive decimals
	return "%.2f" % value
#endregion

#region Table Drawing
func _draw_table_header(headers: PackedStringArray, col_widths: PackedFloat64Array, y: float) -> String:
	var content := ""
	var x := MARGIN_LEFT
	
	# Calculate total width
	var total_width := 0.0
	for w in col_widths:
		total_width += w
	
	# Dark blue background: RGB(44, 62, 80) normalized
	content += "0.173 0.243 0.314 rg\n"
	content += "%s %s %s %s re f\n" % [_float_str(x), _float_str(y - HEADER_ROW_HEIGHT), _float_str(total_width), _float_str(HEADER_ROW_HEIGHT)]
	
	# Draw header text (white)
	for i in range(col_widths.size()):
		var cell_text := headers[i] if i < headers.size() else ""
		var truncated := _truncate_text(cell_text, col_widths[i], HEADER_FONT_SIZE)
		var text_y := y - HEADER_ROW_HEIGHT + CELL_PADDING + 4
		content += _draw_text(truncated, x + CELL_PADDING, text_y, HEADER_FONT_SIZE, true, Color.WHITE)
		x += col_widths[i]
	
	# Reset to black
	content += "0 0 0 rg\n"
	
	return content


func _draw_table_row(row: PackedStringArray, col_widths: PackedFloat64Array, y: float, row_height: float, is_alt: bool, headers: PackedStringArray) -> String:
	var content := ""
	var x := MARGIN_LEFT
	
	# Calculate total width
	var total_width := 0.0
	for w in col_widths:
		total_width += w
	
	# Draw cell backgrounds - either custom or default alternating
	for i in range(col_widths.size()):
		var cell_x := x
		for j in range(i):
			cell_x += col_widths[j]
		
		var bg_color: Color
		var cfg: ColumnConfig = null
		if i < headers.size():
			cfg = _get_column_config(headers[i])
		
		if cfg != null and cfg.has_custom_cell_color():
			bg_color = cfg.cell_color
		elif is_alt:
			bg_color = Color(0.941, 0.941, 0.941)  # Light gray
		else:
			bg_color = Color(0.98, 0.98, 0.98)  # Near white
		
		content += "%s %s %s rg\n" % [_float_str(bg_color.r), _float_str(bg_color.g), _float_str(bg_color.b)]
		content += "%s %s %s %s re f\n" % [_float_str(cell_x), _float_str(y - row_height), _float_str(col_widths[i]), _float_str(row_height)]
	
	# Draw horizontal line at bottom of row (very dark gray)
	content += "0.25 0.25 0.25 RG\n"
	content += "0.5 w\n"
	var row_bottom := y - row_height
	content += "%s %s m\n%s %s l S\n" % [_float_str(MARGIN_LEFT), _float_str(row_bottom), _float_str(MARGIN_LEFT + total_width), _float_str(row_bottom)]
	
	# Draw cell text
	x = MARGIN_LEFT
	for i in range(col_widths.size()):
		var cell_text := row[i] if i < row.size() else ""
		
		# Get column config for styling
		var cfg: ColumnConfig = null
		if i < headers.size():
			cfg = _get_column_config(headers[i])
		
		var font_size := CELL_FONT_SIZE
		var text_bold := false
		var text_color := Color.BLACK
		
		if cfg != null:
			font_size = cfg.text_size
			text_bold = cfg.text_bold
			text_color = cfg.text_color
		
		var cell_lines := _wrap_cell_text(cell_text, col_widths[i], font_size)
		var line_height := font_size * 1.4
		var text_y := y - CELL_PADDING - font_size
		
		for line in cell_lines:
			var truncated := _truncate_text(line, col_widths[i], font_size)
			content += _draw_text(truncated, x + CELL_PADDING, text_y, font_size, text_bold, text_color)
			text_y -= line_height
		
		x += col_widths[i]
	
	return content


func _draw_table_border(col_widths: PackedFloat64Array, top_y: float, height: float) -> String:
	var content := ""
	var x := MARGIN_LEFT
	
	var total_width := 0.0
	for w in col_widths:
		total_width += w
	
	# Set stroke color (very dark gray)
	content += "0.25 0.25 0.25 RG\n"
	content += "0.5 w\n"
	
	# Outer border
	content += "%s %s %s %s re S\n" % [_float_str(x), _float_str(top_y - height), _float_str(total_width), _float_str(height)]
	
	# Vertical lines between columns
	var col_x := MARGIN_LEFT
	for i in range(col_widths.size() - 1):
		col_x += col_widths[i]
		content += "%s %s m\n%s %s l S\n" % [_float_str(col_x), _float_str(top_y), _float_str(col_x), _float_str(top_y - height)]
	
	# Header bottom line (thicker, dark blue)
	content += "0.173 0.243 0.314 RG\n"
	content += "1.5 w\n"
	var header_bottom := top_y - HEADER_ROW_HEIGHT
	content += "%s %s m\n%s %s l S\n" % [_float_str(MARGIN_LEFT), _float_str(header_bottom), _float_str(MARGIN_LEFT + total_width), _float_str(header_bottom)]
	
	return content


func _calculate_row_height(row: PackedStringArray, col_widths: PackedFloat64Array, headers: PackedStringArray) -> float:
	var max_lines := 1
	
	for i in range(min(row.size(), col_widths.size())):
		# Get font size from config if available
		var font_size := CELL_FONT_SIZE
		if i < headers.size():
			var cfg := _get_column_config(headers[i])
			if cfg != null:
				font_size = cfg.text_size
		
		var cell_lines := _wrap_cell_text(row[i], col_widths[i], font_size)
		max_lines = max(max_lines, cell_lines.size())
	
	# Use largest configured font size for row height calculation
	var max_font_size := CELL_FONT_SIZE
	for i in range(col_widths.size()):
		if i < headers.size():
			var cfg := _get_column_config(headers[i])
			if cfg != null:
				max_font_size = max(max_font_size, cfg.text_size)
	
	var line_height := max_font_size * 1.4
	return max(DATA_ROW_HEIGHT, max_lines * line_height + CELL_PADDING * 2)


func _wrap_cell_text(text: String, cell_width: float, font_size: float) -> PackedStringArray:
	# Character width estimate - Helvetica averages ~0.5 * font_size for mixed case
	var char_width := font_size * 0.5
	var max_chars := int((cell_width - CELL_PADDING * 2) / char_width)
	max_chars = max(max_chars, 4)
	
	var lines: PackedStringArray = []
	var words := text.split(" ")
	var current_line := ""
	
	for word in words:
		# Handle very long words by breaking them
		while word.length() > max_chars:
			if current_line.is_empty():
				lines.append(word.substr(0, max_chars - 1) + "-")
				word = word.substr(max_chars - 1)
			else:
				lines.append(current_line)
				current_line = ""
		
		var test_line := (current_line + " " + word).strip_edges() if not current_line.is_empty() else word
		if test_line.length() > max_chars and not current_line.is_empty():
			lines.append(current_line)
			current_line = word
		else:
			current_line = test_line
	
	if not current_line.is_empty():
		lines.append(current_line)
	
	if lines.is_empty():
		lines.append("")
	
	return lines


func _truncate_text(text: String, max_width: float, font_size: float) -> String:
	var char_width := font_size * 0.5
	var max_chars := int((max_width - CELL_PADDING * 2) / char_width)
	
	if text.length() <= max_chars:
		return text
	
	return text.substr(0, max_chars - 3) + "..."
#endregion

#region PDF Structure Building
func _build_pdf() -> String:
	var pdf := ""
	_object_offsets.clear()
	
	# PDF Header
	pdf += "%%PDF-1.4\n"
	# Binary marker (signals this PDF contains binary data)
	pdf += "%%" + char(226) + char(227) + char(207) + char(211) + "\n"
	
	# Object 1: Catalog
	_object_offsets.append(pdf.length())
	pdf += "1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n"
	
	# Object 2: Pages
	_object_offsets.append(pdf.length())
	var page_refs := ""
	for i in range(_page_contents.size()):
		var page_obj_id := 5 + i * 2
		page_refs += "%d 0 R " % page_obj_id
		_page_ids.append(page_obj_id)
		_content_ids.append(page_obj_id + 1)
	pdf += "2 0 obj\n<< /Type /Pages /Kids [%s] /Count %d >>\nendobj\n" % [page_refs.strip_edges(), _page_contents.size()]
	
	# Object 3: Font (Helvetica)
	_object_offsets.append(pdf.length())
	pdf += "3 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>\nendobj\n"
	
	# Object 4: Font (Helvetica-Bold)
	_object_offsets.append(pdf.length())
	pdf += "4 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>\nendobj\n"
	
	# Page objects and content streams
	for i in range(_page_contents.size()):
		var page_id := _page_ids[i]
		var content_id := _content_ids[i]
		
		# Page object
		_object_offsets.append(pdf.length())
		pdf += "%d 0 obj\n" % page_id
		pdf += "<< /Type /Page /Parent 2 0 R "
		pdf += "/MediaBox [0 0 %s %s] " % [_float_str(PAGE_WIDTH), _float_str(PAGE_HEIGHT)]
		pdf += "/Contents %d 0 R " % content_id
		pdf += "/Resources << /Font << /F1 3 0 R /F2 4 0 R >> >> "
		pdf += ">>\nendobj\n"
		
		# Content stream
		var stream := _page_contents[i]
		_object_offsets.append(pdf.length())
		pdf += "%d 0 obj\n" % content_id
		pdf += "<< /Length %d >>\n" % stream.length()
		pdf += "stream\n"
		pdf += stream
		pdf += "endstream\nendobj\n"
	
	# Cross-reference table
	var xref_offset := pdf.length()
	var num_objects := _object_offsets.size() + 1
	pdf += "xref\n"
	pdf += "0 %d\n" % num_objects
	pdf += "0000000000 65535 f \n"
	
	for offset in _object_offsets:
		pdf += "%010d 00000 n \n" % offset
	
	# Trailer
	pdf += "trailer\n"
	pdf += "<< /Size %d /Root 1 0 R >>\n" % num_objects
	pdf += "startxref\n"
	pdf += "%d\n" % xref_offset
	pdf += "%%%%EOF\n"
	
	return pdf
#endregion
