extends Node


var l: LuaState

var D_templates={}
var D_nodes={}
var D_node_meta={}

var NODE_Default={
	id=0,
	label="untitled*",
	linked_script="",
	connections=[
			{
				from_node="100",
				from_port=0,
				to_node="200",
				to_port=0,
			},
			{
				from_node="200",
				from_port=0,
				to_node="300",
				to_port=0,
			},
	],
	nodes=[
		{
			_template="node_Start",
			label="100",
			position={x=0,y=0},
			params={}
		},
		{
			_template="node_DialogueLine",
			label="200",
			position={x=300,y=0},
			params={}
		},
		{
			_template="node_End",
			label="300",
			position={x=600,y=0},
			params={}
		},
	]
}

func DATABASE_Get()-> Dictionary:
	return G_Lua.l.globals.to_dictionary()['_D'].to_dictionary()

func SET(key,value):
	l.globals.set(key,value)

func CONV(input):
	var out={}
	if input is Dictionary:
		out=input
	elif input is LuaTable:
		out=input.to_dictionary()
	else:
		return input
	
	for i in out:
		out[i]=CONV(out[i])
	
	return out


func _ready():
	l=LuaState.new()
	l.open_libraries()
	
	l.do_string("""
		ImpDB_Nodes={}
		ImpDB_Templates={}
		_D={
			garba={},
		}
	""")
	
	print("================================================")
	NODES_LoadAllInPath("res://lua/nodes/")
	print("--------------")
	print(str(D_nodes))
	print("================================================")

# ====================================================================
# TEMPLATES
# ====================================================================

func TEMPLATES_ReloadAll():
	D_templates={}
	TEMPLATES_LoadAllInPath(G_Project.active_project.GetProjectDir()+"/FlowTemplates/")

func TEMPLATES_LoadAllInPath(path: String):
	for i in G_File.LIST_AllInDir(path):
		var _new=l.do_file(i)
	
	D_templates=l.globals.ImpDB_Templates.to_dictionary()

# ====================================================================
# Nodes
# ====================================================================

func NODES_RegenLuaTable():
	var dic=l.globals.to_dictionary()
	var dic2=dic.ImpDB_Nodes.to_dictionary()
	D_nodes=dic2

func NODES_LoadAllInPath(path: String,group:int=0):
	var _p=G_File.PathCorrect(path)
	for i in G_File.LIST_AllInDir(_p,true):
		if i.get_extension()=="lua":
			var _key=i.get_file().get_basename()
			var _val=l.do_file(i)
			print('did file restult: '+str(i))
			
	NODES_RegenLuaTable()

func NODES_GetKeysAlphabetical() -> Array:
	var _out=D_nodes.keys()
	_out.sort()
	return _out

func NODES_ReloadInternal():
	D_nodes={}
	NODES_LoadAllInPath("res://lua/nodes/")

func NODES_ReloadAll():
	NODES_ReloadInternal()
	for i in G_Project.GetCONFIG().get("external_node_paths",[]):
		NODES_LoadAllInPath(i,1)

func NODE_Generate(type: String) -> Dictionary:
	var _dat=D_nodes[type]
	var _newNode={
		position={x=0,y=0},
		id=0,
		label="",
		params={}
	}
	
	_newNode["_template"]=type
	var plist=_dat.get("params",{})
	for i in plist:
		_newNode["params"][i]=plist.get("default",'')
		
	return _newNode

func GRAPH_NewDefault() -> Dictionary:
	return NODE_Default.duplicate(true)
