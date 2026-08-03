extends Resource
class_name res_project

@export var name:=""
@export var path:=""
@export var image: Texture2D
@export var DataTables={}
var DATA={
	name="",
	tags=[],
}
var PLUGIN={
	
}

func genIfNotExist(file:String,default:String):
	if !FileAccess.file_exists(file):
		Z_File.SaveStringAsFile(file,default,true,true)

func GENERATE():
	var file_proj:=path
	var file_plugin:=file_proj.replace(".IDBproj",".IDBplugin")
	#if project file does not exist,
	if !FileAccess.file_exists(file_proj):
		SAVE()
	
	#GEN plugin
	genIfNotExist(file_plugin,"""return {
		tables={
			{name='characters', cells={ {name='key',type='string'},{name='name',type='string'} }},
			{name='items', cells={ {name='key',type='string'},{name='name',type='string'} }},
			{name='flags', cells={ {name='key',type='string'},{name='name',type='string'} }},
		}
	}""")
	

func PATH_Root():
	return path.get_base_dir()



func PATH_ToProjCoreFile(new_extenstion:String):
	return path.replace(".IDBproj","."+new_extenstion)

func UserMeta_Get() -> Dictionary:
	return G.DATA_global.get('project_meta',{}).get(path,{})

func UserMeta_GetBool(name:String) -> bool:
	return Z_Lit.BOOL(UserMeta_Get().get(name,false),false)

func UserData_Get() -> Dictionary:
	if !G.DATA_global.has('per_project'):
		G.DATA_global['per_project']={}
	if !G.DATA_global['per_project'].has(path):
		G.DATA_global['per_project'][path]={}
	return G.DATA_global['per_project'].get(path,{})

func TreeExpansion_Get(file_path: String) -> bool:
	return G.DATA_global\
		.get('per_project', {})\
		.get(path, {})\
		.get('tree_expansion', {})\
		.get(file_path, false)

func TreeExpansion_Set(file_path: String, expanded: bool):
	if !G.DATA_global.has('per_project'):
		G.DATA_global['per_project'] = {}
	if !G.DATA_global['per_project'].has(path):
		G.DATA_global['per_project'][path] = {}
	if !G.DATA_global['per_project'][path].has('tree_expansion'):
		G.DATA_global['per_project'][path]['tree_expansion'] = {}
	G.DATA_global['per_project'][path]['tree_expansion'][file_path] = expanded

func GetProjectDir():
	return G_String.Split_AtCharacter(path,"/",true)[0]

func SAVE() :
	var out=DATA
	out['name']=name
	
	# ssave Project
	var outString:=Z_Parse.to_JSON(out)
	Z_File.SaveStringAsFile(path,outString,true,true)

func LOAD_fromPath(path: String):
	var st=Z_File.LoadFileAsString(path)
	var data_loaded:Dictionary
	var lua_out=Z.L.do_string(st)
	if lua_out is Dictionary:
		data_loaded=lua_out
	else:
		data_loaded=Z_Parse.from_JSON(st)
	
	LOAD_fromDictionary(data_loaded)
	PLUGIN=Z.L.do_file(PATH_ToProjCoreFile("IDBplugin"))


func LOAD_fromDictionary(data: Dictionary):
	DATA=data
	name=data.get("name","")
	var img_path=PATH_ToProjCoreFile("png")
	print("projpath is: "+GetProjectDir())
	image=G_File.LOAD_Texture(img_path)
	
	#load tables
	for i in G_File.LIST_AllInDir(GetProjectDir()+"/tables/"):
		var _ext := i.get_extension()
		if _ext != "csv" and _ext != "tbl":
			continue
		var _nam=i.get_file().split(".")[0]
		print("   Register table "+_nam)
		DataTables[_nam]=G_File.CSV_Import(i)

func TABLE_GetConfig() -> Dictionary:
	var out:={}
	
	for i in TABLE_GetConfigArray():
		out[i.get('name',"")]=i
	
	return out

func TABLE_GetConfigArray() -> Array:
	PLUGIN=Z.L.do_file(PATH_ToProjCoreFile("IDBplugin"))
	if PLUGIN is Dictionary:
		return Z_Lit.ARRAY(PLUGIN.get('tables',[]),[])
	return []

func TABLE_GetKeys(table: String) -> PackedStringArray:
	return DataTables.get(table,{}).keys()

func TABLE_GetEntry(table: String, entry: String):
	return DataTables.get(table,{}).get(entry,{})


func SCREENPLAY_GetPdfConfig() ->Dictionary:

	var _def={
		columns={
			key={
				text_size=7,
				cell_color="#b0b0b0",
				size_ratio=0.5,
			},
			speaker={
				text_bold=true,
				text_size=9,
				cell_color="#abbeff",
				size_ratio=0.5,
			},
			line={
				size_ratio=2.0,
			},
			direction={
				#text_color="#52481b",
				cell_color="#ffd86e"
			},
		},
	}
	var _j: Dictionary=DATA.get('screenplay_config',_def)
	DATA['screenplay_config']=_j
	return _j
