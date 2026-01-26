extends GraphNode
class_name ui_GraphNode

var node_fix_matching={
	node_ScriptIf="node_luaIf",
	node_ScriptEvent="node_luaScript",
	node_ChoiceHUB="node_ChoiceHub"
}

var node_type: String

var N_GraphOwner: ui_GraphEdit
var LIST_pins: Array[ui_FlowPin]
var TypeData: LuaTable
var DATA:Dictionary={}

@onready var REF_Pin=preload("res://app/scenes/ui/ui_FlowPin.tscn")

# 0=Label Refresh
signal OnNodeEvent(event)

func _ready() -> void:
	G_Node.Children_ClearAll(self)

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
	DATA=node
	var _basType: String=DATA._template
	var _newType=_basType.replace("res://app/res/Nodes/","")
	node_type=_newType
	_newType=_newType.replace(".tres","")
	
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
		PIN_fix(get_child(0),0)
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
			
			for i in range(TypeData.inputs.to_array().size()):
				var pin=TypeData.inputs.to_array()[i]
				ValidateSlotPint(i)
				set_slot_enabled_left(i,true)
			
			for i in range(TypeData.outputs.to_array().size()):
				var pin=TypeData.outputs.to_array()[i]
				ValidateSlotPint(i)
				set_slot_enabled_right(i,true)
			
			for i in range(TypeData.get('section_count',1)+1):
				ValidateSlotPint(i)
			
		Refresh()
	return

func _paramEdited(asset,param,value):
	Refresh()

func Refresh():
	LABEL_Regen(false)
	#if type data is valid
	if TypeData!=null:
		resizable=TypeData.get("exapndable",false)
		var _newTit=TypeData.get("name","*")
		var _key=DATA.get('key',"")
		if _key=="":
			title=_newTit
		else:
			title=_newTit+" ("+_key+")"
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
	ValidateSlotPint(0)
	modulate=Color.GRAY
	title="*INVALID* ( "+node_type+")"

func Refresh_Description():
	# text
	var type_dic=TypeData.to_dictionary()
	for i in get_children():
		i._refresh()

func PIN_fix(d: ui_FlowPin, index : int):
	d.NODE_DATA=DATA
	d.NODE_TEMPLATE=TypeData.to_dictionary()
	d.pin_index=index
	d.SECTION_DATA=TypeData.get('sections',{}).get(index,{})
	
	if d.SECTION_DATA is LuaTable:
		d.SECTION_DATA=d.SECTION_DATA.to_dictionary()

func ValidateSlotPint(index: int) -> ui_FlowPin:
	
	while get_child(index)==null:
		var new_pin: ui_FlowPin=REF_Pin.instantiate()
		PIN_fix(new_pin,index)
		var pin_num=0
		
		var SizeSlotsToArray=func(a : LuaTable):
			if a.to_array().size()>index:
				new_pin.pin_in=a.to_array()[index].to_dictionary()
				var array_size: int=a.to_array().size()
				if pin_num<array_size:
					pin_num=array_size
		
		#new_pin
		# setup pinds
		if TypeData:
			var _inputs=TypeData.get("inputs",[])
			var _outputs=TypeData.get("outputs",[])
			SizeSlotsToArray.call(_inputs)
			SizeSlotsToArray.call(_outputs)
		else:
			new_pin.pin_in={}
			new_pin.pin_out={}
		
		add_child(new_pin)
		LIST_pins.push_back(new_pin)
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
