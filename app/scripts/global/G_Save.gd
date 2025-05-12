extends Node

var dic_projects={}
var path_SaveProj="user://projects.json"
var list_projects: Array[res_project]
var users=[]


func USER_init() -> Dictionary:
	var _new={
		name="",
		id=randi_range(0,9999999),
		email="",
	}
	users.push_back(_new)
	return _new

func _ready():
	dic_projects=G_File.LOAD_Json(path_SaveProj)
	for _path in dic_projects.get("projects",[]):
		PROJECT_Load(_path)

func _exit_tree():
	G_File.SAVE_Json(dic_projects,path_SaveProj)

func PROJECT_Load(path: String):
	
	if !dic_projects['projects'].has(path):
		dic_projects['projects'].push_back(path)
		
	var new_proj =res_project.new()
	new_proj.path=path
	new_proj.__load(G_File.LOAD_Json(path))
	list_projects.push_front(new_proj)

func PROJECT_Remove(project: res_project):
	dic_projects['projects'].erase(project.path)
	list_projects.erase(project)
