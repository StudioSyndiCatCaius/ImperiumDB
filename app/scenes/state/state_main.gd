extends Node


@export_category("Links")
@export var N_TabsMain: TabContainer
@export var N_TabGraphs: TabContainer
@export var N_ProjName: Label
@export var N_Dialog_save: FileDialog
@export var N_Dialog_confirm_quit: ConfirmationDialog
@export var N_img_logo: TextureRect
@export var n_fileTree: Zen_FileTree

@export var n_window_playtest: Window
@export var n_playtest: STATE_playtest
@export var n_block_color: ColorRect
@export var n_TxtEdit_TreeFilter: TextEdit

@onready var REF_GraphEdit:=preload("res://app/scenes/ui/ui_FlowGraph.tscn")

func _ready():
	if G.active_project==null:
		G.active_project=G.list_projects[0]

	#Setup Linked Nodes
	N_ProjName.text=G.active_project.name
	N_Dialog_save.root_subfolder=G.PATH_GetRoot()+"/flow/"
	N_img_logo.texture=G.active_project.image

	#setup graphs — restore previous session or open a blank graph
	G_Node.Children_ClearAll(N_TabGraphs)
	var _session_paths: Array = G.active_project.UserData_Get().get('open_graphs', [])
	var _restored := 0
	for _p in _session_paths:
		if FileAccess.file_exists(_p):
			GRAPH_Open(GRAPH_FromFile(_p), _p)
			_restored += 1
	if _restored == 0:
		GRAPH_Open(G.GRAPH_NewDefault())

	n_fileTree.root_path=G.PATH_GetRoot()+"/flow/"
	FileTree_Rebuild()
	n_fileTree.set_expanded_bulk(G.active_project.DATA.get('tree_expansion',{}))

func _exit_tree():
	var _open_paths: Array = []
	for _graph in N_TabGraphs.get_children():
		if _graph is ui_GraphEdit and _graph.file_path != "":
			_open_paths.append(_graph.file_path)
	G.active_project.UserData_Get()['open_graphs'] = _open_paths
	
func focus():
	return get_viewport().gui_get_focus_owner()

# =============================================================================
# FILE TREE
# =============================================================================

func FileTree_Rebuild():
	n_fileTree.rebuild_tree()

func FileTree_SaveState():
	G.active_project.DATA['tree_expansion']=n_fileTree.get_expanded_bulk()

func _on_file_tree_file_selected(file_path):
	FileTree_SaveState()
	if file_path.get_extension() == "ImpFlow":
		var existing: ui_GraphEdit = GRAPH_GetFromPath(file_path)
		if existing:
			N_TabGraphs.current_tab = N_TabGraphs.get_children().find(existing)
		else:
			GRAPH_Open(GRAPH_FromFile(file_path), file_path)

func _on_file_tree_option_menu_visibility_changed(visible):
	pass # Replace with function body.

func _on_file_tree_menu_option_selected(option_label, file_path, option_index):
	if option_label=="Open Folder":
		OS.shell_open(file_path)

func _on_txt_edit_tree_filter_text_changed():
	n_fileTree.name_filter=n_TxtEdit_TreeFilter.text
	FileTree_Rebuild()


func _on_file_tree_item_collapsed(item):
	FileTree_SaveState()


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
	var _new = G.GRAPH_NewDefault()
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
	return n_window_playtest.visible

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

func _on_menu_edit_id_pressed(id: int):
	var graph: ui_GraphEdit = GRAPH_GetCurrent()
	if not graph:
		return
	match id:
		0: graph.undo_redo.undo()
		1: graph.undo_redo.redo()


func _on_ui_file_tree_tree_exiting():
	pass # Replace with function body.


func _on_dlg_confirm_quit_confirmed():
	get_tree().change_scene_to_file("res://app/scenes/state/STATE_Projects.tscn")


func _on_ui_file_tree_file_double_click(path: String):
	_on_file_tree_file_selected(path)

func _on_btn_open_root_pressed():
	OS.shell_open(G.active_project.GetProjectDir())

func _on_btn_new_res_pressed():
	var _newEnt = res_Entity.new()
	var _savPath=G.PATH_GetRoot()+"/entities/ent.tres"
	print("Saving: "+str(_newEnt)+" to "+_savPath)
	ResourceSaver.save(_newEnt,_savPath)

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
