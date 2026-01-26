extends Control
class_name ui_ParamField

@export var N_paramRoot: Control

@export var N_Label: Label

@export var N_edit_string: TextEdit
@export var N_edit_text: TextEdit
@export var N_edit_code: CodeEdit
@export var N_edit_list: OptionButton
@export var N_edit_bool: CheckBox
@export var N_edit_spin: SpinBox

var autocomplete_functions=[
	"move_player",
	"jump_action", 
	"attack_enemy",
	"collect_item",
	"open_door",
	"save_game",
	"load_game"
]

var asset: res__ImpAsset
var template: res__ImpTemplate
var field: String

func get_field_ui() -> Control:
	return N_paramRoot.get_child(template.properties[field].type)

func _ready():
	
	var field_data=template.properties[field]
	var _val=asset.params.get(field,"")
	var _default_val=template.properties[field].default
	tooltip_text=field_data.tooltip
	
	N_Label.text=field
	
	for c in N_paramRoot.get_children():
		c.visible=N_paramRoot.get_children().find(c)==field_data.type
	
	custom_minimum_size.y=get_field_ui().get_meta("size",30)
	
	if field_data.type==0:
		N_edit_bool.button_pressed=asset.params.get(field,_default_val)
	if field_data.type==1:
		N_edit_spin.value=asset.params.get(field,0)
	if field_data.type==2:
		N_edit_string.text=_val
	if field_data.type==3:
		N_edit_text.text=_val
	if field_data.type==4:
		N_edit_code.text=_val
	if field_data.type==5:

		N_edit_list.clear()
		var list=G.TABLE_GetItemList(field_data.table)
		var _valIndex=-1
		for i in list:
			var _idx=list.find(i)
			var _imgPath=G.PATH_GetRoot()+"/image/ico_"+field_data.table+"_"+i+".png"
			var _ico=G_File.LOAD_Texture(_imgPath)
			var _tblData=G.TABLE_GetItem(field_data.table,i)
			
			N_edit_list.add_item(i)
			N_edit_list.set_item_tooltip(_idx,_tblData.get("description",""))
			N_edit_list.set_item_icon(_idx,_ico)
			
			if i == _val:
				_valIndex=list.find(i)
		N_edit_list.select(_valIndex)

func VALUE_SetAs_String(st: String):
	asset.Param_Set(field,st)

func _on_edit_string_text_changed():
	VALUE_SetAs_String(N_edit_string.text)

func _on_edit_text_text_changed():
	VALUE_SetAs_String(N_edit_text.text)

func _on_N_edit_code_text_changed():
	N_edit_code.request_code_completion(true)
	VALUE_SetAs_String(N_edit_code.text)

func _on_spin_box_value_changed(value):
	asset.Param_Set(field,value)

func _on_check_button_toggled(toggled_on):
	asset.Param_Set(field,toggled_on)

func _on_edit_list_item_selected(index):
	VALUE_SetAs_String(N_edit_list.get_item_text(index))
