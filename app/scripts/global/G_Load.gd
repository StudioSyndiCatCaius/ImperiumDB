extends Node


func Texture(path: String) -> Texture2D:
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

func GLTF(path: String) -> Node:
	var gltf_document = GLTFDocument.new()
	var gltf_state = GLTFState.new()
	
	var error = gltf_document.append_from_file(path, gltf_state)
	if error != OK:
		print("Failed to load GLTF: ", error)
		return null
	
	var scene = gltf_document.generate_scene(gltf_state)
	return scene
