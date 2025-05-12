extends PanelContainer
class_name ui_FlowPin

var REF_NodeOwner: res_FlowNode_Inst
var pin_in: res_FlowPin
var pin_out: res_FlowPin

@export var N_text: RichTextLabel
@export var N_lbl_in: Label
@export var N_lbl_out: Label

func _ready():
	if pin_in:
		N_lbl_in.text=pin_in.name
	if pin_out:
		N_lbl_out.text=pin_out.name

func set_descript(text: String, val: int=10):
	N_text.text=text
	N_text.add_theme_font_size_override("normal_font_size",val)
