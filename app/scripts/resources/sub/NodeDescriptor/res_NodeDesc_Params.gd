extends res_FlowNode_descriptor
class_name res_NodeDesc_Params

func GetDescription(data) -> String:
	var out=""
	for i in data:
		out+=i+"="+str(data.get(i,"\n"))
	return out
