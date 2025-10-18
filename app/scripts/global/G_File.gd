extends Node


signal OnFilesUpdated

@export var csv_imports={
	
}

# ==============================================================================
# Json
# ==============================================================================
func LOAD_Json(path: String) -> Dictionary:
	print("___ Loading Json: "+path+"___")
	if not FileAccess.file_exists(path):
		print("File doesn't exist: " + path)
		return {}
	
	 # Open the file
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		print("Error opening file: " + path)
		print("Error code: " + str(FileAccess.get_open_error()))
		return {}
		
	# Read the content as text
	var json_text = file.get_as_text()
	 # Parse the JSON
	var json = JSON.new()
	var error = json.parse(json_text)
	
	# Check for errors
	if error != OK:
		print("JSON Parse Error: ", json.get_error_message(), " at line ", json.get_error_line())
		return {}
	
	# Get and return the data
	var data = json.get_data()
	return data


func SAVE_Json(data: Dictionary, file_path: String):
	# Extract the directory path from the file path
	var dir_path = file_path.get_base_dir()
	
	# Create directories if they don't exist
	if dir_path != "" and not DirAccess.dir_exists_absolute(dir_path):
		var error = DirAccess.make_dir_recursive_absolute(dir_path)
		if error != OK:
			print("Error creating directories: " + dir_path)
			print("Error code: " + str(error))
			return false
	
	# Create the JSON string
	var json_string = JSON.stringify(data, "  ")  # Pretty print with 2-space indentation
	
	# Open the file for writing
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		print("Error opening file for writing: " + file_path)
		print("Error code: " + str(FileAccess.get_open_error()))
		return false
	
	# Write the JSON string to the file
	file.store_string(json_string)
	OnFilesUpdated.emit()
	return true

# ==============================================================================
# Texture
# ==============================================================================
func PathCorrect(path: String):
	var st: String=path
	st=st.replace("{project}",G_Project.PATH_GetRoot())
	return st

func LOAD_String(_file_path: String) -> String:
	var file_content = ""
	var file_path=""
	file_path=PathCorrect(_file_path)
	var file = FileAccess.open(file_path, FileAccess.READ)

	if file:
		file_content = file.get_as_text()
		file.close()
	else:
		print("Error: Could not open file at path: ", file_path)

	return file_content

func LOAD_Texture(_path: String,useImageFolder=false) -> Texture2D:
	var path=PathCorrect(_path)
	
	print("___ Loading Image: "+path+"___")
	# Create a new image
	var image = Image.new()
	
	# Load the image from the external path
	var error = image.load(path)
	
	# Check if the image was loaded successfully
	if error != OK:
		push_error("Failed to load image from path: " + path)
		return null
	
	# Create a texture from the image
	var texture = ImageTexture.create_from_image(image)
	
	return texture

# ==============================================================================
# Texture
# ==============================================================================

func FILES_SortByExtension(paths: PackedStringArray) -> PackedStringArray:
	var folders := []
	var files := []
	
	# Separate folders from files
	for path in paths:
		if path.ends_with("/") or DirAccess.dir_exists_absolute(path):
			folders.append(path)
		else:
			files.append(path)
	
	# Sort folders alphabetically
	folders.sort()
	
	# Sort files by extension, then by name
	files.sort_custom(func(a: String, b: String) -> bool:
		var ext_a: String = a.get_extension().to_lower()
		var ext_b: String = b.get_extension().to_lower()
		
		if ext_a == ext_b:
			# Same extension, sort by full path
			return a.naturalnocasecmp_to(b) < 0
		else:
			# Different extensions, sort by extension
			return ext_a.naturalnocasecmp_to(ext_b) < 0
	)
	
	# Combine: folders first, then files
	var result: PackedStringArray = []
	result.append_array(folders)
	result.append_array(files)
	
	return result

func LIST_AllInDir(_path: String, include_full_path: bool = true) -> Array[String]:
	var result: Array[String] = []
	var path: String=PathCorrect(_path)
	# Check if the directory exists
	if not DirAccess.dir_exists_absolute(path):
		print("Directory does not exist: ", path)
		return result
	
	# Make sure path ends with a slash for path joining
	if not path.ends_with("/"):
		path += "/"
	
	# Open the directory
	var dir = DirAccess.open(path)
	if dir == null:
		print("Failed to open directory: ", path)
		print("Error: ", error_string(DirAccess.get_open_error()))
		return result
	
	# Start listing the content
	dir.list_dir_begin()
	
	while true:
		var file_name = dir.get_next()
		
		# If we've reached the end of the list, break the loop
		if file_name == "":
			break
			
		# Skip "." and ".." directories
		if file_name == "." or file_name == "..":
			continue
		
		# Add the item to the result array (with full path if requested)
		if include_full_path:
			result.append(path + file_name)
		else:
			result.append(file_name)
	
	# End the listing process
	dir.list_dir_end()
	
	return result


