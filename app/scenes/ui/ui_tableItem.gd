extends PanelContainer


@export_category("links")
@export var N_name: Label
@export var N_desc: Label
@export var N_icon: TextureRect


func DATA_set(dic: Dictionary):
	N_name.text=dic.get("name","")
	N_desc.text=dic.get("description","")
	#N_icon.texture=.LOAD_Texture(dic.get("icon",""))
