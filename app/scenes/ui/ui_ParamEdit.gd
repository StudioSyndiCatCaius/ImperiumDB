extends Control
class_name ui_ParamEdit

@export var N_container: Control

var asset: res__ImpAsset
var template: res__ImpTemplate

@onready var REF_ParanField=preload("res://app/scenes/ui/ui_ParamField.tscn")

func OBJECT_MultiMode(on: bool):
	$Label.visible=on

func OBJECT_Clear():
	G_Node.Children_ClearAll(N_container)

func OBJECT_Set(_obj: res__ImpAsset, _template: res__ImpTemplate):
	OBJECT_Clear()
	print("setting paramEdit to: "+str(_obj))
	template=_template
	asset=_obj

	for p in template.properties:
		var new_param: ui_ParamField = REF_ParanField.instantiate()
		new_param.asset=asset
		new_param.template=template
		new_param.field=p
		N_container.add_child(new_param)
