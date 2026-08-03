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
var _loading := false
var _is_broken := false

# Shared broken-node StyleBoxes — built once, reused for every broken node instance
static var _bs_titlebar: StyleBoxFlat
static var _bs_titlebar_sel: StyleBoxFlat
static var _bs_panel: StyleBoxFlat
static var _bs_panel_sel: StyleBoxFlat

static func _ensure_broken_styles() -> void:
	if _bs_titlebar != null:
		return
	_bs_titlebar = StyleBoxFlat.new()
	_bs_titlebar.bg_color          = Color(0.40, 0.04, 0.04)
	_bs_titlebar.border_width_left  = 2
	_bs_titlebar.border_width_top   = 2
	_bs_titlebar.border_width_right = 2
	_bs_titlebar.border_width_bottom = 0
	_bs_titlebar.border_color       = Color(0.95, 0.18, 0.18)
	_bs_titlebar.corner_radius_top_left  = 4
	_bs_titlebar.corner_radius_top_right = 4
	_bs_titlebar.content_margin_left   = 8.0
	_bs_titlebar.content_margin_top    = 4.0
	_bs_titlebar.content_margin_right  = 8.0
	_bs_titlebar.content_margin_bottom = 4.0

	_bs_titlebar_sel = _bs_titlebar.duplicate()
	_bs_titlebar_sel.bg_color     = Color(0.60, 0.08, 0.08)
	_bs_titlebar_sel.border_color = Color(1.00, 0.40, 0.40)

	_bs_panel = StyleBoxFlat.new()
	_bs_panel.bg_color           = Color(0.10, 0.01, 0.01, 0.96)
	_bs_panel.border_width_left   = 2
	_bs_panel.border_width_top    = 0
	_bs_panel.border_width_right  = 2
	_bs_panel.border_width_bottom = 2
	_bs_panel.border_color        = Color(0.75, 0.10, 0.10)
	_bs_panel.corner_radius_bottom_left  = 4
	_bs_panel.corner_radius_bottom_right = 4
	_bs_panel.content_margin_left   = 8.0
	_bs_panel.content_margin_top    = 4.0
	_bs_panel.content_margin_right  = 8.0
	_bs_panel.content_margin_bottom = 8.0

	_bs_panel_sel = _bs_panel.duplicate()
	_bs_panel_sel.bg_color     = Color(0.16, 0.02, 0.02, 0.96)
	_bs_panel_sel.border_color = Color(0.95, 0.22, 0.22)

var N_GraphOwner: ui_GraphEdit
var LIST_pins: Array[ui_FlowPin]
var TypeData: Dictionary
var DATA:Dictionary={}

@onready var REF_Pin=preload("res://app/scenes/ui/ui_FlowPin.tscn")

# 0=Label Refresh
signal OnNodeEvent(event)


func DATA_to_CSV():
	var _key: String=DATA.get('key',"")
	var _dir: String=DATA.get('direction',"")
	var _spk: String=DATA.params.get('speaker',"")
	var _line: String=DATA.params.get('line',"")
	
	var out=null
	
	if !_dir.is_empty() or !_spk.is_empty() or !_line.is_empty():
		out={
			key=_key,
			speaker=_spk,
			line=_line,
			direction=_dir,
		}
	return out


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
	return TypeData.get('section_count', 1)


