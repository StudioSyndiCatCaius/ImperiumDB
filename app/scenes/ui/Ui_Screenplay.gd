extends Control
class_name ui_Screenplay

@export var N_listBox : VBoxContainer


@onready var sce_line=preload("res://app/scenes/ui/ui_ScreenplayNode.tscn")

var graph: ui_GraphEdit

func _ready():
	REBUILD()


func REBUILD():
	
	G_Node.Children_ClearAll(N_listBox)
	
	for i in NODES_GetOrder():
		var new_line=sce_line.instantiate()
		new_line.node=i
		N_listBox.add_child(new_line)
	

func NODES_GetOrder() -> Array[ui_GraphNode]:
	var out: Array[ui_GraphNode]
	
	if graph:
		out=graph.NODES_GetSortedOrder()
	
	return out
