extends res__ImpAsset
class_name res_FlowNode_Inst


@export var position: Vector2


func META_Save(dic: Dictionary):
	dic['position']=G_Conv.Vec2_to_Dic(position)

func META_Load(dic: Dictionary):
	pass
	position=G_Conv.Dic_to_Vec2(dic.get('position',{}))
