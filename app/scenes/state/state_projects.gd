extends Node

@export_category("Links")
@export var N_ProjList: Node
@export var N_Dialog_LoadProj: FileDialog
@export var N_Confirm_RemoveProj: ConfirmationDialog

@onready var ref_UiProj= preload("res://app/scenes/ui/ui_Project.tscn")

var target_proj: res_project

func _ready():
	LIST_Rebuild()

func LIST_Refresh():
	for i in N_ProjList.get_children():
		if i.has_method("_refresh"):
			i._refresh()

func LIST_Rebuild():
	print("Rebuilding Projects list")
	G_Node.Children_ClearAll(N_ProjList)
	
	for i in G_Project.list_projects:
		var new_proj: ui_Project=ref_UiProj.instantiate()
		new_proj.project=i
		new_proj.OnAction.connect(PROJECT_Action)
		N_ProjList.add_child(new_proj)

func PROJECT_Action(action: int, project: res_project):
	
	# ACTION -- LOAD PROJECT
	if action==0:
		G_Project.LOAD(project)
		get_tree().change_scene_to_file("res://app/scenes/state/STATE_Main.tscn")
	
	# ACTION -- DELETE PROJECT
	if action==1:
		target_proj=project
		N_Confirm_RemoveProj.visible=true


func _on_btn_open_pressed():
	N_Dialog_LoadProj.visible=true

func _on_file_dialog_load_file_selected(path):
	G_Project.PROJECT_Load(path)
	LIST_Rebuild()

func _on_dialog_confirm_delete_confirmed():
	G_Project.PROJECT_Remove(target_proj)
	LIST_Rebuild()


# ===============================================================
# Settings
# ===============================================================


func _on_btn_open_save_pressed():
	OS.shell_open(OS.get_user_data_dir())