func CSV_Import(csv_file_path: String) -> Dictionary:
	var result = {}
	var file = FileAccess.open(csv_file_path, FileAccess.READ)
	
	if file == null:
		print("Error opening file: ", FileAccess.get_open_error())
		return result
	
	# Read header row
	var header = file.get_csv_line()
	if header.size() <= 1:
		print("CSV file must have at least two columns")
		return result
	
	# Store the keys for values (excluding the first column which is for entry keys)
	var value_keys = []
	for i in range(1, header.size()):
		value_keys.append(header[i])
	
	# Process data rows
	while !file.eof_reached():
		var row = file.get_csv_line()
		
		# Skip empty rows or rows with insufficient data
		if row.size() <= 1 or row[0].strip_edges() == "":
			continue
			
		var entry_key = row[0]
		var entry_values = {}
		
		# Add values to the entry dictionary
		for i in range(1, min(row.size(), value_keys.size() + 1)):
			var value = row[i]
			
			# Try to convert numerical values
			if value.is_valid_int():
				value = value.to_int()
			elif value.is_valid_float():
				value = value.to_float()
				
			entry_values[value_keys[i - 1]] = value
		
		# Add the entry to the result dictionary
		result[entry_key] = entry_values
	csv_imports[csv_file_path]=result
	return result


func DUPLICATE_Autoname(source_path: String) -> String:
	# Extract the base directory, filename, and extension
	var dir_path = source_path.get_base_dir()
	var file_name = source_path.get_file().get_basename()
	var file_extension = source_path.get_extension()
	
	# Initialize variables for the new path
	var new_file_name = ""
	var new_path = ""
	var counter = 1
	
	# Keep checking until we find a filename that doesn't exist
	while true:
		if counter == 1:
			new_file_name = file_name + " - Copy"
		else:
			new_file_name = file_name + " - Copy (" + str(counter) + ")"
		
		new_path = dir_path.path_join(new_file_name + "." + file_extension)
		
		# Check if the new path already exists
		if not FileAccess.file_exists(new_path):
			break
			
		# Increment counter and try again
		counter += 1
	
	# Now that we have a unique filename, duplicate the file
	var result = DUPLICATE(source_path, new_path)
	
	if result:
		print("File duplicated successfully to: ", new_path)
		return new_path
	else:
		print("Failed to duplicate file")
		return ""

# The original duplicate_file function from before
func DUPLICATE(source_path: String, destination_path: String) -> bool:
	# Check if source file exists
	if not FileAccess.file_exists(source_path):
		print("Source file doesn't exist: ", source_path)
		return false
	
	# Open the source file for reading
	var source_file = FileAccess.open(source_path, FileAccess.READ)
	if source_file == null:
		print("Failed to open source file: ", FileAccess.get_open_error())
		return false
	
	# Open the destination file for writing
	var destination_file = FileAccess.open(destination_path, FileAccess.WRITE)
	if destination_file == null:
		print("Failed to open destination file: ", FileAccess.get_open_error())
		source_file.close()
		return false
	
	# Read the entire content from the source file
	var content = source_file.get_buffer(source_file.get_length())
	
	# Write the content to the destination file
	destination_file.store_buffer(content)
	
	# Close both files
	source_file.close()
	destination_file.close()
	
	return true

func RENAME(file_path: String, new_base_name: String) -> bool:
	# Check if the file exists
	if not FileAccess.file_exists(file_path):
		print("File doesn't exist: ", file_path)
		return false
	
	# Get the directory, original filename, and extension
	var dir_path = file_path.get_base_dir()
	var extension = file_path.get_extension()
	
	# Create the new path with new base name but same path and extension
	var new_path = dir_path.path_join(new_base_name + "." + extension)
	
	# Get access to the directory
	var dir = DirAccess.open(dir_path)
	if dir == null:
		print("Error opening directory: ", DirAccess.get_open_error())
		return false
	
	# Perform the rename operation
	var error = dir.rename(file_path.get_file(), new_base_name + "." + extension)
	
	# Check if rename was successful
	if error != OK:
		print("Failed to rename file: ", error)
		return false
	
	print("Successfully renamed file from ", file_path, " to ", new_path)
	return true

func FOLDER_New(base_path: String, folder_name: String = "New Folder") -> String:
	# Ensure the base path exists
	if not DirAccess.dir_exists_absolute(base_path):
		print("Base directory doesn't exist: ", base_path)
		return ""
	
	# Open the base directory
	var dir = DirAccess.open(base_path)
	if dir == null:
		print("Error opening directory: ", DirAccess.get_open_error())
		return ""
	
	# Initialize variables for the new folder name
	var new_folder_name = folder_name
	var counter = 1
	var new_folder_path = ""
	
	# Keep checking until we find a folder name that doesn't exist
	while true:
		if counter == 1:
			new_folder_path = base_path.path_join(new_folder_name)
		else:
			new_folder_path = base_path.path_join(new_folder_name + " (" + str(counter) + ")")
		
		# Check if the new folder path already exists
		if not DirAccess.dir_exists_absolute(new_folder_path):
			break
			
		# Increment counter and try again
		counter += 1
	
	# Create the new folder
	var error = dir.make_dir(new_folder_path.get_file())
	
	# Check if folder creation was successful
	if error != OK:
		print("Failed to create folder: ", error)
		return ""
	
	print("Successfully created folder: ", new_folder_path)
	return new_folder_path