func Setup(node: Dictionary):
	_loading = true
	_is_broken = false
	DATA = node
	# Normalize legacy Godot resource paths to template names
	# e.g. "res://app/res/Nodes/node_DialogueLine.tres" -> "node_DialogueLine"
	var _newType: String = G.NODE_TemplateName(str(DATA.get("_template", "")))
	DATA["_template"] = _newType
	node_type = _newType

	if node_fix_matching.has(_newType):
		_newType = node_fix_matching[_newType]

	var _tmeta = DATA.get('meta', {})
	if _tmeta is Dictionary:
		for i in DATA.get('meta', {}):
			DATA[i] = DATA.get('meta')[i]
	DATA.erase('meta')

	# Always restore position regardless of whether the type is valid
	if DATA.get('position') is Vector2:
		position_offset = DATA.position
	else:
		position_offset = G_Conv.Dic_to_Vec2(DATA.get('position', {}))

	for i in LIST_pins:
		set_slot_enabled_right(LIST_pins.find(i), false)
		set_slot_enabled_left(LIST_pins.find(i), false)
		if i != null:
			i.queue_free()
	LIST_pins.clear()

	if G.D_nodes is Dictionary and G.D_nodes.has(_newType):
		TypeData = G.D_nodes[_newType]
		var _pins_input = TypeData.inputs
		if _pins_input is Dictionary:
			_pins_input = _pins_input.values()
		for i in range(_pins_input.size()):
			ValidateSlotPint(i)
			set_slot_enabled_left(i, true)

		var _pins_output = TypeData.outputs
		if _pins_output is Dictionary:
			_pins_output = _pins_output.values()
		for i in range(_pins_output.size()):
			ValidateSlotPint(i)
			set_slot_enabled_right(i, true)

		for i in range(TypeData.get('section_count', 1)):
			ValidateSlotPint(i)
	else:
		# Unknown type — keep a passthrough slot so connections remain visible
		_is_broken = true
		ValidateSlotPint(0)
		set_slot_enabled_left(0, true)
		set_slot_enabled_right(0, true)

	_loading = false
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
	node_type = node_type.replace(".tres", "")
	LABEL_Regen(false)
	if _is_broken:
		name = DATA.get('label', str(get_instance_id()))
		Refresh_AsBroken()
	else:
		resizable = TypeData.get("exapndable", false)
		Refresh_Title()
		var _inSize: Vector2
		var _scale = TypeData.get('size', {x=110, y=60})
		name = DATA.label
		_inSize.x = _scale.x
		_inSize.y = _scale.y
		if resizable and G_Conv.Dic_to_Vec2(DATA.get('size', {})) != Vector2.ZERO:
			_inSize = G_Conv.Dic_to_Vec2(DATA.size)
		size = _inSize
		var _col = TypeData.get("color", [1, 1, 1, 1])
		self_modulate = Color(_col[0], _col[1], _col[2], _col[3])
	Refresh_Description()

func Refresh_AsBroken():
	_ensure_broken_styles()
	title = "BROKEN NODE"
	self_modulate = Color.WHITE
	size = Vector2(220, 60)
	add_theme_stylebox_override("titlebar",          _bs_titlebar)
	add_theme_stylebox_override("titlebar_selected", _bs_titlebar_sel)
	add_theme_stylebox_override("panel",             _bs_panel)
	add_theme_stylebox_override("panel_selected",    _bs_panel_sel)
	add_theme_color_override("title_color", Color(1.0, 0.78, 0.78))

func Refresh_AsInvalid():
	name = "INVALID (" + node_type + ")"
	modulate = Color.GRAY
	title = "*INVALID* ( " + node_type + ")"

func Refresh_Description():
	Refresh_Title()
	# text
	for i in get_children():
		i._refresh()

func PIN_fix(index : int):
	if get_child(index):
		var d: ui_FlowPin=get_child(index)
		d.NODE_DATA=DATA
		d.NODE_TEMPLATE=TypeData
		d.pin_index=index
		var _section_lua=d.NODE_TEMPLATE.get('sections',{})
		
		if _section_lua is Array:
			var _section_data=_section_lua[index]
			d.SECTION_DATA=_section_data
			if not _loading:
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
	var SizeSlotsToArray=func(a : Array, pin_dic: Dictionary):
		
		var _array: Array=a
		var _array_size: int=a.size()
		
		if _array_size>index:
			pin_dic=_array[index]
			if pin_num<_array_size:
				pin_num=_array_size
	
	# setup pinds
	if TypeData:
		var _inputs=TypeData.get("inputs",[])
		var _outputs=TypeData.get("outputs",[])
		if _inputs is Array:
			SizeSlotsToArray.call(_inputs,new_pin.pin_in)
		if _outputs is Array:
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
	DATA['size'] = G_Conv.Vec2_to_Dic(size)

func SOUND_Play():
	var ext_type: String=G.active_project.DATA.get("voice_ext","wav")
	var _sound_path=G.active_project.PATH_Root()+G.active_project.DATA.get('voice_path',"")+DATA.get('key',"")+"."+ext_type
	_sound_path=_sound_path.simplify_path()
	G.SOUND_PlayExternal(_sound_path)
