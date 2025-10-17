extends PanelContainer
class_name ui_FlowPin

var pin_in: Dictionary
var pin_out: Dictionary

@export var N_text: RichTextLabel
@export var N_lbl_in: Label
@export var N_lbl_out: Label
@export var N_icon: TextureRect

func _ready():
	N_icon.visible=false
	if pin_in:
		N_lbl_in.text=pin_in.get('name','')
	if pin_out:
		N_lbl_out.text=pin_out.get('name','')

func set_descript(text: String, size: int=10):
	N_text.text=text
	N_text.add_theme_font_size_override("normal_font_size",size)

func set_icon(txt: Texture2D,size=50):
	if txt:
		N_icon.visible=true
		N_icon.texture=txt
		N_icon.custom_minimum_size.y=size
	else:
		N_icon.visible=false
