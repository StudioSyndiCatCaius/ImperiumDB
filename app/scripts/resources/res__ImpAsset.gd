extends Resource
class_name res__ImpAsset

var linked_file: String
@export var template: res__ImpTemplate
@export var label=""
@export var id:int
@export var tags: PackedStringArray
@export var params={}

signal OnParamEdit(asset: res__ImpAsset,param: String, value)

func _init():
	print("argo: "+str(self))

	
func META_Save(dic: Dictionary):
	pass

func META_Load(dic: Dictionary):
	pass

func get_base_resource_path(path: String) -> String:
	var base = path.split("::")[0]  # remove subresource part if any
	return base.get_basename()+".tres"     # remove extension like .tres or .res

func JSON_Get() -> Dictionary:
	var json_output={ meta={} }
	if template:
		json_output['_template']=get_base_resource_path(template.resource_path)
	json_output['label']=label
	json_output['id']=id
	json_output['tags']=tags
	json_output['params']=params
	META_Save(json_output.meta)
	return json_output

func JSON_Set(json: Dictionary):
	print("  --  load "+str(json))
	label=json.get('label','')
	id=json.get('id',-1)
	tags=json.get('tags',[])
	params=json.get('params',{})
	template=load(json.get('_template',""))
	META_Load(json.get('meta',{}))

func SAVE(path: String=""):
	if !path.is_empty() or !File_IsValid():
		linked_file=path
	G_File.SAVE_Json(JSON_Get(),linked_file)

func LOAD(path: String):
	print("loading "+str(self)+" as "+path)
	#ResourceLoader.load(path)
	linked_file=path
	JSON_Set(G_File.LOAD_Json(path))

func File_IsValid():
	return FileAccess.file_exists(linked_file)

func Param_Set(param: String, value):
	params[param]=value
	OnParamEdit.emit(self,param,value)
