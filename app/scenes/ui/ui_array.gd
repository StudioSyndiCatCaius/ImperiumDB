extends Control

@export var N_ItemList: ItemList
@export var N_SpinBox: SpinBox

var entries=[
	{},
	{},
]

func _ready():
	N_SpinBox.value=entries.size()
	LIST_Rebuild()

func LIST_Rebuild():
	N_ItemList.clear()
	for i in entries.size():
		N_ItemList.add_item("")
		ITEM_SetText(i,"foo")

func ITEM_SetText(index: int,text: String):
	N_ItemList.set_item_text(index,"["+str(index)+"] "+text)

func _on_n_spin_box_value_changed(value):
	print(value)
	entries.resize(value)
	LIST_Rebuild()
