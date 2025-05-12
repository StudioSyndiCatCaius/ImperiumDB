extends res__ImpAsset
class_name res_FlowNode_Inst


@export var position: Vector2
@export var key=""
@export var size: Vector2

func META_Save(dic: Dictionary):
	dic['key']=key
	dic['position']=G_Conv.Vec2_to_Dic(position)
	dic['size']=G_Conv.Vec2_to_Dic(size)

func META_Load(dic: Dictionary):
	key=dic.get('key',"")
	position=G_Conv.Dic_to_Vec2(dic.get('position',{}))
	size=G_Conv.Dic_to_Vec2(dic.get('size',{}))

func ImportCSV(data):
	for i in template.CsvImportFields:
		var val=data.get(i,"")
		if val!="":
			params[i]=data.get(i,"")
