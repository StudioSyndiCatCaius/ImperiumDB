extends HBoxContainer

@export_category("links")
@export var N_List_Table: ItemList
@export var N_Box_TableItems: Control

var current_table=""

@onready var REF_TableItem=preload("res://app/scenes/ui/ui_TableItem.tscn")

func _ready():
	N_List_Table.clear()
	for i in DatTable():
		N_List_Table.add_item(i)

func DatTable():
	return G.active_project.DataTables;

func _on_item_list_item_selected(index):
	current_table=DatTable().keys()[index]
	G_Node.Children_ClearAll(N_Box_TableItems)
	for i in DatTable()[current_table].keys():
		var _inst = REF_TableItem.instantiate()
		var _dat = DatTable()[current_table][i]
		_inst.DATA_set(_dat)
		N_Box_TableItems.add_child(_inst)
