extends Control
class_name ui_pEdit

var paramConfig={}
var paramData={}
var paramName=""

@export var N__label: Label
@export var N_textEdit: TextEdit
@export var N_int: SpinBox
@export var N_List: OptionButton
@export var N_check: CheckBox

signal OnParamEdit(param: String, value)

func Setup(obj: Dictionary, template: LuaTable):
	paramData=obj
	
	if N__label: N__label.text=paramName
	var _val=paramData['params'].get(paramName,"")
	
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
			list=G_Project.TABLE_GetItemList(_tbl)
		#from csv
		if _tbl:
			for i in list:
				var _idx=list.find(i)
				var _imgPath=G_Project.PATH_GetRoot()+"/image/ico_"+_tbl+"_"+i+".png"
				var _ico=G_File.LOAD_Texture(_imgPath)
				var _tblData=G_Project.TABLE_GetItem(_tbl,i)
				
				N_List.add_item(i)
				N_List.set_item_tooltip(_idx,_tblData.get("description",""))
				N_List.set_item_icon(_idx,_ico)
				
				if i == _val:
					_valIndex=list.find(i)
		#from files
		elif paramConfig.has('filePath'):
			for i in G_File.LIST_AllInDir(paramConfig.get('filePath')):
				if i.get_extension()==paramConfig.get('fileType'):
					var key=i.get_file().get_basename()
					var index=N_List.item_count
					
					N_List.add_item(key)
					if key == _val:
						_valIndex=index
					
					if paramConfig.get("GetIcon")!=null:
						var ico_path=paramConfig.GetIcon.invoke(key)
						if ico_path is String:
							var newtxt: Texture2D=G_File.LOAD_Texture(ico_path)
							N_List.set_item_icon(index,newtxt)
		
		N_List.select(_valIndex)
	
	# NUMBER
	if N_int:
		var _p=paramData['params']
		N_int.step=paramConfig.get('step',0.1)
		
		N_int.value=_p.get(paramName,0) as float
		N_int.value_changed.connect(_on_spin_box_value_changed)
	
	if N_check:
		var _v=paramData['params'].get(paramName,false)
		if _v is bool:
			N_check.button_pressed=_v
		else:
			N_check.button_pressed=false
		#N_check.toggled.connect(_on_check_button_toggled)

func SET(val):
	paramData["params"][paramName]=val
	OnParamEdit.emit(paramName,val)

func _on_textChange():
	SET(N_textEdit.text)

func _on_spin_box_value_changed(value):
	SET(value)

func _on_edit_list_item_selected(index):
	SET(N_List.get_item_text(index))


func _on_check_box_toggled(toggled_on):
	SET(toggled_on)


func _on_btn_clear_pressed():
	N_List.select(-1)
	SET('')
