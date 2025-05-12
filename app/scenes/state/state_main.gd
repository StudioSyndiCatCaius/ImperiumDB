extends Node


@export var default_graph: res_FlowGraph

@export_category("Links")
@export var N_TabsMain: TabContainer
@export var N_TabGraphs: TabContainer
@export var N_ProjName: Label
@export var N_Dialog_save: FileDialog
@export var N_Dialog_confirm_quit: ConfirmationDialog
@export var N_TreeRoot: ui_FileTree
@export var N_img_logo: TextureRect

@onready var REF_GraphEdit:=preload("res://app/scenes/ui/ui_FlowGraph.tscn")


func _ready():
	if G_Project.active_project==null:
		G_Project.active_project=G_Save.list_projects[0]

	#Setup Linked Nodes
	N_ProjName.text=G_Project.active_project.name
	N_Dialog_save.root_subfolder=G_Project.PATH_GetRoot()+"/flow/"
	N_img_logo.texture=G_Project.active_project.image
	
	#setup first graph
	G_Node.Children_ClearAll(N_TabGraphs)
	GRAPH_Open(default_graph.duplicate(true))

func focus():
	return get_viewport().gui_get_focus_owner()

# =============================================================================
# Keyboard Inputs
# =============================================================================
func _on_i_save_input_begin():
	var graph: ui_GraphEdit=GRAPH_GetCurrent()
	if graph and graph.current_graph:
		if graph.current_graph.File_IsValid():
			SAVE_Confirm(graph.current_graph.linked_file,graph.current_graph)
		else:
			SAVE_Request(graph.current_graph)

func _on_i_new_input_begin():
	var _new = default_graph.duplicate(true)
	GRAPH_Open(_new)

var SAVE_data={}
var object_to_save: Object

func SAVE_Request(object):
	if object!=null:
		object_to_save=object
		N_Dialog_save.popup()

func SAVE_Confirm(path : String, obj=null):
	if obj:
		object_to_save=obj
	if object_to_save!=null:
		if object_to_save.has_method("SAVE"):
			print('trying to save object')
			object_to_save.SAVE(path)
	GRAPH_GetCurrent().GRAPH_Refresh()
	G_Log.Notification("File Saved: "+str(path),Color.GREEN)


func GRAPH_Open(graph : res_FlowGraph):
	var new_graph: ui_GraphEdit =REF_GraphEdit.instantiate()
	new_graph.current_graph=graph
	N_TabGraphs.add_child(new_graph)
	N_TabGraphs.current_tab+=1
	new_graph.GRAPH_Load(graph)
	

func GRAPH_GetCurrent() -> ui_GraphEdit:
	return N_TabGraphs.get_current_tab_control()

func GRAPH_GetFromPath(path: String) -> ui_GraphEdit:
	for i in N_TabGraphs.get_children():
		if i.current_graph.linked_file==path:
			return i
	return null


func _on_dialog_save_confirmed():
	print('imgo :'+N_Dialog_save.current_path)
	#G_File.SAVE_Json(SAVE_data,N_Dialog_save.current_path)


func _on_dialog_save_file_selected(path):
	SAVE_Confirm(path)

func _on_btn_quit_pressed():
	N_Dialog_confirm_quit.popup()



# ===============================================================
# MENU
# ===============================================================
func _on_menu_file_pressed():
	pass # Replace with function body.


func _on_ui_file_tree_tree_exiting():
	pass # Replace with function body.


func _on_dlg_confirm_quit_confirmed():
	get_tree().change_scene_to_file("res://app/scenes/state/STATE_Projects.tscn")


func _on_ui_file_tree_file_double_click(path: String):
	print(path.get_extension())
	if path.get_extension()=="ImpFlow":
		if GRAPH_GetFromPath(path):
			var _ind= N_TabGraphs.get_children().find(GRAPH_GetFromPath(path))
			N_TabGraphs.current_tab=_ind
		else:
			var new_graph= res_FlowGraph.new()
			new_graph.LOAD(path)
			GRAPH_Open(new_graph)


func _on_btn_open_root_pressed():
	OS.shell_open(G_Project.active_project.GetProjectDir())


func _on_btn_new_res_pressed():
	var _newEnt = res_Entity.new()
	var _savPath=G_Project.PATH_GetRoot()+"/entities/ent.tres"
	print("Saving: "+str(_newEnt)+" to "+_savPath)
	G_Resource.Save(_newEnt,_savPath)
