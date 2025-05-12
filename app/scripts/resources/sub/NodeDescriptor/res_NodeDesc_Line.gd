extends res_FlowNode_descriptor
class_name res_NodeDesc_Line

@export var param_a="speaker"
@export var param_b="line"

func GetDescription(data) -> String:
	var out=""
	out=data.get(param_a,"")+": \n	''"+data.get(param_b,"")+"''"
	return out
	
