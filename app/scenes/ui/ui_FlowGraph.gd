extends PanelContainer
class_name ui_GraphEdit

var nodes_selected: Array[ui_GraphNode]
var importkeyoffset=0
var _NodeKeys: PackedStringArray

var undo_redo := UndoRedo.new()
var _undo_snapshots: Dictionary  # node_label -> {params, direction, position}
var _popup_graph_pos: Vector2    # graph-space position recorded when right-click popup opens

var node_group_icons=[
	"",
	"res://app/assets/2D/icons/t_ico_PlusGreen.png",
]

var file_path=""
#savable data for the currently loaded graph
var DATA={
	id=0,
	label="",
	linked_script="",
	connections=[],
	nodes=[],
}

@export_category("Links")
@export var N_Graph: GraphEdit
@export var N_ParamEdit: ui_ParamEdit
@export var N_NodeList: ItemList
@export var N_lbl_scriptPath: TextEdit
@export var N_txtedit_NodeDir: TextEdit
@export var N_Dlg_csv: FileDialog
@export var N_Spin_KeyOffset: SpinBox
@export var N_popup_Nodelist: PopupMenu
@export var N_screenplay: ui_Screenplay
@export var n_flow_template: OptionButton
@export var col_creating_screen: ColorRect
@export var N_txtedit_GraphDesc: TextEdit
@export var N_txtedit_NodeFilter: TextEdit

@export var parm_BindList: Array[ui_pEdit]

@onready var REF_GraphNode=preload("res://app/scenes/ui/ui_FlowNode.tscn")

signal OnNodeSelected(ui_GraphNode)
signal OnGraphEvent(ui_GraphEdit, StringName, Dictionary)

func _ready():
	N_txtedit_NodeDir.text=""
	GRAPH_Load(G.GRAPH_NewDefault())
	N_screenplay.graph=self
	
	for i in parm_BindList:
		i.OnParamEdit.connect(PARAM_OnEdit)
	
	n_flow_template.add_item("")
	for i in G.FlowTemplate_GetKeys():
		n_flow_template.add_item(i)
	
	NodeList_Rebuild()


func _unhandled_key_input(event: InputEvent):
	if not (event is InputEventKey):
		return
	if not (event.pressed and not event.echo):
		return
	if event.ctrl_pressed and event.keycode == KEY_Z and not event.shift_pressed:
		undo_redo.undo()
		get_viewport().set_input_as_handled()
	elif event.ctrl_pressed and (event.keycode == KEY_Y or (event.keycode == KEY_Z and event.shift_pressed)):
		undo_redo.redo()
		get_viewport().set_input_as_handled()


func NodeList_Rebuild():
	# add selectable nodes
	N_NodeList.clear()
	_NodeKeys=G.NODES_GetKeysAlphabetical()
	
	var template_list=G.FlowTemplate_GetKeys()
	var _tmp=DATA.get('template',"")
	if template_list.has(_tmp):
		var temp_data=G.FlowTemplate_GetData(_tmp)
		var node_list=temp_data.get('nodes').to_array()
		_NodeKeys=node_list
	
	for i in _NodeKeys:
		if G.D_nodes.has(i):
			var dat=G.D_nodes[i].get("name","*no name")
			var _nodeMeta=G.D_node_meta.get(i,{})
			var _m_group=_nodeMeta.get('group',0)
			var texture: Texture2D=null
			if node_group_icons.size()>_m_group and node_group_icons[_m_group]!="":
				texture=load(node_group_icons[_m_group])
			N_popup_Nodelist.add_item(dat)
			var ind=N_NodeList.add_item(dat,texture)
	


func SAVE(path: String):
	file_path=path
	var dat=GRAPH_GetDic()
	Z_File.SaveStringAsFile(path,Z_Parse.to_JSON(dat),true,true)
	G_Log.Notification("File Saved: "+str(path),Color.GREEN)
	GRAPH_Refresh()

