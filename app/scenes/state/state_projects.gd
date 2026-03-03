extends Node

@export_category("Links")
@export var N_ProjList: Node
@export var N_Dialog_LoadProj: FileDialog
@export var N_Dialog_NewProj: FileDialog
@export var N_Confirm_RemoveProj: ConfirmationDialog

@onready var ref_UiProj= preload("res://app/scenes/ui/ui_Project.tscn")

var target_proj: res_project

func _ready():
	#if launching from command line project input:
	if !G.b_FirstOpen:
		G.b_FirstOpen=true
		if !PROJECT_TryLoad_Last():
			LIST_Rebuild()
	else:
		LIST_Rebuild()


func LIST_Refresh():
	for i in N_ProjList.get_children():
		if i.has_method("_refresh"):
			i._refresh()

func LIST_Rebuild():
	print("Rebuilding Projects list")
	G_Node.Children_ClearAll(N_ProjList)
	
	for i in G.list_projects:
		var new_proj: ui_Project=ref_UiProj.instantiate()
		new_proj.project=i
		new_proj.OnAction.connect(PROJECT_Action)
		N_ProjList.add_child(new_proj)

func PROJECT_TryLoad_Last():
	var i=G.PROJECT_GetFromPath(G.DATA_global.get('last_project',""))
	if i:
		PROJECT_Action(0,i)
		return true
	return false

func PROJECT_TryLoad_CommandLine():
	var cmd_args: PackedStringArray=OS.get_cmdline_args()
	if cmd_args.size()>0:
		var cmd_projPath=cmd_args[0]
		if !cmd_projPath.is_empty():
			var _tempProj: res_project=PROJECT_GetFromPath(cmd_projPath)
			if _tempProj!=null:
				PROJECT_Action(0,_tempProj)

func PROJECT_GetFromPath(path: String) -> res_project:
	return G.PROJECT_Load(path)

## 0= Load | 1=Delete
func PROJECT_Action(action: int, project: res_project):
	# ACTION -- LOAD PROJECT
	if action==0:
		G.list_projects.erase(project)
		G.list_projects.push_front(project)
		G.PROJECT_Open(project)
		get_tree().change_scene_to_file("res://app/scenes/state/STATE_Main.tscn")
	
	# ACTION -- DELETE PROJECT
	if action==1:
		target_proj=project
		N_Confirm_RemoveProj.visible=true


func _on_btn_open_pressed():
	N_Dialog_LoadProj.visible=true

func _on_file_dialog_load_file_selected(path):
	G.PROJECT_Load(path)
	LIST_Rebuild()

func _on_dialog_confirm_delete_confirmed():
	G.PROJECT_Remove(target_proj)
	LIST_Rebuild()


# ===============================================================
# Settings
# ===============================================================


func _on_btn_open_save_pressed():
	OS.shell_open(OS.get_user_data_dir())


# ===============================================================
# New Project
# ===============================================================

func _on_btn_new_pressed():
	N_Dialog_NewProj.popup()


func _on_dialog_new_file_selected(path):
	G.PROJECT_Create(path)
	LIST_Refresh()
