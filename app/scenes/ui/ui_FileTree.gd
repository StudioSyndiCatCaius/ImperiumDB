extends Control
class_name ui_FileTree

@export var path: String
@export var is_project_relative: bool

@export var icon_folder: Texture2D
@export var icon_file: Texture2D

@export_category("Links")
@export var N_BtnOpen: Button
@export var N_BtnExpand: Button
@export var N_icon: TextureRect
@export var N_SubitemRoot: Control
@export var N_SubitemList: VBoxContainer
@export var N_timer_dblClk: Timer
@export var N_popup_file: PopupMenu
@export var N_popup_folder: PopupMenu
@export var N_confirm_delete: ConfirmationDialog
@export var N_TxtEdit_name: TextEdit
@export var N_lbl_fileCount: Label

@onready var ref_self=preload("res://app/scenes/ui/ui_FileTree.tscn")

## generic file action signal
## Parameters:
## - Int: 0=pressed | 1=duplicate | 2=delete
## - value: The point value of the collected item
signal FileAction(Int,path)
signal FileDoubleClick(path)

func child_action(action,path):
	if action!=0:
		_ReloadPath()

func child_DlbClick(path):
	FileDoubleClick.emit(path)
	print('im gud')

var is_expanded=false
var is_folder: bool

func _ready():
	G_File.OnFilesUpdated.connect(_ReloadPath)
	is_expanded=G_Project.active_project.tree_expansion.get(path,false)
	N_SubitemRoot.visible=false
	_ReloadPath()


func Path_Get() -> String:
	if is_project_relative:
		return G_Project.PATH_GetRoot()+path
	return path

func _ReloadPath():
	N_lbl_fileCount.text=""
	is_folder=!FileAccess.file_exists(path)
	N_BtnOpen.visible=is_folder
	FileName_Refresh()
	SetExpanded(is_expanded)


func SetExpanded(_expanded: bool):
	is_expanded=_expanded
	G_Project.active_project.tree_expansion[path]=is_expanded
	N_SubitemRoot.visible=is_expanded
	G_Node.Children_ClearAll(N_SubitemList)
	if is_expanded:
		print('try load: '+Path_Get())
		for i in G_File.LIST_AllInDir(Path_Get()):
			print('adding item: '+i)
			var new_item: ui_FileTree = ref_self.instantiate()
			new_item.path=i
			new_item.FileDoubleClick.connect(child_DlbClick)
			new_item.FileAction.connect(child_action)
			N_SubitemList.add_child(new_item)
			new_item._ReloadPath()
		

func FileName_SetState(state: int):
	if state==1:
		N_TxtEdit_name.text=N_BtnExpand.text.get_basename()
		N_TxtEdit_name.visible=true
		N_TxtEdit_name.grab_focus()
	elif  state==0:
		N_TxtEdit_name.visible=false
		FileName_Refresh()

func FileName_Refresh():
	if is_folder:
		N_BtnExpand.icon=icon_folder
		var path_raw=Path_Get().get_basename()
		if path_raw[-1]=="/":
			path_raw=G_String.Chop(path_raw,1,true)
		var str_parse=G_String.Split_AtCharacter(path_raw,"/",true)
		N_BtnExpand.text=str_parse[1]
		N_lbl_fileCount.text=(str(G_File.LIST_AllInDir(path).size())+" files")
	else:
		N_BtnExpand.icon=icon_file
		N_BtnExpand.text=Path_Get().get_file()


var can_bldClk=false
func _on_btn_expand_pressed():
	if can_bldClk:
		FileDoubleClick.emit(path)
		print('idub')
		can_bldClk=false
	else:
		N_timer_dblClk.start(0)
		can_bldClk=true
	FileAction.emit(0,path)
	if is_folder:
		SetExpanded(!is_expanded)


func _on_timer_dbl_click_timeout():
	can_bldClk=false

func _on_btn_open_pressed():
	if is_folder:
		OS.shell_open(Path_Get())

func _on_button_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var _n: PopupMenu
			if is_folder:
				_n=N_popup_folder
				N_popup_folder.popup()
			else:
				_n=N_popup_file
				N_popup_file.popup()
			_n.position=get_global_mouse_position()


func _on_popup_file_index_pressed(index):
	# TRY Duplicarte file
	if index==0:
		G_File.DUPLICATE_Autoname(path)
		FileAction.emit(1,path)
	# TRY delte file
	if index==1:
		N_confirm_delete.popup()
	if index==2:
		FileName_SetState(1)

func _on_confrim_delete_confirmed():
	var dir = DirAccess.open(path.get_base_dir())
	if dir.file_exists(path):
		FileAction.emit(2,path)
		dir.remove(path.get_file())
		queue_free()

func _on_tedit_name_focus_exited():
	G_File.RENAME(path,N_TxtEdit_name.text)
	FileName_SetState(0)


func _on_popup_folder_index_pressed(index):
	if index==0:
		G_File.FOLDER_New(path)
		_ReloadPath()
	if index==1:
		FileName_SetState(1)
