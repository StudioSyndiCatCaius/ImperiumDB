extends PanelContainer

@export var N_lbl_text: Label
@export var N_timer: Timer

func _ready():
	N_lbl_text.visible=false
	G_Log.LogEvent.connect(_onLogEvent)


func _onLogEvent(event,dat):
	if event==0:
		N_lbl_text.visible=true
		N_lbl_text.text=dat._txt
		N_lbl_text.modulate=dat._col
		N_timer.start(0)


func _on_timer_notif_timeout():
	N_lbl_text.visible=false
