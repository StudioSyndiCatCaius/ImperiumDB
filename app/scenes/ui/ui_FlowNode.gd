extends GraphNode
class_name ui_GraphNode

var N_GraphOwner: ui_GraphEdit
var node_data: res_FlowNode_Inst
var LIST_pins: Array[ui_FlowPin]

@onready var REF_Pin=preload("res://app/scenes/ui/ui_FlowPin.tscn")

func NODE_GetTemplate() -> res_FlowNode_type:
	return node_data.template

func Setup(node: res_FlowNode_Inst):
	node_data=node
	node_data.OnParamEdit.connect(_paramEdited)
	name=node.label
	
	position_offset=node.position
	
	if node.template!=null:
		
		print(" ------- doing connections ------- ")
		for i in LIST_pins:
			set_slot_enabled_right(LIST_pins.find(i),false)
			set_slot_enabled_left(LIST_pins.find(i),false)
			if i!=null:
				i.queue_free()
		
		for i in range(node_data.template.inputs.size()):
			print(" doing inputs ")
			var pin=node_data.template.inputs[i]
			ValidateSlotPint(i)
			set_slot_enabled_left(i,true)
		
		for i in range(node_data.template.outputs.size()):
			print(" doing outputs ")
			var pin=node_data.template.outputs[i]
			ValidateSlotPint(i)
			set_slot_enabled_right(i,true)
		Refresh()
	return

func _paramEdited(asset,param,value):
	Refresh()

func Refresh():
	resizable=node_data.template.Exapndable
	
	if node_data.template!=null:
		var _inSize=node_data.template.scale
		if resizable and !node_data.size==Vector2.ZERO:
			_inSize=node_data.size
		size=_inSize
		# SET NAME
		title=node_data.template.name
		var _LinkKey=node_data.template.UseLinkKey
		node_data.label=name
		if _LinkKey:
			title+="("+node_data.key+")"
		self_modulate=node_data.template.color
	if node_data.template.descriptor:
		var _d=node_data.template.descriptor
		ValidateSlotPint(0).set_descript(_d.GetDescription(node_data.params),_d.text_size)

func ValidateSlotPint(index: int) -> ui_FlowPin:
	while get_child(index)==null:
		var new_pin: ui_FlowPin=REF_Pin.instantiate()
		new_pin
		# setup pinds
		if NODE_GetTemplate().inputs.size()>index:
			new_pin.pin_in=NODE_GetTemplate().inputs[index]
		if NODE_GetTemplate().outputs.size()>index:
			new_pin.pin_out=NODE_GetTemplate().outputs[index]
		
		add_child(new_pin)
		LIST_pins.push_back(new_pin)
	return get_child(index)


func _on_position_offset_changed():
	node_data.position=position_offset


func _on_resize_end(new_size):
	node_data.size=size