func DATA_to_CSV() -> String:
	var nodes:=NODES_GetSortedOrder()
	var output_array:=[]
	
	var output="key,speaker,line,direction,\n"
	for i in nodes:
		
		var node_dat=i.DATA_to_CSV()
		if node_dat is Dictionary:
			output_array.push_back(node_dat)
			
	return Z_Parse.to_CSV(output_array)


func GRAPH_GetDic():
	var out: Dictionary=DATA
	out['connections']=N_Graph.connections
	out['nodes']=[]
	for i in NODES_GetAll():
		out['nodes'].push_back(i.DATA)
	return DATA

func GRAPH_Refresh():
	var _nam=file_path
	#var _valid=file_path.is_valid_filename()
	if file_path!="":
		name=_nam.get_file().split(".")[0]
	else:
		name="untitled*"
	
	# update meta/script import widget
	N_lbl_scriptPath.text=DATA.get('linked_script',"")
	#N_Spin_KeyOffset.value=current_graph.importkeyoffset
	CONNECTIONS_Fix()
	
	# Load description
	N_txtedit_GraphDesc.text=DATA.get("description","")

func GRAPH_Load(graph: Dictionary):
	if N_txtedit_NodeFilter:
		N_txtedit_NodeFilter.text = ""
	undo_redo.clear_history()
	_undo_snapshots.clear()
	DATA=graph
	
	## CORRECT OLD NODE DATA
	var _tmeta=DATA.get('meta',{})
	if _tmeta is Dictionary:
		for i in DATA.get('meta',{}):
			DATA[i]=DATA.get('meta')[i]
	DATA.erase('meta')
	
	# ===== CLEAR GRAPH ====
	
	# Remove nodes
	for i in N_Graph.get_children():
		if i is ui_GraphNode:
			i.free()
	
	# ===== CREATE GRAPH ====
	
	# LOAD nodes
	for i in DATA.get("nodes",[]):
		NODE_Add(i)
	
	# LOAD - connections
	for i in N_Graph.connections:
		N_Graph.disconnect_node(i.from_node,i.from_port,i.to_node,i.to_port)
	for c in DATA.get("connections",[]):
		print("-- setup Connection: "+str(c.from_node))
		N_Graph.connect_node(c.from_node,c.from_port,c.to_node,c.to_port)
	
	GRAPH_Refresh()

func NODES_GetAll() -> Array[ui_GraphNode]:
	var out: Array[ui_GraphNode]
	for i in N_Graph.get_children():
		if i is ui_GraphNode:
			out.push_back(i)
	return out

func NODES_RefreshAll():
	for i in N_Graph.get_children():
		if i.has_method("Refresh"):
			i.Refresh()

func NODES_GetSortedOrder() -> Array[ui_GraphNode]:
	var sort_values: Dictionary[ui_GraphNode,int]
	
	var nodes_to_check:Array[ui_GraphNode]=[]
	var start_node: ui_GraphNode=NODE_GetByType('node_Start')
	
	var InterateNodeCheck = func(start: ui_GraphNode):
		var _start_val=sort_values.get(start,0)
		
		#remvoe checked node from list of TO check
		if nodes_to_check.has(start):
			nodes_to_check.erase(start)
		
		#iterate over connected output nodes
		var output_nodes:Array[ui_GraphNode]=NODES_GetConnected_Output(start)
		for i in output_nodes:
			#if node has not already been givien a sort number
			if !sort_values.has(i):
				var loc_index:int=output_nodes.find(i)
				var new_index=_start_val+(loc_index*1000)+1
				#asign node with sort number
				sort_values[i]=new_index
				nodes_to_check.push_back(i)
	
	# add sort numbers to all nodes starting from START
	if start_node:
		nodes_to_check.push_back(start_node)
		sort_values[start_node]=0
		
		while !nodes_to_check.is_empty():
			for i in nodes_to_check:
				InterateNodeCheck.call(i)
	
	# finally, sort into array based on sort number
	# Get the keys as an array
	var sorted_keys: Array[ui_GraphNode] = sort_values.keys()

	# Sort by the dictionary values (ascending order)
	sorted_keys.sort_custom(func(a, b): return sort_values[a] < sort_values[b])
	
	return sorted_keys
	

