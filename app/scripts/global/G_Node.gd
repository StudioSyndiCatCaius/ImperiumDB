extends Node


func Children_ClearAll(node: Node):
	for i in node.get_children():
		i.queue_free()

func Children_SetVisible_All(node: Node, visible: bool):
	for i in node.get_children():
		i.visible=visible
			

func Children_SetVisible_Index(node: Node, index: int):
	if node.get_children().size()>index:
		node.get_child(index).visible

func Child_GetByName(node: Node, in_name: String) -> Node:
	for i in node.get_children():
		var _tName=i.name
		if _tName==in_name:
			return i
	return null
