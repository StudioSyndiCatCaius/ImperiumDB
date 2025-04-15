extends Node


func Split_AtCharacter(string: String, character: String, reverse: bool) -> Array[String]:
	var result: Array[String] = ["", ""]
	var index = string.find(character)
	
	# If we're doing a reverse search, look for the last occurrence instead
	if reverse:
		index = string.rfind(character)
	
	# If the character isn't found, return the original string as the left part
	if index == -1:
		result[0] = string
		return result
	
	# Set the left and right parts
	result[0] = string.substr(0, index)           # Left part (before character)
	result[1] = string.substr(index + 1)          # Right part (after character)
	
	return result
	
func Chop(input_string: String, chars_to_remove: int, reverse: bool = false) -> String:
	# Check for edge cases
	if input_string.is_empty() or chars_to_remove >= input_string.length():
		return ""
	
	# If reverse is true, remove from the end (right)
	if reverse:
		return input_string.left(input_string.length() - chars_to_remove)
	# Otherwise, remove from the beginning (left)
	else:
		return input_string.substr(chars_to_remove)
