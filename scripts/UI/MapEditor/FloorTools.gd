extends Control

signal active_floor_type(type)

onready var BTN_Breakable = $CTRLs/BTN_Breakable
onready var BTN_Safe = $CTRLs/BTN_Safe
onready var BTN_Ends = $CTRLs/BTN_Ends
onready var BTN_PS = $CTRLs/BTN_Player_Start

func _ready():
	var bg = ButtonGroup.new()
	BTN_Breakable.group = bg
	BTN_Safe.group = bg
	BTN_Ends.group = bg
	BTN_PS.group = bg


func _on_floor_btn_toggle(pressed : bool, btn : String):
	if pressed:
		emit_signal("active_floor_type", btn)
