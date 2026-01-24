extends Control


@export var N_lbl_dir: Label
@export var N_lbl_spk: Label
@export var N_lbl_lin: Label
@export var N_ico: TextureRect

var node: ui_GraphNode

func _ready():
	
	var txt_dir=""
	var txt_line=""
	var txt_speaker=""
	if node:
		var params=node.DATA.get('params',{})
		txt_dir=node.DATA.get('direction',"")
		txt_speaker=params.get('speaker',"")
		txt_line=params.get('line',"")
	
	var _ico=G_Load.Texture_Icon("ico_characters_"+txt_speaker)
	if _ico:
		N_ico.texture=_ico
	
	if txt_line.is_empty() and txt_speaker.is_empty() and txt_dir.is_empty():
		queue_free()
	else:
		N_lbl_dir.text=txt_dir
		N_lbl_lin.text=txt_line
		N_lbl_spk.text=txt_speaker
