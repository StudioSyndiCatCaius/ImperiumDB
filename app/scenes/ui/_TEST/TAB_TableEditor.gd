extends PanelContainer
class_name ui_TablesEditor



@export var tab_container: TabContainer
const UI_TABLE_EDITOR = preload("uid://cca0n6v7t3edr")

func _ready():
	ReloadTables()


func ReloadTables():
	G_Node.Children_ClearAll(tab_container)
	await get_tree().create_timer(0.05)
	var cfg=G.active_project.TABLE_GetConfig()
	for i in cfg:
		var new_table:ui_TableEditor=UI_TABLE_EDITOR.instantiate()
		new_table._Setup(i)
		tab_container.add_child(new_table)


func _on_tab_bar_tab_button_pressed(tab):
	var g=G.active_project.TABLE_GetConfigArray()[tab]
	if g:
		print()


func _on_z_1d_input_input_started(node, value):
	print("gooba")


func _on_btn_save_pressed():
	var i=tab_container.get_child(0)
	if i is ui_TableEditor:
		i.CSV_save()


func _on_btn_sav_eall_pressed():
	for i in tab_container.get_children():
		if i is ui_TableEditor:
			i.CSV_save()


func _on_btn_reload_tables_pressed():
	ReloadTables()