func NODES_GetConnected_Output(start: ui_GraphNode) -> Array[ui_GraphNode]:
	var out:Array[ui_GraphNode]=[]
	
	var con_list:Array[Dictionary]=N_Graph.get_connection_list_from_node(start.name)
	
	for i in con_list:
		if i['from_node']==start.name:
			var _path: StringName=i['to_node']
			var _child=G_Node.Child_GetByName(N_Graph,_path)
			out.push_back(_child)

	return out



func NODES_GetSelected() -> Array[ui_GraphNode]:
	var out:Array[ui_GraphNode]=[]
	for i in nodes_selected:
		if i and !i.is_queued_for_deletion() and i is ui_GraphNode:
			out.push_back(i)
	return out

func NODES_SetAllSelected(selected: bool):
	nodes_selected=[]
	for i in get_children():
		if i and !i.is_queued_for_deletion() and i is ui_GraphNode:
			
			if selected:
				nodes_selected.push_back(i)


func NODE_AddFromTemplate(template: String,pos: Vector2) -> ui_GraphNode:
	var _newNode={
		_template=template,
		position={x=0,y=0},
		params={},
	}
	_newNode.position.x=pos.x
	_newNode.position.y=pos.y
	
	return NODE_Add(_newNode)

func NODE_Add(node: Dictionary) -> ui_GraphNode:
	#add node to table if not already in
	if !DATA["nodes"].has(node):
		DATA["nodes"].push_back(node)
	
	var new_node: ui_GraphNode=REF_GraphNode.instantiate()
	
	# init label if none
	new_node.OnNodeEvent.connect(_on_ui_flow_node_on_node_event)
	N_Graph.add_child(new_node)
	new_node.Setup(node)
	print("Created new node "+str(new_node)+" on graph: "+str(self))
	
	return new_node

func NODE_Remove(node: ui_GraphNode):
	node.queue_free()

func NODE_GetByType(type: String) -> ui_GraphNode:
	var node_list=NODES_GetAll()
	for n in node_list:
		if n.node_type==type:
			return n
	return null

func NODE_GetByParam(param: String, value) -> ui_GraphNode:
	for n in NODES_GetAll():
		if n.DATA.get(param)==value:
			return n
	return null

func NODE_RefreshCurrent():
	var n: Array[ui_GraphNode]=NODES_GetSelected()
	if n.size()>0 and n[0]:
		n[0].Refresh_Description()

func CONNECTIONS_Fix():
	pass
	#current_graph.connections.clear()
	#for i in N_Graph.connections:
	#	current_graph.CONNECTION_AddFromDic(i)

func PARAM_OnEdit(param: String, value):
	NODE_RefreshCurrent()

func _on_graph_edit_connection_request(from_node, from_port, to_node, to_port):
	_ur_connection_add(from_node, from_port, to_node, to_port)
	undo_redo.create_action("Connect Nodes")
	undo_redo.add_do_method(_ur_connection_add.bind(from_node, from_port, to_node, to_port))
	undo_redo.add_undo_method(_ur_connection_remove.bind(from_node, from_port, to_node, to_port))
	undo_redo.commit_action(false)

func _on_graph_edit_disconnection_request(from_node, from_port, to_node, to_port):
	_ur_connection_remove(from_node, from_port, to_node, to_port)
	undo_redo.create_action("Disconnect Nodes")
	undo_redo.add_do_method(_ur_connection_remove.bind(from_node, from_port, to_node, to_port))
	undo_redo.add_undo_method(_ur_connection_add.bind(from_node, from_port, to_node, to_port))
	undo_redo.commit_action(false)

