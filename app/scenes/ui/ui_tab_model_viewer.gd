extends Control


@export var N_3D_Camera: Camera3D
@export var N_SubsceneRoot: Node3D

@onready var N_List_anim=$HBoxContainer/PanelContainer/VBoxContainer/PanelContainer/ItemList
@onready var dialog_file=$FileDialog

var N_SubsceneObject: Node3D
var anim_player: AnimationPlayer

func _on_button_pressed():
	if !dialog_file.visible:
		dialog_file.popup()


func _on_file_dialog_file_selected(path):
	print("path: "+path)
	
	if N_SubsceneObject:
		N_SubsceneObject.queue_free()
	N_SubsceneObject=G_Load.GLTF(path)
	anim_player = N_SubsceneObject.get_node("AnimationPlayer")
	N_List_anim.clear()
	if anim_player:
		for i in anim_player.get_animation_list():
			N_List_anim.add_item(i)
	N_SubsceneRoot.add_child(N_SubsceneObject)

func _on_h_slider_value_changed(value):
	N_3D_Camera.fov=value

func _on_item_list_item_activated(index):
	var anim_name:String=N_List_anim.get_item_text(index)
	if anim_player:
		anim_player.get_animation(anim_name).loop_mode=Animation.LOOP_LINEAR
		anim_player.play(anim_name)
