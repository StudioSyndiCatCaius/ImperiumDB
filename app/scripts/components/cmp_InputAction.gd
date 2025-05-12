extends Node
class_name cmp_InputAction

@export var key: Key
@export var Require_CTRL=false
@export var Require_Alt=false
@export var Require_Shift=false
@export var RequiredVisibleNode: Control

var is_down=false

signal InputBegin
signal InputEnd

func Is_Pressed():
	if Input.is_key_pressed(key):
		if Input.is_key_pressed(KEY_CTRL) or !Require_CTRL:
			if Input.is_key_pressed(KEY_ALT) or !Require_Alt:
				if Input.is_key_pressed(KEY_SHIFT) or !Require_Shift:
					return true
	return false

func _process(delta):
	if RequiredVisibleNode==null or RequiredVisibleNode.visible:
		if is_down:
			if !Is_Pressed():
				is_down=false
				InputEnd.emit()
		else:
			if Is_Pressed():
				is_down=true
				InputBegin.emit()