# ==================================================================
# Node Selection
# ==================================================================
func _on_graph_edit_node_selected(node):
	nodes_selected.push_back(node)
	N_ParamEdit.OBJECT_Clear()
	N_txtedit_NodeDir.text=node.DATA.get('direction',"")

	var _multi: bool=nodes_selected.size()>1
	N_ParamEdit.OBJECT_MultiMode(_multi)

	if nodes_selected[0] and !_multi:
		var n=nodes_selected[0]
		N_ParamEdit.OBJECT_Set(n.DATA,n.TypeData)
		for i in parm_BindList:
			i.Setup(n.DATA)

	_undo_snapshots[str(node.name)] = {
		params = node.DATA.get('params', {}).duplicate(true),
		direction = node.DATA.get('direction', ''),
		position = node.position_offset
	}


func _on_graph_edit_node_deselected(node):
	N_txtedit_NodeDir.text=""
	if nodes_selected.has(node):
		N_ParamEdit.OBJECT_MultiMode(false)
		nodes_selected.erase(node)
		N_ParamEdit.OBJECT_Clear()
		for i in parm_BindList:
			i.OBJECT={}
			i.Value_CLEAR()

	var label := str(node.name)
	var snap = _undo_snapshots.get(label)
	if snap and !node.is_queued_for_deletion():
		var cur_params = node.DATA.get('params', {})
		var cur_dir = node.DATA.get('direction', '')
		var cur_pos = node.position_offset
		var params_changed = snap.params != cur_params
		var dir_changed = snap.direction != cur_dir
		var pos_changed = snap.position.distance_to(cur_pos) > 0.5
		if params_changed or dir_changed or pos_changed:
			undo_redo.create_action("Edit Node")
			if params_changed:
				undo_redo.add_do_method(_ur_params_set.bind(label, cur_params.duplicate(true)))
				undo_redo.add_undo_method(_ur_params_set.bind(label, snap.params))
			if dir_changed:
				undo_redo.add_do_method(_ur_direction_set.bind(label, cur_dir))
				undo_redo.add_undo_method(_ur_direction_set.bind(label, snap.direction))
			if pos_changed:
				undo_redo.add_do_method(_ur_position_set.bind(label, cur_pos))
				undo_redo.add_undo_method(_ur_position_set.bind(label, snap.position))
			undo_redo.commit_action(false)
	_undo_snapshots.erase(label)

func _on_graph_edit_duplicate_nodes_request():
	undo_redo.create_action("Duplicate Nodes")
	for i in nodes_selected:
		if !i.is_queued_for_deletion():
			var _new = i.DATA.duplicate(true)
			_new['label'] = str(randi_range(0, 9999999))
			_new['position'] = {x = i.position_offset.x + 30, y = i.position_offset.y + 30}
			var dup_label: String = _new['label']
			undo_redo.add_do_method(_ur_node_add.bind(_new))
			undo_redo.add_undo_method(_ur_node_remove.bind(dup_label))
	undo_redo.commit_action()
			

func _on_list_nodes_item_activated(index):
	# Side-panel double-click: spawn at the visible centre of the graph
	var vis_center: Vector2 = N_Graph.scroll_offset + N_Graph.size * 0.5 / N_Graph.zoom
	_spawn_node_at(_NodeKeys[index], vis_center)

func _spawn_node_at(node_type: String, graph_pos: Vector2):
	var _node = G.NODE_Generate(node_type)
	_node['position'] = {x = graph_pos.x, y = graph_pos.y}
	if _node.get('label', '') == '':
		_node['label'] = str(randi_range(0, 9999999))
	var label: String = _node['label']
	_ur_node_add(_node)
	undo_redo.create_action("Add Node")
	undo_redo.add_do_method(_ur_node_add.bind(_node))
	undo_redo.add_undo_method(_ur_node_remove.bind(label))
	undo_redo.commit_action(false)

