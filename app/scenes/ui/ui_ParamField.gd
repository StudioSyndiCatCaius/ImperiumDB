extends Control
class_name ui_ParamField

@export var N_paramRoot: Control

@export var N_Label: Label

@export var N_edit_string: TextEdit
@export var N_edit_text: TextEdit
@export var N_edit_code: TextEdit

var asset: res__ImpAsset
var template: res__ImpTemplate
var field: String

func get_field_ui() -> Control:
	return N_paramRoot.get_child(template.properties[field].type)

func _ready():
	var field_data=template.properties[field]
	
	N_Label.text=field
	
	for c in N_paramRoot.get_children():
		c.visible=N_paramRoot.get_children().find(c)==field_data.type
	
	custom_minimum_size.y=get_field_ui().get_meta("size",30)
	
	if field_data.type==0:
		$HBoxContainer/Control/CheckButton.toggled=asset.params.get(field,false)
	if field_data.type==1:
		$HBoxContainer/Control/SpinBox.value=asset.params.get(field,0)
	if field_data.type==2:
		N_edit_string.text=asset.params.get(field,"")
	if field_data.type==3:
		N_edit_text.text=asset.params.get(field,"")
	if field_data.type==4:
		N_edit_code.text=asset.params.get(field,"")

func VALUE_SetAs_String(st: String):
	asset.params[field]=st

func _on_edit_string_text_changed():
	VALUE_SetAs_String(N_edit_string.text)

func _on_edit_text_text_changed():
	VALUE_SetAs_String(N_edit_text.text)

func _on_code_edit_text_changed():
	VALUE_SetAs_String(N_edit_code.text)


func _on_spin_box_value_changed(value):
	asset.params[field]=value


func _on_check_button_toggled(toggled_on):
	asset.params[field]=toggled_on
