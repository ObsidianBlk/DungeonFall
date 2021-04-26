extends "res://scripts/UI/CTRLDBMon.gd"


export var enable_toggle : bool = false
export var enable_pressed : bool = false
export var enable_down : bool = false

onready var btn_node = get_node("BTN")

func _ready():
	if enable_toggle:
		btn_node.connect("toggled", self, "_on_toggled")
	if enable_pressed:
		btn_node.connect("pressed", self, "_on_pressed")
	if enable_down:
		btn_node.connect("button_down", self, "_on_button_down")

func _on_toggled(enabled : bool):
	pass

func _on_pressed():
	pass

func _on_button_down():
	pass
