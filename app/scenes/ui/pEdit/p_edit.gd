extends PanelContainer
class_name ui_pEdit

var paramConfig={}
var OBJECT={}
@export var paramName=""
@export var paramCategory=""

@export var N__label: Label
@export var N_textEdit: TextEdit
@export var N_int: SpinBox
@export var N_List: OptionButton
@export var N_check: CheckBox

signal OnParamEdit(param: String, value)

func _ready():
	N__label.text=paramName

func Setup(obj: Dictionary):
	OBJECT=obj
	
	if N__label: N__label.text=paramName
	if !OBJECT.has(paramCategory):
		OBJECT[paramCategory]={}
	var _val=Value_Get()
	
	# TEXT
	if N_textEdit:
		N_textEdit.text=_val
		N_textEdit.text_changed.connect(_on_textChange)
	
	# TABLE
	if N_List:
		N_List.clear()
		var _valIndex=-1
		var _tbl=paramConfig.get('table')
		var list=[]
		
		if _tbl:
			var _glob=Z.L.pull_variant("_D")
			var ltbl=_glob.get(_tbl,{})
			if ltbl is Dictionary:
				var _dtbl=ltbl
				var _keys=_dtbl.keys()
				list=_keys
				list.sort()
			list.append_array(G.TABLE_GetItemList(_tbl))
		#from csv
		if _tbl:
			for i in list:
				var _idx=list.find(i)
				var _imgPath=G.PATH_GetRoot()+"/image/ico_"+_tbl+"_"+i+".png"
				var _ico=G_Load.Texture(_imgPath)
				var _tblData=G.TABLE_GetItem(_tbl,i)
				
				N_List.add_item(i)
				N_List.set_item_tooltip(_idx,_tblData.get("description",""))
				N_List.set_item_icon(_idx,_ico)
				
				if i == _val:
					_valIndex=list.find(i)
		#from files
		elif paramConfig.has('filePath'):
			var _filsPth=paramConfig.get('filePath')
			_filsPth=G_File.PathCorrect(_filsPth)
			var _files=G_File.LIST_AllInDir(_filsPth)
			for i in _files:
				if i.get_extension()==paramConfig.get('fileType'):
					var key=i.get_file().get_basename()
					var index=N_List.item_count
					
					N_List.add_item(key)
					if key == _val:
						_valIndex=index
					
					if paramConfig.get("GetIcon")!=null:
						var ico_path=paramConfig.GetIcon.invoke(key)
						if ico_path is String:
							var newtxt: Texture2D=G_Load.Texture(ico_path)
							N_List.set_item_icon(index,newtxt)
		
		N_List.select(_valIndex)
	
	# NUMBER
	if N_int:
		var _p=OBJECT[paramCategory]
		N_int.step=paramConfig.get('step',0.1)
		var _def=paramConfig.get('default',0.0)
		N_int.value=_p.get(paramName,_def) as float
		N_int.value_changed.connect(_on_spin_box_value_changed)
	
	if N_check:
		var _v=OBJECT[paramCategory].get(paramName,false)
		if _v is bool:
			N_check.button_pressed=_v
		else:
			N_check.button_pressed=false
		#N_check.toggled.connect(_on_check_button_toggled)

func Value_Get() -> Variant:
	if paramCategory!="":
		return OBJECT[paramCategory].get(paramName,"")
	else:
		return OBJECT.get(paramName,"")

func Value_SET(val):
	if paramCategory!="":
		OBJECT[paramCategory][paramName]=val
	else:
		OBJECT[paramName]=val
	OnParamEdit.emit(paramName,val)

func Value_CLEAR():
	if N_textEdit:
		N_textEdit.text=""

func _on_textChange():
	Value_SET(N_textEdit.text)

func _on_spin_box_value_changed(value):
	Value_SET(value)

func _on_edit_list_item_selected(index):
	Value_SET(N_List.get_item_text(index))


func _on_check_box_toggled(toggled_on):
	Value_SET(toggled_on)


func _on_btn_clear_pressed():
	N_List.select(-1)
	Value_SET('')
