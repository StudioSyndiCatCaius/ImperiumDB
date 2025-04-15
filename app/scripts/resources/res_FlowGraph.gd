extends res__ImpAsset
class_name res_FlowGraph

@export var nodes: Array[res_FlowNode_Inst]
@export var connections: Array[res_FlowConnection]

func META_Save(dic: Dictionary):
	# SAVE connections
	var _con=[]
	for i in connections:
		_con.push_back({
			from_node=i.from_node,
			from_port=i.from_port,
			to_node=i.to_node,
			to_port=i.to_port,
		})
	dic["connections"]=_con
	
	# SAVE nodes
	var _nod=[]
	for i in nodes:
		_nod.push_back(i.JSON_Get())
	dic["nodes"]=_nod

func META_Load(dic: Dictionary):
	print("--------- LOADING META: "+str(dic))
	# LOAD connections
	connections.clear()
	for i in dic.get("connections",[]):
		CONNECTION_AddFromDic(i)
		
	# LOAD nodes
	nodes.clear()
	var _nodesIn: Array =dic.get("nodes",[])
	for n in _nodesIn:
		var new_node=res_FlowNode_Inst.new()
		new_node.JSON_Set(n)
		nodes.push_back(new_node)

func CONNECTION_AddFromDic(dic: Dictionary):
	CONNECTION_Add(
		dic.get("from_node",""),
		dic.get("from_port",0),
		dic.get("to_node",""),
		dic.get("to_port",0),
	)

func CONNECTION_Add(from_node: String, from_port: int,to_node: String, to_port: int):
	var new_con=res_FlowConnection.new()
	new_con.from_node=from_node
	new_con.to_node=to_node
	new_con.from_port=from_port
	new_con.to_port=to_port
	connections.push_back(new_con)
