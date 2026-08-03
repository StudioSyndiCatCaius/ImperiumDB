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

# Custom filterable dropdown (used by pEdit_table instead of N_List)
@export var N_btn_dropdown: Button
@export var N_dropdown_popup: PopupPanel
@export var N_popup_filter: TextEdit
@export var N_popup_items: ItemList
@export var N_lineedit_manual: LineEdit
@export var N_btn_edit_toggle: Button

var _table_items: Array = []
var _manual_mode := false

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
	if N_btn_dropdown or N_List:
		_table_items = []
		var _tbl = paramConfig.get('table')
		var list: Array = []

		if _tbl:
			var _glob = Z.L.pull_variant("_D")
			var ltbl = _glob.get(_tbl, {})
			if ltbl is Dictionary:
				list = ltbl.keys()
				list.sort()
			list.append_array(G.TABLE_GetItemList(_tbl))

		if _tbl:
			for i in list:
				var _imgPath = G.PATH_GetRoot() + "/image/ico_" + _tbl + "_" + i + ".png"
				var _ico: Texture2D = G_Load.Texture(_imgPath)
				var _tblData = G.TABLE_GetItem(_tbl, i)
				_table_items.append({text = i, icon = _ico, tooltip = _tblData.get("description", "")})
		elif paramConfig.has('filePath'):
			var _filsPth: String = G_File.PathCorrect(paramConfig.get('filePath'))
			var _files = G_File.LIST_AllInDir(_filsPth)
			for i in _files:
				if i.get_extension() == paramConfig.get('fileType'):
					var key: String = i.get_file().get_basename()
					var _ico: Texture2D = null
					if paramConfig.get("GetIcon") != null:
						var ico_path = paramConfig.GetIcon.call(key)
						if ico_path is String:
							_ico = G_Load.Texture(ico_path)
					_table_items.append({text = key, icon = _ico, tooltip = ""})

		_manual_mode = false
		if N_lineedit_manual:
			N_lineedit_manual.visible = false
		if N_btn_edit_toggle:
			N_btn_edit_toggle.text = "✏"
		if N_btn_dropdown:
			N_btn_dropdown.visible = true
			var _match = _table_items.filter(func(it): return it.text == _val)
			_set_dropdown_display(_val, _match[0].icon if _match.size() > 0 else null)

		if N_List:
			N_List.clear()
			var _valIndex := -1
			for item in _table_items:
				var idx := N_List.item_count
				N_List.add_item(item.text, item.icon)
				N_List.set_item_tooltip(idx, item.tooltip)
				if item.text == _val:
					_valIndex = idx
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
	if N_List:
		N_List.select(-1)
	if N_btn_dropdown:
		_set_dropdown_display("", null)
	Value_SET('')

func _on_btn_dropdown_pressed():
	if not N_dropdown_popup:
		return
	if N_popup_filter:
		N_popup_filter.text = ""
	_rebuild_table_popup()
	N_dropdown_popup.position = DisplayServer.mouse_get_position()
	N_dropdown_popup.popup()
	if N_popup_filter:
		N_popup_filter.grab_focus()

func _rebuild_table_popup():
	if not N_popup_items:
		return
	N_popup_items.clear()
	var filter := N_popup_filter.text.to_lower() if N_popup_filter else ""
	for item in _table_items:
		if filter.is_empty() or item.text.to_lower().contains(filter):
			var idx := N_popup_items.add_item(item.text, item.icon)
			N_popup_items.set_item_tooltip(idx, item.tooltip)

func _on_popup_filter_text_changed():
	_rebuild_table_popup()

func _on_popup_filter_gui_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	var count := N_popup_items.item_count if N_popup_items else 0
	if count == 0:
		return
	if event.keycode == KEY_DOWN:
		N_popup_items.grab_focus()
		N_popup_items.select(0)
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_UP:
		N_popup_items.grab_focus()
		N_popup_items.select(count - 1)
		get_viewport().set_input_as_handled()

func _set_dropdown_display(text: String, icon: Texture2D) -> void:
	if not N_btn_dropdown:
		return
	if text != "":
		N_btn_dropdown.text = text
		N_btn_dropdown.icon = icon
		N_btn_dropdown.remove_theme_color_override("font_color")
	else:
		N_btn_dropdown.text = "(none)"
		N_btn_dropdown.icon = null
		N_btn_dropdown.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))

func _on_popup_items_item_selected(index: int):
	var text := N_popup_items.get_item_text(index)
	var icon := N_popup_items.get_item_icon(index)
	_set_dropdown_display(text, icon)
	Value_SET(text)
	if N_dropdown_popup:
		N_dropdown_popup.hide()

func _set_manual_mode(enabled: bool) -> void:
	_manual_mode = enabled
	if N_btn_dropdown:
		N_btn_dropdown.visible = not enabled
	if N_lineedit_manual:
		N_lineedit_manual.visible = enabled
		if enabled:
			N_lineedit_manual.text = Value_Get()
			N_lineedit_manual.grab_focus()
			N_lineedit_manual.select_all()
	if N_btn_edit_toggle:
		N_btn_edit_toggle.text = "✓" if enabled else "✏"

func _commit_manual_input() -> void:
	if not _manual_mode:
		return
	var text := N_lineedit_manual.text if N_lineedit_manual else ""
	Value_SET(text)
	var matched := _table_items.filter(func(it): return it.text == text)
	_set_dropdown_display(text, matched[0].icon if matched.size() > 0 else null)
	_set_manual_mode(false)

func _on_btn_edit_toggle_pressed() -> void:
	if _manual_mode:
		_commit_manual_input()
	else:
		_set_manual_mode(true)

func _on_lineedit_manual_submitted(_text: String) -> void:
	_commit_manual_input()

func _on_lineedit_manual_focus_exited() -> void:
	_commit_manual_input()
