extends Node


var LOADED_Texture: Dictionary
var LOADED_SOUNDS: Dictionary

func Texture(_path: String) -> Texture2D:
	if LOADED_Texture.has(_path):
		return LOADED_Texture[_path]
	var path=G_File.PathCorrect(_path)
	
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
	texture.set_size_override(Vector2(50,50))
	LOADED_Texture[_path]=texture
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

func Texture_Icon(path: String):
	var _imgPath=G_Project.PATH_GetRoot()+"/image/"+path+".png"
	return G_Load.Texture(_imgPath)
	

func SOUND(path: String) -> AudioStream:
	if LOADED_SOUNDS.has(path):
		return LOADED_SOUNDS[path]
		
	var file_extension = path.get_extension().to_lower()
	print("attemptint to load SOUND: "+str(path))
	var _wavs=[
		"wav",
		"WAV",
		"Wav"
	]
	if _wavs.has(file_extension):
	   # WAV - Need to use ResourceLoader or load as a resource
		# For runtime loading of WAV files from user:// or absolute paths:
		
		var file = FileAccess.open(path, FileAccess.READ)
		if not file:
			push_error("Could not open file: " + path)
			return null
		
		var bytes = file.get_buffer(file.get_length())
		file.close()
		
		# Create AudioStreamWAV and load the data
		var audio_stream = AudioStreamWAV.new()
		audio_stream.data = bytes
		
		# You may need to set format properties based on the WAV file
		# Common defaults for 16-bit stereo WAV:
		audio_stream.format = AudioStreamWAV.FORMAT_16_BITS
		audio_stream.mix_rate = 44100  # Adjust based on your file
		audio_stream.stereo = true  # Adjust based on your file
		
		LOADED_SOUNDS[path]=audio_stream
		return audio_stream
	
	elif file_extension == "ogg":
		# For OGG, you can load it directly
		print("attemptint to load audio as OGG: ")
		var audio_stream = AudioStreamOggVorbis.load_from_file(path)

		return audio_stream
	print("Failed to load audio invalid files extension: "+str(file_extension))
	return null
