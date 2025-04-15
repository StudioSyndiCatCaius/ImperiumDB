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

@onready var ref_self=preload("res://app/scenes/ui/ui_FileTree.tscn")


signal FileAction(int,path)
signal FileDoubleClick(path)

func child_DlbClick(path):
	FileDoubleClick.emit(path)

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
	is_folder=!FileAccess.file_exists(path)
	N_BtnOpen.visible=is_folder
	if is_folder:
		N_BtnExpand.icon=icon_folder
		var path_raw=Path_Get().get_basename()
		if path_raw[-1]=="/":
			path_raw=G_String.Chop(path_raw,1,true)
		var str_parse=G_String.Split_AtCharacter(path_raw,"/",true)
		N_BtnExpand.text=str_parse[1]
	else:
		N_BtnExpand.icon=icon_file
		N_BtnExpand.text=Path_Get().get_file()
	
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
			N_SubitemList.add_child(new_item)
			new_item._ReloadPath()
		

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
