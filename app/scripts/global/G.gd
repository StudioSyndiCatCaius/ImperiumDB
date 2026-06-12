extends Node

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

var project_template={
	"flow/test.ImpFlow"="",
	"lua/autorun/data.lua"="
	_D={
		characters={
			Imp={name='Mr Imp'}
		},
		items={},
	}
	",
	"image/logo.png"=preload("res://icon.png"),
}


var b_FirstOpen=false

var list_projects: Array[res_project]
var active_project: res_project
var DATA_global={
	projects=[]
}

var path_SaveProj="user://projects.json"

var users=[]

func _ready():
	
	Z.L.do_string("ImpDB_Nodes={}")
	await get_tree().create_timer(0.1)
	DATA_global=G_File.LOAD_Json(path_SaveProj,DATA_global)
	for _path in DATA_global.get("projects",[]):
		PROJECT_Load(_path)
	if active_project==null and list_projects.size()>0:
		active_project=list_projects[0]

func _exit_tree():
	G_File.SAVE_Json(DATA_global,path_SaveProj)
	if active_project!=null:
		active_project.SAVE()

func GetCONFIG() -> Dictionary:
	return active_project.DATA

func PATH_GetRoot() -> String:
	var str=""
	if active_project:
		str=active_project.path.get_base_dir()
	return str

# ====================================================================
# PROJECT
# ====================================================================


func PROJECT_Register(path: String):
	if !DATA_global.has('projects'):
		DATA_global['projects']=[]
	
	var _a: Array=DATA_global['projects']
	if _a.has(path):
		DATA_global['projects'].erase(path)
	DATA_global['projects'].push_back(path)

func PROJECT_GetFromPath(path: String):
	for i in list_projects:
		if i.path==path:
			return i
	return null

func PROJECT_Load(path: String) -> res_project:
	print("Loading Project: "+path)
	if !FileAccess.file_exists(path):
		return null
	if !DATA_global['projects'].has(path):
		print("  -- path not in project list. Adding now.")
		PROJECT_Register(path)
	
	#create new project
	var new_proj =res_project.new()
	print("  new project object created as: "+str(new_proj))
	
	new_proj.path=path
	new_proj.LOAD_fromPath(path)
	list_projects.push_front(new_proj)
	return new_proj

func PROJECT_Remove(project: res_project):
	DATA_global['projects'].erase(project.path)
	list_projects.erase(project)

func PROJECT_Create(path: String):
	var _nam: String=path.get_file().get_basename()
	var _path=path.replace(_nam+".IDBproj",_nam+"/"+_nam+".IDBproj")
	var _dat={
		name=_nam,
		external_node_paths=[
			"{project}/FlowNodes/",
		],
		tags=[],
		tree_expansion={}
	}
	G_File.SAVE_Json(_dat,_path)
	PROJECT_Register(_path)
	PROJECT_Load(_path)


func PROJECT_CreateLua(string: String):
	var s="""
		return {
			name="$project_name",
			linked_script="",
			tables={},
			tags={},
		}
	"""


func PROJECT_Open(project: res_project):
	active_project=project
	DATA_global['last_project']=project.path
	
	PROJECT_RerunScripts()
	
	# Load CUSTOM/OVERRIDE lua
	var _inDir: String=active_project.GetProjectDir()+"/lua/autorun/"
	for i in G_File.LIST_AllInDir(_inDir,true,true):
		Z.L.do_file(i)
		print(" --- project did lua file: "+i)
	G.NODES_RegenLuaTable()

func PROJECT_RerunScripts():
	G.NODES_ReloadAll()
	G.TEMPLATES_ReloadAll()

# ====================================================================
# TABLES
# ====================================================================

func TABLE_GetItem(table: String, entry: String) ->Dictionary:
	return active_project.DataTables.get(table,{}).get(entry,{})

func TABLE_GetItemList(table: String) -> PackedStringArray:
	var _keys: PackedStringArray=active_project.DataTables.get(table,{}).keys()
	#var _ap_keys: PackedStringArray=active_project.DATA.get('tables',{}).get(table,[])
	#_keys.append_array(_ap_keys)
	return _keys


# ====================================================================
# NodeTemapltes
# ====================================================================

func FlowTemplate_GetData(id: String):
	var imps=Z.L.pull_variant('ImpDB_FlowTemplates')
	
	return imps.get(id,{})

