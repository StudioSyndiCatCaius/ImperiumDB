extends Node


@export var default_graph: res_FlowGraph

@export_category("Links")
@export var N_TabsMain: TabContainer
@export var N_TabGraphs: TabContainer
@export var N_ProjName: Label
@export var N_Dialog_save: FileDialog
@export var N_Dialog_confirm_quit: ConfirmationDialog
@export var N_TreeRoot: ui_FileTree

@onready var REF_GraphEdit:=preload("res://app/scenes/ui/ui_FlowGraph.tscn")


func _ready():
	if G_Project.active_project==null:
		G_Project.active_project=G_Save.list_projects[0]
	
	#Setup Linked Nodes
	N_ProjName.text=G_Project.active_project.name
	N_Dialog_save.root_subfolder=G_Project.PATH_GetRoot()+"/data/"
	
	
	#setup first graph
	G_Node.Children_ClearAll(N_TabGraphs)
	GRAPH_Open(default_graph)

func focus():
	return get_viewport().gui_get_focus_owner()

func _on_i_save_input_begin():
	var graph: ui_GraphEdit=N_TabGraphs.get_current_tab_control()
	SAVE_OBJECT(graph.current_graph)


var SAVE_data={}
var object_to_save: Object

func SAVE_OBJECT(object):
	if object!=null:
		object_to_save=object
		N_Dialog_save.popup()

func GRAPH_Open(graph : res_FlowGraph):
	var new_graph: ui_GraphEdit =REF_GraphEdit.instantiate()
	new_graph.current_graph=graph
	N_TabGraphs.add_child(new_graph)
	N_TabGraphs.current_tab+=1
	new_graph.GRAPH_Load(graph)
	



func _on_dialog_save_confirmed():
	print('imgo :'+N_Dialog_save.current_path)
	#G_File.SAVE_Json(SAVE_data,N_Dialog_save.current_path)


func _on_dialog_save_file_selected(path):
	if object_to_save!=null:
		if object_to_save.has_method("SAVE"):
			print('trying to save object')
			object_to_save.SAVE(path)

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
	if path.get_extension()=="ImpAsset":
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
