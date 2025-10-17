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
				print(" doing inputs ")
				var pin=TypeData.inputs.to_array()[i]
				ValidateSlotPint(i)
				set_slot_enabled_left(i,true)
			
			for i in range(TypeData.outputs.to_array().size()):
				print(" doing outputs ")
				var pin=TypeData.outputs.to_array()[i]
				ValidateSlotPint(i)
				set_slot_enabled_right(i,true)
				
		Refresh()
	return

func _paramEdited(asset,param,value):
	Refresh()

func Refresh():
	#if type data is valid
	if TypeData!=null:
		resizable=TypeData.get("exapndable",false)
		var _newTit=TypeData.get("name","*")
		title=_newTit+"("+DATA.get('key',"")+")"
		var _inSize:Vector2
		var _scale=TypeData.get('size',{x=110,y=60})
		
		name=DATA.label
		_inSize.x=_scale.x
		_inSize.y=_scale.y
		if resizable and !G_Conv.Dic_to_Vec2(DATA.size)==Vector2.ZERO:
			_inSize=G_Conv.Dic_to_Vec2(DATA.size)
		size=_inSize

		var _LinkKey=TypeData.get("UseLinkKey",false)

		#if _LinkKey:
		#	title+="("+node_data.key+")"
		var _col=TypeData.get("color",[1,1,1,1]).to_array()
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
	
	if TypeData.get("GetDescription")!=null:
		var result=TypeData.GetDescription.invoke(DATA)
		if result is String:
			ValidateSlotPint(0).set_descript(result,
			type_dic.get('description_size',12))
	
	if TypeData.get("GetIcon")!=null:
		var result=TypeData.GetIcon.invoke(DATA)
		if result is String:
			ValidateSlotPint(0).set_icon(G_File.LOAD_Texture(result),
			type_dic.get('icon_size',50))

func ValidateSlotPint(index: int) -> ui_FlowPin:
	while get_child(index)==null:
		var new_pin: ui_FlowPin=REF_Pin.instantiate()
		#new_pin
		# setup pinds
		if TypeData:
			var _inputs=TypeData.get("inputs",[])
			var _outputs=TypeData.get("outputs",[])
			if _inputs.to_array().size()>index:
				new_pin.pin_in=_inputs.to_array()[index].to_dictionary()
			if _outputs.to_array().size()>index:
				new_pin.pin_out=_outputs.to_array()[index].to_dictionary()
		else:
			new_pin.pin_in={}
			new_pin.pin_out={}
		
		add_child(new_pin)
		LIST_pins.push_back(new_pin)
	return get_child(index)

func ImportCSV(dat):
	pass

func _on_position_offset_changed():
	DATA.position=G_Conv.Vec2_to_Dic(position_offset)

func _on_resize_end(new_size):
	DATA.size=size