func FlowTemplate_GetKeys():
	var tbl=Z.L.pull_variant('ImpDB_FlowTemplates')
	if tbl is Dictionary:
		return tbl.keys()
	return []

# ====================================================================
# USER
# ====================================================================

func USER_init() -> Dictionary:
	var _new={
		name="",
		id=randi_range(0,9999999),
		email="",
	}
	users.push_back(_new)
	return _new

# ====================================================================
# SOUND
# ====================================================================

func SOUND_PlayExternal(path: String):
	var _soundPath=G_File.PathCorrect(path)
	var _SP: AudioStreamPlayer=get_tree().current_scene.get_node("%soundPlayer")
	var _sound=G_Load.SOUND(_soundPath)
	_SP.stream=_sound
	_SP.play()


# ====================================================================
# Raw Script
# ====================================================================
var imported_csv={}
func CSV_get(path: String):
	if imported_csv.has(path):
		return imported_csv[path]
	var dic=G_File.CSV_Import(path)
	imported_csv[path]=dic
	return dic

@export var import_script_directions={}
@export var import_csv={}

func SCRIPT_GetDirectionTextByLineKey() -> Dictionary:
	var line_dir_map: Dictionary[String,String]={}
	var _script_path=G.active_project.DATA.get('linked_script',"")
	var _str=Z_File.LoadFileAsString(_script_path)
	var raw_dic: Array=Z_Parse.from_CSV(_str,true)

	var last_key:=""
	var last_dir:=""
	
	for i in raw_dic:
	
		var check_key:String=i.get('key',"")
		print("getting keys from line: "+check_key)
		
		#if reached a new valid key
		if check_key!=last_key && !check_key.is_empty():
			#if last bulked direction is NOT empty, then apply it to current key
			if !last_dir.is_empty() && !last_key.is_empty():
				line_dir_map[last_key]=last_dir
			#clear direction & update to new key
			last_dir=""
			last_key=check_key
		
		#if this direction line has text, apply it on next line break to bulk dir
		var apnd: String=i.get('direction',"")
		if !apnd.is_empty():
			last_dir+=apnd+"\n"
	
	#dump direction table into json
	Z_File.SaveStringAsFile(G.PATH_GetRoot()+"/_dump/DirectionDump.json", Z_Parse.to_JSON(line_dir_map),true,true)
	
	return line_dir_map



func AutorunPath(path: String):
	var list=G_File.LIST_AllInDir(path,true,true)
	
	for i in list:
		if i.get_extension()=="lua":
			Z.L.do_file(i)


# ====================================================================
# TEMPLATES
# ====================================================================

func TEMPLATES_ReloadAll():
	D_templates={}
	TEMPLATES_LoadAllInPath(G.active_project.GetProjectDir()+"/FlowTemplates/")

func TEMPLATES_LoadAllInPath(path: String):
	for i in G_File.LIST_AllInDir(path):
		var _new=Z.L.do_file(i)
	
	D_templates=Z.L.pull_variant('ImpDB_Templates')

# ====================================================================
# Nodes
# ====================================================================

func NODES_RegenLuaTable():
	var dic2=Z.L.pull_variant('ImpDB_Nodes')
	if dic2 is Dictionary:
		D_nodes=dic2
	else:
		D_nodes={}


func NODES_LoadAllInPath(path: String,group:int=0):
	print("started lua path gen: "+path)
	var _p=G_File.PathCorrect(path)
	var _file_list=G_File.LIST_AllInDir(_p,true,true)
	for i in _file_list:
		if i.get_extension()=="lua":
			var _key=i.get_file().get_basename()
			var _val=Z.L.do_file(i)
			print('did file restult: '+str(i))
			
	NODES_RegenLuaTable()

func NODES_GetKeysAlphabetical() -> Array:
	var _out=D_nodes.keys()
	_out.sort()
	return _out

func get_executable_directory_path():
	if OS.has_feature("editor"):
		return "res://"
	else:
		return OS.get_executable_path().get_base_dir()+"/"

func NODES_ReloadInternal():
	D_nodes={}
	NODES_LoadAllInPath(get_executable_directory_path()+"lua/autorun/nodes/")

func NODES_ReloadAll():
	NODES_ReloadInternal()
	for i in G.GetCONFIG().get("external_node_paths",[]):
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

# ====================================================================
# GRAPH
# ====================================================================

func GRAPH_NewDefault() -> Dictionary:
	return NODE_Default.duplicate(true)

func GRAPH_Export(flow: Dictionary):
	print()