func _on_graph_edit_delete_nodes_request(nodes):
	var all_data: Array = []
	var all_labels: Array = []
	var all_connections: Array = []
	var seen_con_keys: Dictionary = {}
	for n in N_Graph.get_children():
		if nodes.has(n.name) and n is ui_GraphNode:
			all_data.append(n.DATA.duplicate(true))
			all_labels.append(str(n.name))
			for c in N_Graph.connections:
				if c.from_node == n.name or c.to_node == n.name:
					var key := "%s:%d:%s:%d" % [c.from_node, c.from_port, c.to_node, c.to_port]
					if !seen_con_keys.has(key):
						seen_con_keys[key] = true
						all_connections.append({from_node=c.from_node, from_port=c.from_port,
							to_node=c.to_node, to_port=c.to_port})
	undo_redo.create_action("Delete Nodes")
	for label in all_labels:
		undo_redo.add_do_method(_ur_node_remove.bind(label))
	undo_redo.add_undo_method(_ur_nodes_restore.bind(all_data, all_connections))
	undo_redo.commit_action()
	for i in nodes_selected:
		if i:
			i.selected = false
		

func _on_btn_close_pressed():
	queue_free()

func _on_btn_update_keys_pressed():
	var _num: int=N_Spin_KeyOffset.value
	for i in NODES_GetAll():
		if i.TypeData.get("UseLinkKey",false):
			i.DATA['key']=name+"_"+str(_num)
			_num+=1
			i.Refresh()


func _on_btn_script_import_pressed():
	var _script_path=SCRIPT_GetPath()
	var _scriptOvr=DATA.get("linked_script")
	if _scriptOvr!="":
		_script_path=_scriptOvr
	var _csv=G_File.CSV_Import(_script_path)
	
	#write csv values to individual flow nodes
	for i in NODES_GetAll():
		if _csv.has(i.DATA.get('key','')):
			i.ImportCSV(_csv[i.DATA.key])
	
	_on_btn_d_irection_import_pressed()

func SCRIPT_GetPath() -> String:
	return G.active_project.DATA.get('linked_script',"")

func _on_btn_d_irection_import_pressed():

	var line_dir_map: Dictionary=Z_Parse.from_JSON(Z_File.LoadFileAsString(G.PATH_GetRoot()+"/_dump/DirectionDump.json"))
	
	for i in NODES_GetAll():
		if i:
			i.DATA['direction']=line_dir_map.get(i.DATA.get('key',""),"")
	
	NODES_RefreshAll()

func _on_btn_script_set_pressed():
	N_Dlg_csv.root_subfolder=G.PATH_GetRoot()
	N_Dlg_csv.popup()

func _on_file_dialog_file_selected(path):
	file_path=path
	GRAPH_Refresh()

func _on_lbl_script_path_text_changed():
	DATA['linked_script']=N_lbl_scriptPath.text

func _INPUT_Next():
	var t: Array[ui_GraphNode] = NODES_GetSelected()
	if t.size() == 0:
		return
	var _cur: ui_GraphNode = t[0]
	var _newClass = _cur.node_type
	if _cur.TypeData.get('quick_next'):
		_newClass = _cur.TypeData['quick_next']
	if !_newClass:
		return
	var pos = _cur.position_offset + Vector2(_cur.size.x + 50, 0)
	var node_data = G.NODE_Generate(_newClass)
	node_data['position'] = {x = pos.x, y = pos.y}
	node_data['label'] = str(randi_range(0, 9999999))
	var new_label: String = node_data['label']
	var from_label: String = str(_cur.name)
	undo_redo.create_action("Add Next Node")
	undo_redo.add_do_method(_ur_node_add.bind(node_data))
	undo_redo.add_do_method(_ur_connection_add.bind(from_label, 0, new_label, 0))
	undo_redo.add_undo_method(_ur_connection_remove.bind(from_label, 0, new_label, 0))
	undo_redo.add_undo_method(_ur_node_remove.bind(new_label))
	undo_redo.commit_action()
	NODES_SetAllSelected(false)
	var new_node = NODE_GetByParam('label', new_label)
	if new_node:
		N_Graph.set_selected(new_node)

