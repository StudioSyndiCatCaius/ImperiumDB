extends Node

var active_project: res_project


func _ready():
	if G_Project.active_project==null and G_Save.list_projects.size()>0:
		G_Project.active_project=G_Save.list_projects[0]

func PATH_GetRoot() -> String:
	var str=active_project.path.get_base_dir()
	return str

func _exit_tree():
	if active_project!=null:
		active_project.__save()


func LOAD(project: res_project):
	active_project=project
