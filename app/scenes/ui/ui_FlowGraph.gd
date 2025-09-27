extends PanelContainer
class_name ui_GraphEdit

var nodes_selected: Array[ui_GraphNode]

@export var default_graph: res_FlowGraph
var current_graph: res_FlowGraph
@export var node_types: Array[res_FlowNode_type]

@export_category("Links")
@export var N_Graph: GraphEdit
@export var N_ParamEdit: ui_ParamEdit
@export var N_NodeList: ItemList
@export var N_lbl_scriptPath: TextEdit
@export var N_txtedit_NodeId: TextEdit
@export var N_Dlg_csv: FileDialog
@export var N_Spin_KeyOffset: SpinBox
@export var N_popup_Nodelist: PopupMenu

@onready var REF_GraphNode=preload("res://app/scenes/ui/ui_FlowNode.tscn")


signal OnNodeSelected(ui_GraphNode)

func _ready():
	
	if current_graph!=null:
		current_graph = default_graph.duplicate(true)
		GRAPH_Load(current_graph)
	
	N_NodeList.clear()
	for i in node_types:
		N_popup_Nodelist.add_item(i.name)
		N_NodeList.add_item(i.name)

func GRAPH_Refresh():
	var _nam=current_graph.linked_file
	var _valid=current_graph.File_IsValid()
	if _valid:
		name=_nam.get_file().split(".")[0]
	else:
		name="untitled*"
	current_graph.label=name
	# update meta/script import widget
	N_lbl_scriptPath.text=current_graph.linked_script
	N_Spin_KeyOffset.value=current_graph.importkeyoffset
	CONNECTIONS_Fix()

func GRAPH_Load(graph: res_FlowGraph):
	current_graph=graph
	# Remove nodes
	for i in N_Graph.get_children():
		if i is ui_GraphNode:
			i.free()
	
	# Add new nodes - instances
	for i in current_graph.nodes:
		NODE_Add(i)
	
	# Add new nodes -  connections
	for c in current_graph.connections:
		print("-- setup Connection: "+str(c.from_node))
		N_Graph.connect_node(c.from_node,c.from_port,c.to_node,c.to_port)
	
	GRAPH_Refresh()

func NODES_RefreshAll():
	for i in N_Graph.get_children():
		if i.has_method("Refresh"):
			i.Refresh()

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


func NODE_AddFromTemplate(template: res_FlowNode_type,pos: Vector2) -> ui_GraphNode:
	var _newNode: res_FlowNode_Inst=res_FlowNode_Inst.new()
	_newNode.position=pos
	_newNode.template=template
	return NODE_Add(_newNode)

func NODE_Add(node: res_FlowNode_Inst) -> ui_GraphNode:
	if !current_graph.nodes.has(node):
		current_graph.nodes.push_back(node)
	# init label if none
	var new_node=REF_GraphNode.instantiate()
	if node.label.is_empty():
		node.label=str(randi_range(0,9999999))
	N_Graph.add_child(new_node)
	new_node.Setup(node)
	print("Created new node "+str(new_node)+" on graph: "+str(self))
	
	return new_node

func NODE_Remove(node: ui_GraphNode):
	current_graph.nodes.erase(node.node_data)
	node.queue_free()

func CONNECTIONS_Fix():
	current_graph.connections.clear()
	for i in N_Graph.connections:
		current_graph.CONNECTION_AddFromDic(i)

func _on_graph_edit_connection_request(from_node, from_port, to_node, to_port):
	N_Graph.connect_node(from_node,from_port,to_node,to_port)
	CONNECTIONS_Fix()

func _on_graph_edit_disconnection_request(from_node, from_port, to_node, to_port):
	N_Graph.disconnect_node(from_node,from_port,to_node,to_port)
	CONNECTIONS_Fix()

# ==================================================================
# Node Selection
# ==================================================================
func _on_graph_edit_node_selected(node):
	nodes_selected.push_back(node)
	N_txtedit_NodeId.text=node.node_data.label
	N_ParamEdit.OBJECT_Clear()
	var _multi: bool=nodes_selected.size()>1
	N_ParamEdit.OBJECT_MultiMode(_multi)
	if nodes_selected[0] and !_multi:
		N_ParamEdit.OBJECT_Set(nodes_selected[0].node_data,nodes_selected[0].node_data.template)

