extends res__ImpTemplate
class_name res_FlowNode_type

@export var name=""
@export var color: Color = Color.WHITE
@export var scale: Vector2
@export var UseLinkKey: bool

@export var inputs: Array[res_FlowPin]
@export var outputs: Array[res_FlowPin]

@export var descriptor: res_FlowNode_descriptor
@export var CsvImportFields: PackedStringArray
@export var NextNode: res_FlowNode_type

@export_category("editor")
@export var Exapndable: bool
