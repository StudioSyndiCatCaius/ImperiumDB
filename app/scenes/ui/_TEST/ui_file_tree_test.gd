extends PanelContainer

@export var file_tree: FileTree

func _ready():
	file_tree.root_path="D:/PROJECTS/Work/Noiramore/JudithTestClassroom/Content/__ImpDB/flow/"
	file_tree.recursive=true
	file_tree.rebuild_tree()
	file_tree.set_expanded_bulk(G.active_project.DATA.get('tree_expansion',{}))


func _on_file_tree_file_selected(file_path):
	print(file_tree.get_expanded_bulk())
