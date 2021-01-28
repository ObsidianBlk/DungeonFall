extends Control


onready var BTN_Breakable = $CTRLs/BTN_Breakable
onready var BTN_Safe = $CTRLs/BTN_Safe
onready var BTN_Ends = $CTRLs/BTN_Ends

var active_btn = "B"

func _ready():
	var bg = ButtonGroup.new()
	BTN_Breakable.group = bg
	BTN_Safe.group = bg
	BTN_Ends.group = bg


func _on_floor_btn_toggle(pressed : bool, btn : String):
	print ("Pressed: ", pressed, " | BTN: ", btn)
	#if btn != active_btn:
	#	match(active_btn):
	#		"B":
	#			BTN_Breakable.pressed = false
	#		"S":
	#			BTN_Safe.pressed = false
	#		"E":
	#			BTN_Ends.pressed = false
	#	active_btn = btn
	#elif not pressed:
	#	match(active_btn):
	#		"B":
	#			BTN_Breakable.pressed = true
	#		"S":
	#			BTN_Safe.pressed = true
	#		"E":
	#			BTN_Ends.pressed = true
