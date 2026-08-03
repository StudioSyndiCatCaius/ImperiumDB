extends Control


@export var opts_voice_ext: OptionButton
@onready var chk_cmdEnable: CheckButton = $ScrollContainer/VBoxContainer/GridContainer/box_CmdEnb/chk_cmdEnable


func _ready() -> void:
	opts_voice_ext.text = G.active_project.DATA.get("voice_ext", "wav")
	chk_cmdEnable.button_pressed = G.active_project.DATA.get("cmd_enabled", false)
	chk_cmdEnable.toggled.connect(_on_chk_cmd_enable_toggled)


func _on_opts_voice_ext_item_selected(index: int) -> void:
	G.active_project.DATA["voice_ext"] = opts_voice_ext.text


func _on_chk_cmd_enable_toggled(enabled: bool) -> void:
	G.active_project.DATA["cmd_enabled"] = enabled
	var _main := get_tree().current_scene
	if _main.has_method("CMD_Refresh"):
		_main.CMD_Refresh()
