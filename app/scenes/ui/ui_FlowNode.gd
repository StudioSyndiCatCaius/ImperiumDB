extends GraphNode
class_name ui_GraphNode

var node_fix_matching={
	node_ScriptIf="node_luaIf",
	node_ScriptEvent="node_luaScript",
	node_ChoiceHUB="node_ChoiceHub",
	
	node_Delay="node_delay",
	node_FlagBool="node_luaIf",
	node_camera="node_Cam",
}

var node_type: String

var N_GraphOwner: ui_GraphEdit
var LIST_pins: Array[ui_FlowPin]
var TypeData: LuaTable
var DATA:Dictionary={}

@onready var REF_Pin=preload("res://app/scenes/ui/ui_FlowPin.tscn")

# 0=Label Refresh
signal OnNodeEvent(event)


func LABEL_Regen(force=false):
	var st=LABEL_Get()
	if st=="" or force:
		LABEL_Set(str(randi_range(0,9999999)))

func LABEL_Get() -> String:
	return DATA.get('label',"")

func LABEL_Refresh():
	name=DATA['label']
	OnNodeEvent.emit('LabelRefresh')

func LABEL_Set(new_label: String):
	DATA['label']=new_label
	LABEL_Refresh()

func DIRECTION_Set(text: String):
	DATA['direction']=text

func DIRECTION_Get() -> String:
	return DATA.get('direction',"")

func getSectionCount() -> int:
	return TypeData.to_dictionary().get('section_count',)

func Setup(node: Dictionary):
	
	#G_Node.Children_ClearAll(self)
	DATA=node
	var _basType: String=DATA._template
	var _newType=_basType.replace("res://app/res/Nodes/","")
	node_type=_newType
	_newType=_newType.replace(".tres","")
	
	Refresh_AsInvalid()
	
	## CORRECT OLD NODE DATA
	if node_fix_matching.has(_newType):
		_newType=node_fix_matching[_newType]
		
	## CORRECT OLD NODE DATA
	var _tmeta=DATA.get('meta',{})
	if _tmeta is Dictionary:
		for i in DATA.get('meta',{}):
			DATA[i]=DATA.get('meta')[i]
	DATA.erase('meta')
	
	#get node typedata
	if G_Lua.D_nodes.has(_newType):
		TypeData=G_Lua.D_nodes[_newType]
		PIN_fix(0)
		if TypeData!=null:
			if DATA.position is Vector2:
				position_offset=DATA.position
			else:
				position_offset=G_Conv.Dic_to_Vec2(DATA.position)
			
			print(" ------- doing connections ------- ")
			for i in LIST_pins:
				set_slot_enabled_right(LIST_pins.find(i),false)
				set_slot_enabled_left(LIST_pins.find(i),false)
				if i!=null:
					i.queue_free()
					
			var _pins_input: Array=TypeData.inputs.to_array()
			for i in range(_pins_input.size()):
				var pin=_pins_input[i]
				ValidateSlotPint(i)
				set_slot_enabled_left(i,true)
			
			var _pins_output: Array=TypeData.outputs.to_array()
			for i in range(_pins_output.size()):
				var pin=_pins_output[i]
				ValidateSlotPint(i)
				set_slot_enabled_right(i,true)
			
			for i in range(TypeData.get('section_count',1)):
				ValidateSlotPint(i)
				print()
			
		Refresh()
	return

func _paramEdited(asset,param,value):
	Refresh()

func Refresh_Title():
	var _newTit=TypeData.get("name","*")
	var _key=DATA.get('key',"")
	if _key=="":
		title=_newTit
	else:
		title=_newTit+" ("+_key+")"

func Refresh():
	LABEL_Regen(false)
	#if type data is valid
	if TypeData!=null:
		resizable=TypeData.get("exapndable",false)
		Refresh_Title()
		var _inSize:Vector2
		var _scale=TypeData.get('size',{x=110,y=60})
		
		name=DATA.label
		_inSize.x=_scale.x
		_inSize.y=_scale.y
		if resizable and !G_Conv.Dic_to_Vec2(DATA.get('size',{}))==Vector2.ZERO:
			_inSize=G_Conv.Dic_to_Vec2(DATA.size)
		size=_inSize

		var _LinkKey=TypeData.get("UseLinkKey",false)

		#if _LinkKey:
		#	title+="("+node_data.key+")"
		var _col=TypeData.get("color",[1,1,1,1])
		if _col is LuaTable:
			_col=_col.to_array()
		self_modulate=Color(_col[0],_col[1],_col[2],_col[3])
	else:
		Refresh_AsInvalid()
	Refresh_Description()

func Refresh_AsInvalid():
	name="INVALID ("+node_type+")"
	modulate=Color.GRAY
	title="*INVALID* ( "+node_type+")"

func Refresh_Description():
	Refresh_Title()
	# text
	var type_dic=TypeData.to_dictionary()
	for i in get_children():
		i._refresh()

func PIN_fix(index : int):
	if get_child(index):
		var d: ui_FlowPin=get_child(index)
		d.NODE_DATA=DATA
		d.NODE_TEMPLATE=TypeData.to_dictionary()
		d.pin_index=index
		var _section_lua=d.NODE_TEMPLATE.get('sections',{})
		_section_lua=G_Lua.CONV(_section_lua)
		
		
		var _section_data=_section_lua.get(index+1,{})
		
		
		d.SECTION_DATA=_section_data
		d._refresh()

func ValidateSlotPint(index: int) -> ui_FlowPin:
	var new_pin: ui_FlowPin
	var is_new_pin:=false
	
	if get_children().size()>index:
		var __c=get_child(index)
		new_pin=__c
	else:
		new_pin=REF_Pin.instantiate()
		LIST_pins.push_back(new_pin)
		is_new_pin=true
	
	#FUNCTION - sizing pin array to slots
	var pin_num=0
	var SizeSlotsToArray=func(a : LuaTable, pin_dic: Dictionary):
		
		var _array: Array=a.to_array()
		var _array_size: int=a.to_array().size()
		
		if _array_size>index:
			print("try add pin to"+str(a)+" on "+node_type)
			pin_dic=_array[index].to_dictionary()
			if pin_num<_array_size:
				pin_num=_array_size
	
	# setup pinds
	if TypeData:
		var _inputs=TypeData.get("inputs",[])
		var _outputs=TypeData.get("outputs",[])
		SizeSlotsToArray.call(_inputs,new_pin.pin_in)
		SizeSlotsToArray.call(_outputs,new_pin.pin_out)
	else:
		new_pin.pin_in={}
		new_pin.pin_out={}
	
	if !get_children().has(new_pin):
		add_child(new_pin)
	
	PIN_fix(index)
	return get_child(index)

func ImportCSV(dat):
	for i in dat:
		DATA['params'][i]=dat[i]
	Refresh()

func _on_position_offset_changed():
	DATA.position=G_Conv.Vec2_to_Dic(position_offset)

func _on_resize_end(new_size):
	DATA.size=size

func SOUND_Play():
	var _sound_path=TypeData.get('GetSoundPath')
	if _sound_path is LuaFunction:
		var _spath=_sound_path.invoke(DATA)
		G.SOUND_PlayExternal(_spath)
