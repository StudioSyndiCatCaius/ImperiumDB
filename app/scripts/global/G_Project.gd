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

func PROJECT_Load(path: String):
	print("Loading Project: "+path)
	if !dic_projects['projects'].has(path):
		print("  -- path not in project list. Adding now.")
		dic_projects['projects'].push_back(path)
	
	#create new project
	var new_proj =res_project.new()
	print("  new project object created as: "+str(new_proj))
	
	new_proj.path=path
	new_proj.DATA=G_File.LOAD_Json(path)
	new_proj.__load(new_proj.DATA)
	list_projects.push_front(new_proj)

func GetCONFIG() -> Dictionary:
	return G_Project.active_project.DATA

func PROJECT_Remove(project: res_project):
	dic_projects['projects'].erase(project.path)
	list_projects.erase(project)


func PATH_GetRoot() -> String:
	var str=""
	if active_project:
		str=active_project.path.get_base_dir()
	return str


func LOAD(project: res_project):
	active_project=project
	G_Lua.NODES_ReloadAll()

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
