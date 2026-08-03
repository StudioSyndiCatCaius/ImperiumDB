extends HBoxContainer

@export var param_name:=""
@export var display_name:=""
@export var defaultValue:=""

@export var N_txtEdit: TextEdit
@export var n_label: Label

func _ready():
	n_label.text=display_name
	if N_txtEdit:
		N_txtEdit.text=getDic().get(param_name,defaultValue)

func getDic() ->Dictionary:
	return G.active_project.DATA

func _on_text_edit_text_changed():
	getDic()[param_name]=N_txtEdit.text
