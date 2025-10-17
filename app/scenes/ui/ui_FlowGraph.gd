extends PanelContainer
class_name ui_GraphEdit

var nodes_selected: Array[ui_GraphNode]
var importkeyoffset=0

var node_group_icons=[
	"res://app/assets/2D/icons/Icon_File_T.PNG",
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
@export var N_txtedit_NodeId: TextEdit
@export var N_Dlg_csv: FileDialog
@export var N_Spin_KeyOffset: SpinBox
@export var N_popup_Nodelist: PopupMenu

@onready var REF_GraphNode=preload("res://app/scenes/ui/ui_FlowNode.tscn")

signal OnNodeSelected(ui_GraphNode)

func _ready():
	pass
	GRAPH_Load(G_Lua.GRAPH_NewDefault())
	
	# add selectable nodes
	N_NodeList.clear()
	for i in G_Lua.D_nodes:
		var dat=G_Lua.D_nodes[i].get("name","*no name")
		var _nodeMeta=G_Lua.D_node_meta.get(i,{})
		var _m_group=_nodeMeta.get('group')
		var texture: Texture2D=null
		if node_group_icons.size()>_m_group:
			texture=load(node_group_icons[_m_group])
		N_popup_Nodelist.add_item(dat)
		var ind=N_NodeList.add_item(dat,texture)

func SAVE(path: String):
	file_path=path
	var dat=GRAPH_GetDic()
	G_File.SAVE_Json(dat,path)
	G_Log.Notification("File Saved: "+str(path),Color.GREEN)
	GRAPH_Refresh()

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

func GRAPH_Load(graph: Dictionary):
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
	
	var new_node=REF_GraphNode.instantiate()
	
	# init label if none
	if !node.has('label') or node.get('label')=="":
		node['label']=str(randi_range(0,9999999))
	N_Graph.add_child(new_node)
	new_node.Setup(node)
	print("Created new node "+str(new_node)+" on graph: "+str(self))
	
	return new_node

func NODE_Remove(node: ui_GraphNode):
	node.queue_free()

func CONNECTIONS_Fix():
	pass
	#current_graph.connections.clear()
	#for i in N_Graph.connections:
	#	current_graph.CONNECTION_AddFromDic(i)

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
	N_txtedit_NodeId.text=DATA.label
	N_ParamEdit.OBJECT_Clear()
	var _multi: bool=nodes_selected.size()>1
	N_ParamEdit.OBJECT_MultiMode(_multi)
	if nodes_selected[0] and !_multi:
		var n=nodes_selected[0]
		N_ParamEdit.OBJECT_Set(n.DATA,n.TypeData)

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
			var _new =i.DATA.duplicate(true)
			var _ui=NODE_Add(_new)
			_ui.position_offset=i.position_offset+Vector2(10,10)
			n.push_back(_ui)
			

func _on_list_nodes_item_activated(index):
	var _nodeType=G_Lua.D_nodes.keys()[index]
	var _node=G_Lua.NODE_Generate(_nodeType)
	
	_node.position=N_Graph.scroll_offset*(1/N_Graph.zoom)+get_local_mouse_position()
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
	for i in NODES_GetAll():
		if i.TypeData.get("UseLinkKey",false):
			i.DATA['key']=name+"_"+str(_num)
			_num+=1
			i.Refresh()

func _on_btn_script_import_pressed():
	var dat=G_File.CSV_Import(DATA.get("linked_script"))
	for i in NODES_GetAll():
		if dat.has(i.key):
			i.ImportCSV(dat[i.key])
	NODES_RefreshAll()

func _on_btn_script_set_pressed():
	N_Dlg_csv.root_subfolder=G_Project.PATH_GetRoot()
	N_Dlg_csv.popup()

func _on_file_dialog_file_selected(path):
	file_path=path
	GRAPH_Refresh()

func _on_lbl_script_path_text_changed():
	DATA['linked_script']=N_lbl_scriptPath.text

func _INPUT_Next():
	var t: Array[ui_GraphNode]=NODES_GetSelected()
	print(str(t))
	if t.size()>0:
		var _cur: ui_GraphNode=t[0]
		var _newClass=_cur.node_type
		
		if _cur.TypeData['quick_next']:
			_newClass=_cur.TypeData['quick_next']
		if _newClass:
			var _newNode=NODE_AddFromTemplate(_newClass,_cur.position_offset+Vector2(_cur.size.x+50,0))
			N_Graph.connect_node(_cur.name,0,_newNode.name,0)
			NODES_SetAllSelected(false)
			N_Graph.set_selected(_newNode)
		CONNECTIONS_Fix()

func _on_spin_offset_key_value_changed(value):
	var _newV: int=value
	importkeyoffset=_newV

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


func _on_i_select_all_next_input_begin():
	var t: Array[ui_GraphNode]=NODES_GetSelected()
	var _newSel: Array[String]
	if t[0]:
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
	print('argo')
	var n: Array[ui_GraphNode]=NODES_GetSelected()
	if n[0]:
		n[0].Refresh_Description()
