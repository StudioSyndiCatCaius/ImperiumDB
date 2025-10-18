extends HBoxContainer

@export var N_Current_label: Label
@export var N_Tabs: TabContainer
@export var N_ParamEdit: ui_ParamEdit
@export var N_TextDump: RichTextLabel

var current_path=""
var current_data={}

@onready var s_entityList=preload("res://app/scenes/ui/ui_EntityList.tscn")

func _ready():
	G_Node.Children_ClearAll(N_Tabs)
	#var _troot=N_FileTree.create_item()
	for i in G_Lua.D_templates:
		var n: ui_EntityList=s_entityList.instantiate()
		N_Tabs.add_child(n)
		n.OnSelect.connect(OnEntitySelect)
		n.SETUP(i)


func OnEntitySelect(name, path):
	current_path=path
	N_Current_label.text=name
	current_data=TOML.parse(path)
	N_ParamEdit.OBJECT_Set(current_data,G_Lua.D_templates[TAB_Get().template_name])

func TAB_Get() -> ui_EntityList:
	var _o=N_Tabs.get_child(N_Tabs.current_tab) as ui_EntityList
	return _o

func __SAVE():
	current_path
	TOML.dump(current_path,current_data)
	G_Log.Notification("Saved TOML file to: "+current_path,Color.GREEN)

func _on_tab_container_tab_changed(tab):
	N_ParamEdit.OBJECT_Clear()
