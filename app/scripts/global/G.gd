extends Node


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
	DATA_global=G_File.LOAD_Json(path_SaveProj,DATA_global)
	for _path in DATA_global.get("projects",[]):
		PROJECT_Load(_path)
	if active_project==null and list_projects.size()>0:
		active_project=list_projects[0]

func _exit_tree():
	G_File.SAVE_Json(DATA_global,path_SaveProj)
	if active_project!=null:
		active_project.__save()

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
	new_proj.DATA=G_File.LOAD_Json(path)
	new_proj.__load(new_proj.DATA)
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

func PROJECT_Open(project: res_project):
	active_project=project
	DATA_global['last_project']=project.path
	
	PROJECT_RerunScripts()
	
	# Load CUSTOM/OVERRIDE lua
	var _inDir: String=active_project.GetProjectDir()+"/lua/autorun/"
	for i in G_File.LIST_AllInDir(_inDir,true,true):
		G_Lua.l.do_file(i)
		print(" --- project did lua file: "+i)
	print("here da ting:" +str(G_Lua.l.globals.ImpDB_Nodes.to_dictionary()))
	G_Lua.NODES_RegenLuaTable()

func PROJECT_RerunScripts():
	G_Lua.NODES_ReloadAll()
	G_Lua.TEMPLATES_ReloadAll()

# ====================================================================
# TABLES
# ====================================================================

func TABLE_GetItem(table: String, entry: String) ->Dictionary:
	return active_project.DataTables.get(table,{}).get(entry,{})

func TABLE_GetItemList(table: String) -> PackedStringArray:
	return active_project.DataTables.get(table,{}).keys()

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
func SCRIPT_GetDirectionTextByLineKey() -> Dictionary[String,String]:
	var out: Dictionary[String,String]={}
	
	var _script_path=G_Lua.l.globals.to_dictionary().get('IMPDB_SCRIPT_PATH','')
	var direction_text=""
	var data = G_File.CSV_ImportArray(_script_path)
	
	for k in data:
		var new_dir=k.get('direction',"")
		if !new_dir.is_empty():
			direction_text+=new_dir+"\n --- \n"
			
		var line_key=k.get('key',"")
		# if on new line
		if !line_key.is_empty():
			out[line_key]=direction_text
			direction_text=""
	return out
