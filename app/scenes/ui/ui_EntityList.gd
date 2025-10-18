extends Control
class_name ui_EntityList

@export var N_tree: ItemList

var template_name=""
var entity_paths=""

signal OnSelect(name: String, path: String)

func SETUP(template: String):
	name=template
	template_name=template
	entity_paths=G_Project.active_project.GetProjectDir()+"/entities/"+template+"/"
	N_tree.clear()
	REFRESH()


func REFRESH():
	for i in G_File.LIST_AllInDir(entity_paths):
		var _ext=i.get_extension()
		if _ext=="TOML" or _ext=="toml":
			N_tree.add_item(i.get_file().get_basename())


func _on_tree_item_activated(index):
	var _name=N_tree.get_item_text(index)
	OnSelect.emit(_name,entity_paths+_name+".toml")