func _on_spin_offset_key_value_changed(value):
	var _newV: int=value
	importkeyoffset=_newV

func _on_graph_edit_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_popup_graph_pos = (N_Graph.get_local_mouse_position() + N_Graph.scroll_offset) / N_Graph.zoom
			N_popup_Nodelist.popup()
			N_popup_Nodelist.position = get_global_mouse_position()

func _on_n_popup_node_list_index_pressed(index):
	_spawn_node_at(_NodeKeys[index], _popup_graph_pos)

func _on_btn_fix_con_pressed():
	CONNECTIONS_Fix()


func _on_i_select_all_next_input_begin():
	var t: Array[ui_GraphNode]=NODES_GetSelected()
	var _newSel: Array[String]
	if t.size()>0 and t[0]:
		#print(str(current_graph.connections))
		for i in DATA.connections:
			print(i.from_node + " " + t[0].name)
			if(i.from_node==t[0].name):
				_newSel.push_back(i.to_node)

	for i in _newSel:
		for n in N_Graph.get_children():
			if n.name==i:
				n.selected=true

func _on_btn_del_empty_pressed():
	for i in NODES_GetAll():
		var _p=i.DATA.params
		if i.TypeData.get("EmptyDelete",false):
			if _p.get("line","")=="":
				NODE_Remove(i)


func _on_params_on_param_edit(param, value):
	NODE_RefreshCurrent()




func _on_btn_play_sound_pressed():
	var n: Array[ui_GraphNode]=NODES_GetSelected()
	if n.size()>0:
		n[0].SOUND_Play()

func _on_btn_regen_nodes_pressed():
	for i in NODES_GetAll():
		i.LABEL_Regen(true)

func _on_ui_flow_node_on_node_event(event):
	if event=='LabelRefresh':
		pass

func _on_btn_set_import_clean_pressed():
	_on_btn_update_keys_pressed()
	_on_btn_script_import_pressed()
	_on_btn_del_empty_pressed()


func _on_txt_edit_dir_text_changed():
	var no: Array[ui_GraphNode] =NODES_GetSelected()
	if no.size()>0:
		var n: ui_GraphNode=no[0]
		if n:
			n.DATA['direction']=N_txtedit_NodeDir.text
			n.Refresh_Description()


func _on_tab_container_tab_changed(tab):
	if tab==1:
		N_screenplay.REBUILD()


func _on_btn_debug_pressed():
	print(NODES_GetSortedOrder())


func _on_n_flow_template_item_selected(index):
	DATA['template']=n_flow_template.get_item_text(index)
	NodeList_Rebuild()


func _on_btn_playtest_pressed():
	OnGraphEvent.emit(self,'playtest',{})

func _on_btn_export_pressed():
	col_creating_screen.visible=true
	await get_tree().create_timer(0.2).timeout
	var project_dir: String = ProjectSettings.globalize_path("res://").replace("/", "\\")
	
	#SETUP - temp JSON
	var _j: Dictionary=G.active_project.SCREENPLAY_GetPdfConfig()
	
	#SETUP - temp CSV
	var _csvSting:=DATA_to_CSV()
	
	var output_name=file_path.get_file().get_basename()+".pdf"
	var output_path=G.active_project.GetProjectDir()+"/Export/"+output_name
	var output_desc=DATA.get('description',"")
	var converter := CsvScriptToPdf.new()
	#file_path.get_file()
	var result=converter.CsvScriptToPDF(file_path.get_file().get_basename(),output_desc,_csvSting,_j,output_path)
		
	if result == OK:
		print("✓ PDF created successfully!")
		G_Log.Notification("Screenplay exported to: "+output_path,Color.AQUA)
	else:
		G_Log.Notification("✗ Failed to create PDF, error code: "+str(result),Color.RED)
		print("PDF export error: ", result)
		printerr(result)
	col_creating_screen.visible=false


