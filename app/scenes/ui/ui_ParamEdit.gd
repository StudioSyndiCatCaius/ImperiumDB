extends Control
class_name ui_ParamEdit

@export var N_container: Control

var ui_types={}
@onready var REF_ParanField=preload("res://app/scenes/ui/ui_ParamField.tscn")

func _ready():
	ui_types['text']=preload("res://app/scenes/ui/pEdit/pEdit_text.tscn")
	ui_types['string']=preload("res://app/scenes/ui/pEdit/pEdit_string.tscn")
	ui_types['number']=preload("res://app/scenes/ui/pEdit/pEdit_int.tscn")
	ui_types['bool']=preload("res://app/scenes/ui/pEdit/pEdit_bool.tscn")
	ui_types['code']=preload("res://app/scenes/ui/pEdit/pEdit_code.tscn")
	ui_types['table']=preload("res://app/scenes/ui/pEdit/pEdit_table.tscn")


signal OnParamEdit(param: String, value)

func OBJECT_MultiMode(on: bool):
	$Label.visible=on

func OBJECT_Clear():
	G_Node.Children_ClearAll(N_container)

func OBJECT_Set(_obj: Dictionary, _template: LuaTable):
	OBJECT_Clear()
	if !_obj:
		print("could not set ParamEdit object: object is invalid")
		return
	if !_template:
		print("could not set ParamEdit object: template is invalid")
		return
	
	var plist: Dictionary=G_Lua.CONV(_template.get('params',{}))
	var key_list: Array =plist.keys()
	key_list.sort_custom(func(a,b):
		return plist[a].get('order',0) < plist[b].get('order',0)
	)
	for i in key_list:
		var _type=plist[i].get('type')
		if ui_types.has(_type):
			var newp: ui_pEdit=ui_types[_type].instantiate()
			newp.paramName=i
			newp.paramConfig=plist[i]
			newp.Setup(_obj,_template)
			newp.OnParamEdit.connect(_op)
			$ScrollContainer/VBoxContainer.add_child(newp)

func _op(param: String, value):
	print('migo')
	OnParamEdit.emit(param,value)
