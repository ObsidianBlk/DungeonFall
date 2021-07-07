extends PopupPanel

signal confirm
signal cancel

export var text : String = "" setget _set_label_text
export var confirm_only : bool = false setget _set_confirm_only

var _text = ""
onready var label = $MarginContainer/VBoxContainer/Label
onready var btn_cancel_node = $MarginContainer/VBoxContainer/HBoxContainer/BTN_Cancel
onready var margin_node = $MarginContainer/VBoxContainer/HBoxContainer/MarginContainer


func _set_label_text(text : String):
	if label:
		label.text = text
	else:
		_text = text

func _set_confirm_only(e : bool):
	confirm_only = e
	if btn_cancel_node and margin_node:
		btn_cancel_node.visible = not e
		margin_node.visible = not e

func _ready():
	if _text != "":
		label.text = _text
		_text = ""
	if confirm_only:
		btn_cancel_node.visible = false
		margin_node.visible = false


func _on_confirm_pressed():
	emit_signal("confirm")


func _on_cancel_pressed():
	emit_signal("cancel")