func _on_graph_edit_node_deselected(node):
	N_txtedit_NodeId.text=""
	if nodes_selected.has(node):
		N_ParamEdit.OBJECT_MultiMode(false)
		nodes_selected.erase(node)
		N_ParamEdit.OBJECT_Clear()

func _on_graph_edit_duplicate_nodes_request():
	var n=[]
	for i in nodes_selected:
		if !i.is_queued_for_deletion():
			var _new =i.node_data.duplicate(true)
			_new.template=i.node_data.template
			var _ui=NODE_Add(_new)
			_ui.position_offset=i.position_offset+Vector2(10,10)
			n.push_back(_ui)
			

func _on_list_nodes_item_activated(index):
	var _temp=node_types[index]
	var _node=res_FlowNode_Inst.new()
	_node.template=_temp
	#get_global_mouse_position()+Vector2(100,100)+(N_Graph.scroll_offset*-1)#+Vector2(100,100)
	
	print("ago: "+str(N_Graph.scroll_offset))
	_node.position=N_Graph.scroll_offset*(1/N_Graph.zoom)+get_local_mouse_position()
	print(str(_node.position))
	
	NODE_Add(_node)

func _on_graph_edit_delete_nodes_request(nodes):
	for i in N_Graph.get_children():
		if nodes.has(i.name):
			NODE_Remove(i)
	for i in nodes_selected:
		if i:
			i.selected=false
		

func _on_btn_close_pressed():
	queue_free()

func _on_btn_update_keys_pressed():
	var _num: int=N_Spin_KeyOffset.value
	for i in current_graph.nodes:
		if i.template.UseLinkKey:
			i.key=current_graph.label+"_"+str(_num)
			_num+=1
	
	for i in N_Graph.get_children():
		if i.has_method("Refresh"):
			i.Refresh()

func _on_btn_script_import_pressed():
	var dat=G_File.CSV_Import(current_graph.linked_script)
	for i in current_graph.nodes:
		if dat.has(i.key):
			i.ImportCSV(dat[i.key])
	NODES_RefreshAll()

func _on_btn_script_set_pressed():
	N_Dlg_csv.root_subfolder=G_Project.PATH_GetRoot()
	N_Dlg_csv.popup()

func _on_file_dialog_file_selected(path):
	current_graph.linked_script=path
	GRAPH_Refresh()

func _on_lbl_script_path_text_changed():
	current_graph.linked_script=N_lbl_scriptPath.text

func _INPUT_Next():
	var t: Array[ui_GraphNode]=NODES_GetSelected()
	print(str(t))
	if t.size()>0:
		var _cur: ui_GraphNode=t[0]
		var _newClass: res_FlowNode_type=_cur.NODE_GetTemplate()
		
		if _newClass.NextNode:
			_newClass=_newClass.NextNode
		if _newClass:
			var _newNode=NODE_AddFromTemplate(_newClass,_cur.position_offset+Vector2(_cur.size.x+50,0))
			N_Graph.connect_node(_cur.name,0,_newNode.name,0)
			NODES_SetAllSelected(false)
			N_Graph.set_selected(_newNode)
		CONNECTIONS_Fix()


func _on_spin_offset_key_value_changed(value):
	var _newV: int=value
	current_graph.importkeyoffset=_newV


func _on_graph_edit_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MASK_RIGHT and event.pressed:
			N_popup_Nodelist.popup()
			N_popup_Nodelist.position=get_global_mouse_position()

func _on_n_popup_node_list_index_pressed(index):
	_on_list_nodes_item_activated(index)


func _on_btn_fix_con_pressed():
	CONNECTIONS_Fix()

func _on_text_edit_node_id_text_changed():
	if NODES_GetSelected()[0]:
		NODES_GetSelected()[0].node_data.label=N_txtedit_NodeId.text
		NODES_GetSelected()[0].name=N_txtedit_NodeId.text
