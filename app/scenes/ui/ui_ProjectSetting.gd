extends PanelContainer



enum _type {BOOL, INT}

@export var param_name:=""
@export var display_name:=""
@export var type:_type

@export var N_lbl_name: Label

@onready var N_TypeRoot: Control=$HBoxContainer/Control
@onready var N_checkBox: CheckButton=$HBoxContainer/Control/CheckButton
@onready var N_SpinBox: SpinBox=$HBoxContainer/Control/SpinBox


func _ready():
	N_lbl_name.text=display_name
	G_Node.Children_SetVisible_All(N_TypeRoot,false)
	pass
	if type==_type.BOOL:
		N_checkBox.button_pressed=G.DATA_global.get(param_name,false)
		N_TypeRoot.get_child(0).visible=true
	if type==_type.INT:
		N_SpinBox.value=G.DATA_global.get(param_name,0)
		N_TypeRoot.get_child(1).visible=true


func _on_spin_box_value_changed(value):
	if type==_type.INT:
		print('')
		G.DATA_global[param_name]=value

func _on_check_button_toggled(toggled_on):
	if type==_type.BOOL:
		print('')
		G.DATA_global[param_name]=toggled_on
