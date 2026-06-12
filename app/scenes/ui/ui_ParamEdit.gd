extends Control
class_name ui_ParamEdit

var current_object={}
var current_template: Dictionary

@export var key=""
@export var N_container: GridContainer
@export var N_CmdContainer: Container
@export var columns=1

var ui_types={}
@onready var REF_ParanField=preload("res://app/scenes/ui/ui_ParamField.tscn")
@onready var REF_CmdButton=preload("res://app/scenes/ui/ui_CmdButton.tscn")

func _ready():
	N_container.columns=columns
	G_Node.Children_ClearAll(N_container)
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
	current_object={}
	current_template={}
	G_Node.Children_ClearAll(N_container)

func OBJECT_Set(_obj: Dictionary, _template: Dictionary):
	OBJECT_Clear()
	current_object=_obj
	current_template=_template
	if !_obj:
		print("could not set ParamEdit object: object is invalid")
		return
	if !_template:
		print("could not set ParamEdit object: template is invalid")
		return
	
	var plist: Dictionary=_template.get('params',{})
	var key_list: Array =plist.keys()
	key_list.sort_custom(func(a,b):
		return plist[a].get('order',0) < plist[b].get('order',0)
	)
	for i in key_list:
		var _type=plist[i].get('type')
		if ui_types.has(_type):
			var newp: ui_pEdit=ui_types[_type].instantiate()
			newp.paramName=i
			newp.paramCategory=key
			newp.paramConfig=plist[i]
			newp.Setup(_obj)
			newp.OnParamEdit.connect(_op)
			newp.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			N_container.add_child(newp)
	
	#load commands
	G_Node.Children_ClearAll(N_CmdContainer)
	var _cmdList=_template.get('cmd',[])
	for i in _cmdList:
		var _newCmd: ui_CmdButton=REF_CmdButton.instantiate()
		_newCmd.cmd_key=i
		_newCmd.OnSelect.connect(_OnCmdSelect)
		N_CmdContainer.add_child(_newCmd)

func _OnCmdSelect(key:String):
	if current_template:
		var _temp=current_template
		var _func=_temp.cmd[key]
		if _func is Callable:
			var _output=_func.invoke(current_object)
			if _output is Dictionary:
				
				#Play Sound
				if _output.get('action','')=='PlaySound':
					var _soundPath=_output.get('path','')
					_soundPath=G_File.PathCorrect(_soundPath)
					var _SP: AudioStreamPlayer=get_tree().current_scene.get_node("%soundPlayer")
					var _sound=G_Load.SOUND(_soundPath)
					_SP.stream=_sound
					_SP.play()

func _op(param: String, value):
	print('migo')
	OnParamEdit.emit(param,value)
