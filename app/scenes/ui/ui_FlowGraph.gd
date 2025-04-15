extends PanelContainer
class_name ui_GraphEdit

@export var current_graph: res_FlowGraph

@export_category("Links")
@export var N_Graph: GraphEdit
@export var N_ParamEdit: ui_ParamEdit

@onready var REF_GraphNode=preload("res://app/scenes/ui/ui_FlowNode.tscn")

signal OnNodeSelected(ui_GraphNode)

func _ready():
		if current_graph!=null:
			current_graph = current_graph.duplicate(true)
			GRAPH_Load(current_graph)

func GRAPH_Load(graph: res_FlowGraph):
	current_graph=graph
	name=current_graph.label
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


func NODE_Add(node: res_FlowNode_Inst):
	var new_node=REF_GraphNode.instantiate()
	N_Graph.add_child(new_node)
	new_node.Setup(node)
	
	return

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
var nodes_selected: Array[ui_GraphNode]

func _on_graph_edit_node_selected(node):
	nodes_selected.push_back(node)
	N_ParamEdit.OBJECT_Clear()
	var _multi: bool=nodes_selected.size()>1
	N_ParamEdit.OBJECT_MultiMode(_multi)
	if nodes_selected[0] and !_multi:
		N_ParamEdit.OBJECT_Set(nodes_selected[0].node_data,nodes_selected[0].node_data.template)

func _on_graph_edit_node_deselected(node):
	if nodes_selected.has(node):
		N_ParamEdit.OBJECT_MultiMode(false)
		nodes_selected.erase(node)
		N_ParamEdit.OBJECT_Clear()

func _on_graph_edit_duplicate_nodes_request():
	pass
