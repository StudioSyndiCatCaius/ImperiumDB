extends Resource
class_name res__ImpTemplate

@export var properties: Dictionary[StringName,res_ParamType]
var path_subfolder="/*/"

func PATH_Get():
	return G_Project.PATH_GetRoot()+path_subfolder
