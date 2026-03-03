extends PanelContainer
class_name ui_FlowPin

var NODE_DATA={}
var NODE_TEMPLATE={}
var SECTION_DATA={}

var pin_in: Dictionary
var pin_out: Dictionary
var pin_index: int = 0

@export var N_text: RichTextLabel
@export var N_lbl_title: Label
@export var N_lbl_in: Label
@export var N_lbl_out: Label
@export var N_icon: TextureRect

func _ready():
	N_icon.visible=false
	if pin_in:
		N_lbl_in.text=pin_in.get('name','')
	if pin_out:
		N_lbl_out.text=pin_out.get('name','')


func getSectionCall(call) -> LuaFunction:
	if SECTION_DATA is LuaTable:
		SECTION_DATA=SECTION_DATA.to_dictionary()

	if SECTION_DATA.has(call):
		return SECTION_DATA[call]
	if NODE_TEMPLATE.has(call):
		return NODE_TEMPLATE[call]
	return null

func getSectionParam_string(param: String) -> String:
	
	var i: LuaFunction = getSectionCall(param)
	if i:
		var result=i.invoke(NODE_DATA,pin_index)
		if result is String:
			return result
	return ""

func getSectionParam_texture(param: String) -> Texture2D:
	
	var i = getSectionCall(param)
	if i:
		var result=i.invoke(NODE_DATA,pin_index)
		if result is String:
			return G_File.LOAD_Texture(result)
	return null


func _refresh():
	
	N_lbl_title.text=SECTION_DATA.get('title',"")
	N_lbl_title.visible=!N_lbl_title.text.is_empty()

	var txt=getSectionParam_string("GetDescription")

	
	N_text.text=txt
	var pList=SECTION_DATA.get('gParam',{})
	if pList is LuaTable:
		pList=pList.to_dictionary()
	
	var txt_col=G_Lua.CONV(SECTION_DATA.get('text_color',{r=1,g=1,b=1,a=1}))
	N_text.modulate.r=txt_col.r
	N_text.modulate.g=txt_col.g
	N_text.modulate.b=txt_col.b
	N_text.modulate.a=txt_col.a

	
	size_flags_stretch_ratio=SECTION_DATA.get('text_ratio',1)
	
	var _texture=getSectionParam_texture("GetIcon")
	if _texture:
		N_icon.texture=_texture
		N_icon.visible=true
	else:
		N_icon.visible=false
	


func set_icon(txt: Texture2D,size=50):
	if txt:
		N_icon.visible=true
		N_icon.texture=txt
		N_icon.custom_minimum_size.y=size
	else:
		N_icon.visible=false
