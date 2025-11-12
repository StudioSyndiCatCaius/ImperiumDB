extends Button
class_name ui_CmdButton


var cmd_key=""

signal OnSelect(key: String)

func _ready():
	text=cmd_key

func _on_pressed():
	OnSelect.emit(cmd_key)
