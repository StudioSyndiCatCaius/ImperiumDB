extends Node

@export_category("Links")
@export var N_ProjList: Node
@export var N_Dialog_LoadProj: FileDialog
@export var N_Dialog_NewProj: FileDialog
@export var N_Confirm_RemoveProj: ConfirmationDialog

@onready var ref_UiProj= preload("res://app/scenes/ui/ui_Project.tscn")

@onready var N_STATE_NewProject: Control = $STATE_NewProject
@onready var N_nProj_img: TextureRect = $"STATE_NewProject/PanelContainer/VBoxContainer/HBoxContainer/TextureRect"
@onready var N_nProj_name: TextEdit = $"STATE_NewProject/PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer/txtEdit_nProj_name"
@onready var N_nProj_id: TextEdit = $"STATE_NewProject/PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer/txtEdit_nProj_id"
@onready var N_nProj_path_lbl: Label = $"STATE_NewProject/PanelContainer/VBoxContainer/HBoxContainer2/ColorRect/lbl_projPath"

var target_proj: res_project
var _newproj_image_path := ""
var _newproj_folder_path := ""
var _newproj_dialog_img: FileDialog
var _newproj_dialog_folder: FileDialog

func _ready():
	N_STATE_NewProject.visible = false

	# Wire new project panel buttons
	var _btn_change_img = $"STATE_NewProject/PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer/btn_nProj_ChangeImg"
	var _btn_set_path = $"STATE_NewProject/PanelContainer/VBoxContainer/HBoxContainer2/btn_nProj_ChangeImg"
	var _btn_create = $"STATE_NewProject/PanelContainer/VBoxContainer/HBoxContainer3/btn_nProj_create"
	var _btn_cancel = $"STATE_NewProject/PanelContainer/VBoxContainer/HBoxContainer3/btn_nProj_cancel"
	_btn_change_img.pressed.connect(_on_btn_nProj_change_img_pressed)
	_btn_set_path.pressed.connect(_on_btn_nProj_set_path_pressed)
	_btn_create.pressed.connect(_on_btn_nProj_create_pressed)
	_btn_cancel.pressed.connect(_on_btn_nProj_cancel_pressed)

	# File dialog for picking a thumbnail image
	_newproj_dialog_img = FileDialog.new()
	_newproj_dialog_img.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_newproj_dialog_img.access = FileDialog.ACCESS_FILESYSTEM
	_newproj_dialog_img.filters = PackedStringArray(["*.png,*.jpg,*.jpeg ; Images"])
	_newproj_dialog_img.use_native_dialog = true
	_newproj_dialog_img.file_selected.connect(_on_newproj_img_selected)
	add_child(_newproj_dialog_img)

	# File dialog for picking the destination folder
	_newproj_dialog_folder = FileDialog.new()
	_newproj_dialog_folder.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	_newproj_dialog_folder.access = FileDialog.ACCESS_FILESYSTEM
	_newproj_dialog_folder.use_native_dialog = true
	_newproj_dialog_folder.dir_selected.connect(_on_newproj_folder_selected)
	add_child(_newproj_dialog_folder)

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
	NEWPROJ_Show()

func _on_dialog_new_file_selected(path):
	G.PROJECT_Create(path)
	LIST_Refresh()

func NEWPROJ_Show():
	_newproj_image_path = ""
	_newproj_folder_path = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS).path_join("ImperiumDB")
	N_nProj_name.text = ""
	N_nProj_id.text = ""
	N_nProj_img.texture = preload("res://icon.png")
	N_nProj_path_lbl.text = _newproj_folder_path
	N_STATE_NewProject.visible = true

func NEWPROJ_Hide():
	N_STATE_NewProject.visible = false

func _on_btn_nProj_cancel_pressed():
	NEWPROJ_Hide()

func _on_btn_nProj_change_img_pressed():
	_newproj_dialog_img.popup()

func _on_btn_nProj_set_path_pressed():
	_newproj_dialog_folder.current_dir = _newproj_folder_path
	_newproj_dialog_folder.popup()

func _on_newproj_img_selected(path: String):
	_newproj_image_path = path
	var img = G_File.LOAD_Texture(path)
	if img:
		N_nProj_img.texture = img

func _on_newproj_folder_selected(path: String):
	_newproj_folder_path = path
	N_nProj_path_lbl.text = path

func _on_btn_nProj_create_pressed():
	NEWPROJ_Create()

func NEWPROJ_Create():
	var proj_name := N_nProj_name.text.strip_edges()
	var proj_id := N_nProj_id.text.strip_edges()

	if proj_name.is_empty():
		proj_name = "Untitled"
	if proj_id.is_empty():
		proj_id = proj_name.to_lower().replace(" ", "_")
	if _newproj_folder_path.is_empty():
		_newproj_folder_path = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS).path_join("ImperiumDB")

	var template_path: String = G.get_executable_directory_path() + "_TEMPLATE"
	var dest_dir := _newproj_folder_path.path_join(proj_id)

	# Clone the template folder into dest_dir
	if !NEWPROJ_CopyFolder(template_path, dest_dir):
		push_error("Failed to copy template to: " + dest_dir)
		return

	var _dir := DirAccess.open(dest_dir)
	if _dir == null:
		push_error("Cannot open new project dir: " + dest_dir)
		return

	# Rename TEMPLATE.IDBproj → {proj_id}.IDBproj
	_dir.rename("TEMPLATE.IDBproj", proj_id + ".IDBproj")
	var proj_file := dest_dir.path_join(proj_id + ".IDBproj")

	# Set project name in the file
	var proj_data := G_File.LOAD_Json(proj_file, {})
	proj_data['name'] = proj_name
	G_File.SAVE_Json(proj_data, proj_file)

	# Rename TEMPLATE.png → {proj_id}.png, then overwrite if custom image chosen
	_dir.rename("TEMPLATE.png", proj_id + ".png")
	var thumb_path := dest_dir.path_join(proj_id + ".png")
	if !_newproj_image_path.is_empty():
		G_File.DUPLICATE(_newproj_image_path, thumb_path)

	# Remove the Godot import sidecar — not needed at runtime
	var import_file := dest_dir.path_join("TEMPLATE.png.import")
	if FileAccess.file_exists(import_file):
		DirAccess.remove_absolute(import_file)

	G.PROJECT_Load(proj_file)
	LIST_Rebuild()
	NEWPROJ_Hide()

func NEWPROJ_CopyFolder(src: String, dst: String) -> bool:
	var err := DirAccess.make_dir_recursive_absolute(dst)
	if err != OK and err != ERR_ALREADY_EXISTS:
		return false
	var dir := DirAccess.open(src)
	if dir == null:
		return false
	dir.list_dir_begin()
	var item := dir.get_next()
	while item != "":
		if item != "." and item != "..":
			var src_path := src.path_join(item)
			var dst_path := dst.path_join(item)
			if dir.current_is_dir():
				NEWPROJ_CopyFolder(src_path, dst_path)
			else:
				G_File.DUPLICATE(src_path, dst_path)
		item = dir.get_next()
	dir.list_dir_end()
	return true
