extends PanelContainer
class_name ui_Project

var project: res_project

signal OnAction(int,res_project)

@export_category("Links")
@export var N_name: Label
@export var N_path: Label
@export var N_image: TextureRect

func _ready():
	_refresh()

func _refresh():
	if project:
		if N_name:
			N_name.text=project.name
		if N_path:
			N_path.text=project.path
			N_path.visible=!G_Save.dic_projects.get("hide_path",false)
		if N_image:
			N_image.texture=project.image

func _on_btn_open_pressed():
	OnAction.emit(0,project)

func _on_btn_delete_pressed():
	OnAction.emit(1,project)
