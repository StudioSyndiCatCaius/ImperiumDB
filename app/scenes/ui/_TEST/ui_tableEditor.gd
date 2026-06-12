extends PanelContainer
class_name ui_TableEditor

@export var table_editor: Zen_TableEditor

var CONFIG:={}
var table_key:=""
var csv_path:=""
var proj_ref: res_project

func _ready():
	proj_ref=G.active_project

func _Setup(new_key):
	table_key=new_key
	name=new_key
	table_editor.data=[]
	table_editor.columns=[]
	
	CONFIG=G.active_project.TABLE_GetConfig().get(table_key,{})
	
	for i in CONFIG.get('cells',[]):
		var new_cell_config:=Zen_TableCellConfig.new()
		new_cell_config.column_name=i.get('name')
		var new_cell_type:Zen_ParamType
		var param_type:=""
		param_type=i.get('type',"")
		new_cell_config.cell_ratio=i.get('cell_ratio',1)
		
		if param_type=="int":
			new_cell_type= Zen_ParamType_Number.new()
			new_cell_type.is_float=false
			new_cell_type.clamp=true
			new_cell_type.max_value=i.get('max',9999)
			new_cell_type.min_value=i.get('min',0)
			
		elif param_type=="options":
			new_cell_type= Zen_ParamType_Options.new()
			new_cell_type.options=i.get('options',[])
		elif param_type=="bool":
			new_cell_type= Zen_ParamType_Bool.new()
		else:
			pass
	
		new_cell_config.param_type=new_cell_type
		table_editor.columns.push_back(new_cell_config)
	
	CSV_load()

func CSV_getPath() -> String:
	return G.PATH_GetRoot()+"/tables/"+table_key+".csv"

func CSV_getString() -> String:
	return Z_File.LoadFileAsString(CSV_getPath())

func CSV_load():
	var d=Z_Parse.from_CSV(CSV_getString(),true)
	table_editor.data=d

func CSV_save():
	var str_to_sav=Z_Parse.to_CSV(table_editor.data)
	Z_File.SaveStringAsFile(CSV_getPath(),str_to_sav,true,true)
	G_Log.Notification("Saved CSV table: "+CSV_getPath(),Color.GREEN)


func _on_zen_table_editor_data_changed(data):
	print(data)
