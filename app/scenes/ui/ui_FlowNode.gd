extends GraphNode
class_name ui_GraphNode


var node_data: res_FlowNode_Inst

var LIST_pins: Array[ui_FlowPin]

@onready var REF_Pin=preload("res://app/scenes/ui/ui_FlowPin.tscn")

func Setup(node: res_FlowNode_Inst):
	node_data=node
	name=node.label
	
	position_offset=node.position
	
	if node.template!=null:
		size=node.template.scale
		title=name
		self_modulate=node.template.color
		
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
		
	return

func ValidateSlotPint(index: int) -> ui_FlowPin:
	while get_child(index)==null:
		var new_pin=REF_Pin.instantiate()
		add_child(new_pin)
		LIST_pins.push_back(new_pin)
	return get_child(index)


func _on_position_offset_changed():
	node_data.position=position_offset
