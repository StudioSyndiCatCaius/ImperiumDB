extends Node

var list_projects: Array[res_project]
var active_project: res_project
var dic_projects={}
var path_SaveProj="user://projects.json"

var users=[]

func _ready():
	dic_projects=G_File.LOAD_Json(path_SaveProj)
	for _path in dic_projects.get("projects",[]):
		PROJECT_Load(_path)
	if active_project==null and list_projects.size()>0:
		active_project=list_projects[0]

func _exit_tree():
	G_File.SAVE_Json(dic_projects,path_SaveProj)
	if active_project!=null:
		active_project.__save()

func GetCONFIG() -> Dictionary:
	return active_project.DATA

func PROJECT_Register(path: String):
	dic_projects['projects'].push_back(path)

func PROJECT_Load(path: String):
	print("Loading Project: "+path)
	if !dic_projects['projects'].has(path):
		print("  -- path not in project list. Adding now.")
		PROJECT_Register(path)
	
	#create new project
	var new_proj =res_project.new()
	print("  new project object created as: "+str(new_proj))
	
	new_proj.path=path
	new_proj.DATA=G_File.LOAD_Json(path)
	new_proj.__load(new_proj.DATA)
	list_projects.push_front(new_proj)

func PROJECT_Remove(project: res_project):
	dic_projects['projects'].erase(project.path)
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

func PATH_GetRoot() -> String:
	var str=""
	if active_project:
		str=active_project.path.get_base_dir()
	return str


func PROJECT_Open(project: res_project):
	active_project=project
	
	for i in G_File.LIST_AllInDir(active_project.GetProjectDir()+
	"/lua/autorun/"):
		G_Lua.l.do_file(i)
		print(" --- project did lua file: "+i)
	
	G_Lua.NODES_ReloadAll()
	G_Lua.TEMPLATES_ReloadAll()
func TABLE_GetItem(table: String, entry: String) ->Dictionary:
	return active_project.DataTables.get(table,{}).get(entry,{})

func TABLE_GetItemList(table: String) -> PackedStringArray:
	return active_project.DataTables.get(table,{}).keys()


func USER_init() -> Dictionary:
	var _new={
		name="",
		id=randi_range(0,9999999),
		email="",
	}
	users.push_back(_new)
	return _new
