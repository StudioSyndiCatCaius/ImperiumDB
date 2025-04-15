extends HBoxContainer

@export_category("links")
@export var N_List_Table: ItemList


func _ready():
	N_List_Table.clear()
	for i in G_Project.active_project.DataTables:
		N_List_Table.add_item(i)
