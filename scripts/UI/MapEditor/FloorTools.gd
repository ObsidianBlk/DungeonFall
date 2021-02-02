extends Control

signal active_floor_type(type)

onready var BTN_Breakable = $CTRLs/BTN_Breakable
onready var BTN_Safe = $CTRLs/BTN_Safe
onready var BTN_Ends = $CTRLs/BTN_Ends

func _ready():
	var bg = ButtonGroup.new()
	BTN_Breakable.group = bg
	BTN_Safe.group = bg
	BTN_Ends.group = bg


func _on_floor_btn_toggle(pressed : bool, btn : String):
	print ("Pressed: ", pressed, " | BTN: ", btn)
	if pressed:
		emit_signal("active_floor_type", btn)