func _on_btn_export_csv_pressed():
	var output_name=DATA.get('label',"output")+".csv"
	var output_path=G.active_project.GetProjectDir()+"/Export/"+output_name
	var result=Z_File.SaveStringAsFile(output_path,DATA_to_CSV(),true,true)
	
	if result == OK:
		print("✓ PDF created successfully!")
		G_Log.Notification("Screenplay exported to: "+output_path,Color.AQUA)
	else:
		G_Log.Notification("✗ Failed to create PDF, error code: "+str(result),Color.RED)
		print("PDF failed: "+output_path)
		printerr(result)


func _on_text_edit_graph_desc_text_changed():
	DATA.description=N_txtedit_GraphDesc.text


func _on_node_filter_text_changed():
	NODES_FilterByValue(N_txtedit_NodeFilter.text)

func NODES_FilterByValue(text: String):
	for node in NODES_GetAll():
		if text.is_empty():
			node.modulate = Color.WHITE
		else:
			var params: Dictionary = node.DATA.get('params', {})
			var matched := false
			for key in params:
				if str(params[key]).contains(text):
					matched = true
					break
			node.modulate = Color.WHITE if matched else Color(1.0, 1.0, 1.0, 0.1)


# ==============================================================
# UNDO / REDO  — internal execution primitives
# ==============================================================

func _ur_node_add(data: Dictionary):
	if !DATA["nodes"].has(data):
		DATA["nodes"].push_back(data)
	var new_node: ui_GraphNode = REF_GraphNode.instantiate()
	new_node.OnNodeEvent.connect(_on_ui_flow_node_on_node_event)
	N_Graph.add_child(new_node)
	new_node.Setup(data)

func _ur_node_remove(label: String):
	for n in NODES_GetAll():
		if n.DATA.get('label') == label:
			var idx = DATA["nodes"].find(n.DATA)
			if idx >= 0:
				DATA["nodes"].remove_at(idx)
			n.queue_free()
			break
	var to_remove: Array = []
	for c in N_Graph.connections:
		if c.from_node == label or c.to_node == label:
			to_remove.append(c)
	for c in to_remove:
		N_Graph.disconnect_node(c.from_node, c.from_port, c.to_node, c.to_port)

func _ur_nodes_restore(nodes_data: Array, connections: Array):
	for data in nodes_data:
		_ur_node_add(data)
	for c in connections:
		N_Graph.connect_node(c.from_node, c.from_port, c.to_node, c.to_port)

func _ur_connection_add(from_node: String, from_port: int, to_node: String, to_port: int):
	N_Graph.connect_node(from_node, from_port, to_node, to_port)

func _ur_connection_remove(from_node: String, from_port: int, to_node: String, to_port: int):
	N_Graph.disconnect_node(from_node, from_port, to_node, to_port)

func _ur_params_set(label: String, params: Dictionary):
	var n = NODE_GetByParam('label', label)
	if n:
		n.DATA['params'] = params
		n.Refresh_Description()
		if nodes_selected.has(n):
			N_ParamEdit.OBJECT_Set(n.DATA, n.TypeData)

func _ur_direction_set(label: String, text: String):
	var n = NODE_GetByParam('label', label)
	if n:
		n.DATA['direction'] = text
		n.Refresh_Description()
		if nodes_selected.has(n):
			N_txtedit_NodeDir.text = text

func _ur_position_set(label: String, pos: Vector2):
	var n = NODE_GetByParam('label', label)
	if n:
		n.position_offset = pos
