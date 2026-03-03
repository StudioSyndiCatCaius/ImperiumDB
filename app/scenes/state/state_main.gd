extends Node


@export_category("Links")
@export var N_TabsMain: TabContainer
@export var N_TabGraphs: TabContainer
@export var N_ProjName: Label
@export var N_Dialog_save: FileDialog
@export var N_Dialog_confirm_quit: ConfirmationDialog
@export var N_TreeRoot: ui_FileTree
@export var N_img_logo: TextureRect

@export var n_window_playtest: Window
@export var n_playtest: STATE_playtest
@export var n_block_color: ColorRect


@onready var REF_GraphEdit:=preload("res://app/scenes/ui/ui_FlowGraph.tscn")


func _ready():
	if G.active_project==null:
		G.active_project=G.list_projects[0]
	
	#Setup Linked Nodes
	N_ProjName.text=G.active_project.name
	N_Dialog_save.root_subfolder=G.PATH_GetRoot()+"/flow/"
	N_img_logo.texture=G.active_project.image
	
	#setup first graph
	G_Node.Children_ClearAll(N_TabGraphs)
	GRAPH_Open(G_Lua.GRAPH_NewDefault())
	
	
func focus():
	return get_viewport().gui_get_focus_owner()

# =============================================================================
# Keyboard Inputs
# =============================================================================
func _on_i_save_input_begin():
	match(N_TabsMain.current_tab):
		0:
			var graph: ui_GraphEdit=GRAPH_GetCurrent()
			if graph:
				if FileAccess.file_exists(graph.file_path):
					SAVE_Confirm(graph.file_path,graph)
				else:
					SAVE_Request(graph)
	var _tab: Control=N_TabsMain.get_current_tab_control()
	if _tab and _tab.has_method("__SAVE"):
		_tab.__SAVE()

func _on_i_new_input_begin():
	var _new = G_Lua.GRAPH_NewDefault()
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
	#print("attempting to save: "+obj)
	if object_to_save!=null:
		if object_to_save.has_method("SAVE"):
			print('trying to save object: '+str(object_to_save))
			object_to_save.SAVE(path)
	GRAPH_GetCurrent().GRAPH_Refresh()

func GRAPH_OnEvent(graph: ui_GraphEdit, event: StringName, meta: Dictionary):
	print("Graph event: "+event+" on '"+str(graph)+"'")
	
	if event=="playtest":
		n_playtest.linked_graph=graph
		n_window_playtest.popup()
		n_block_color.visible=true
		n_block_color.mouse_filter=Control.MOUSE_FILTER_STOP

func PLAYTEST_IsActive():
	return n_window_playtest.visibile

func GRAPH_Open(graph: Dictionary,path:String=""):
	var new_graph: ui_GraphEdit =REF_GraphEdit.instantiate()
	new_graph.DATA=graph
	N_TabGraphs.add_child(new_graph)
	for i in N_TabGraphs.get_child_count():
		if N_TabGraphs.get_child(i)==new_graph:
			N_TabGraphs.current_tab=i
	if path!="":
		new_graph.file_path=path
	new_graph.OnGraphEvent.connect(GRAPH_OnEvent)
	new_graph.GRAPH_Load(graph)

func GRAPH_FromFile(file: String) -> Dictionary:
	var j=G_File.LOAD_Json(file)
	return j

func GRAPH_GetCurrent() -> ui_GraphEdit:
	return N_TabGraphs.get_current_tab_control()

func GRAPH_GetFromPath(path: String) -> ui_GraphEdit:
	for i in N_TabGraphs.get_children():
		if i.file_path==path:
			return i
	return null

func _on_dialog_save_confirmed():
	print('imgo :'+N_Dialog_save.current_path)
	#G_File.SAVE_Json(SAVE_data,N_Dialog_save.current_path)

func _on_dialog_save_file_selected(path):
	SAVE_Confirm(path,object_to_save)

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
	if path.get_extension()=="ImpFlow":
		# select if already open
		if GRAPH_GetFromPath(path):
			var _ind= N_TabGraphs.get_children().find(GRAPH_GetFromPath(path))
			N_TabGraphs.current_tab=_ind
		# open if not already open
		else:
			var new_graph={}
			new_graph=GRAPH_FromFile(path)
			GRAPH_Open(new_graph,path)

func _on_btn_open_root_pressed():
	OS.shell_open(G.active_project.GetProjectDir())

func _on_btn_new_res_pressed():
	var _newEnt = res_Entity.new()
	var _savPath=G.PATH_GetRoot()+"/entities/ent.tres"
	print("Saving: "+str(_newEnt)+" to "+_savPath)
	G_Resource.Save(_newEnt,_savPath)

func CMD_RerunScripts():
	G.PROJECT_RerunScripts()

func CMD_ReloadTables():
	pass # Replace with function body.

# ===============================================================
# MENU
# ===============================================================

func PLAYTEST_Stop():
	n_window_playtest.visible=false
	n_block_color.visible=false
	n_block_color.mouse_filter=Control.MOUSE_FILTER_IGNORE
