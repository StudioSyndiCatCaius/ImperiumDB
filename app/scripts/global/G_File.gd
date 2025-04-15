extends Node


signal OnFilesUpdated

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

func LOAD_Texture(path: String) -> Texture2D:
	
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

func LIST_AllInDir(path: String, include_full_path: bool = true) -> Array[String]:
	var result: Array[String] = []
	
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
