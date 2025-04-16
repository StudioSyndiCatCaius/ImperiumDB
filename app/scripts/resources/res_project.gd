extends Resource
class_name res_project

@export var name=""
@export var path=""
@export var tags: PackedStringArray
@export var image: Texture2D
@export var tree_expansion={}
@export var DataTables={}

var loaded_graphs: res_FlowGraph

func GetProjectDir():
	return G_String.Split_AtCharacter(path,"/",true)[0]

func __save() :
	var out: Dictionary
	out['name']=name
	out['tags']=tags
	out['tree_expansion']=tree_expansion
	G_File.SAVE_Json(out,path)

	
func __load(data: Dictionary):
	name=data.get("name","")
	tags=data.get("tags",[])
	tree_expansion=data.get("tree_expansion",{})
	var img_path=path.replace(".IDBproj",".png")
	print("projpath is: "+GetProjectDir())
	image=G_File.LOAD_Texture(img_path)
	
	#load tables
	for i in G_File.LIST_AllInDir(GetProjectDir()+"/tables/"):
		var _nam=i.get_file().split(".")[0]
		print("   Register table "+_nam)
		DataTables[_nam]=G_File.CSV_Import(i)

func TABLE_GetKeys(table: String) -> PackedStringArray:
	return DataTables.get(table,{}).keys()

func TABLE_GetEntry(table: String, entry: String):
	return DataTables.get(table,{}).get(entry,{})
