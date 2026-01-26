extends Resource
class_name res__ImpTemplate

@export var icon: Texture2D
var path_subfolder="/*/"

func PATH_Get():
	return G.PATH_GetRoot()+path_subfolder
