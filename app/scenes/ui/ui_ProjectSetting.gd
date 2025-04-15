extends PanelContainer



enum _type {BOOL, INT}

@export var Name=""
@export var type:_type


@onready var N_TypeRoot: Control=$HBoxContainer/Control

@onready var N_checkBox: CheckButton=$HBoxContainer/Control/CheckButton
@onready var N_SpinBox: SpinBox=$HBoxContainer/Control/SpinBox

func _ready():
	
	G_Node.Children_SetVisible_All(N_TypeRoot,false)
	
	if type==_type.BOOL:
		N_checkBox.toggle_mode=G_Save.dic_projects.get(Name,false)
		N_TypeRoot.get_child(0).visible=true
	if type==_type.INT:
		N_SpinBox.value=G_Save.dic_projects.get(Name,0)
		N_TypeRoot.get_child(1).visible=true


func _on_spin_box_value_changed(value):
	if type==_type.INT:
		G_Save.dic_projects[Name]=value

func _on_check_button_toggled(toggled_on):
	if type==_type.BOOL:
		G_Save.dic_projects[Name]=toggled_on
