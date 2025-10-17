extends HBoxContainer

@export var N_FileTree: Tree
@export var N_TextDump: RichTextLabel


func _ready():
	N_FileTree.clear()
	#var _troot=N_FileTree.create_item()
	for i in G_File.LIST_AllInDir("{project}/entities/item/"):
		var _ni: TreeItem= N_FileTree.create_item()
		_ni.set_text(0,i.get_file().get_basename())
