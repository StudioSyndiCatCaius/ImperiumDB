extends CodeEdit

# Your array of autocomplete strings
var autocomplete_functions = [
	"move_player",
	"jump_action", 
	"attack_enemy",
	"collect_item",
	"open_door",
	"save_game",
	"load_game"
]




func _ready():
	autocomplete_functions=[]
	
	for i in G.TABLE_GetItemList("script"):
		var args=i.split("(")[0]
		var input=i.split(")")[0]
		var t={
			method=i,
			display=args,
			input=input,
		}
		autocomplete_functions.push_back(t)
	
	
	# Connect the code completion request signal
	#code_completion_requested.connect(_on_code_completion_requested)
	
	# Enable code completion
	code_completion_enabled = true

func _request_code_completion(force):
	# Clear any existing completion options
	#clear_code_completion_options()

	# Get current text and cursor position to filter suggestions
	var current_line = get_line(get_caret_line())
	var current_word = get_current_word(current_line, get_caret_column())
	
	# Add each function as a completion option
	for f in autocomplete_functions:
		var func_name=f["display"]
		if current_word.is_empty() or func_name.begins_with(current_word):
			add_code_completion_option(
				CodeEdit.KIND_FUNCTION,  # Type of completion (function, variable, etc.)
				f["method"],               # Display text
				f["input"]+")",        # Insert text (what gets inserted)
				Color.CYAN,              # Color (optional)
				null,                    # Icon (optional)
				f["input"]+")"         # Default value (optional)
			)
	
	# Update the completion options
	update_code_completion_options(true)

# Helper function to get the current word being typed
func get_current_word(line: String, column: int) -> String:
	if column == 0:
		return ""
	
	var start = column
	var end = column
	
	# Find start of word
	while start > 0 and (line[start - 1].is_valid_identifier() or line[start - 1] == "_"):
		start -= 1
	
	return line.substr(start, end - start)


func _on_text_changed():
	_request_code_completion(true)
