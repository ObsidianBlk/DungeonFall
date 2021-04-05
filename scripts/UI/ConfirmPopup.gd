extends PopupPanel

signal confirm
signal cancel

export var text : String = "" setget _set_label_text

var _text = ""
onready var label = $MarginContainer/VBoxContainer/Label


func _set_label_text(text):
	if label:
		label.text = text
	else:
		_text = text

func _ready():
	if _text != "":
		label.text = _text
		_text = ""


func _on_confirm_pressed():
	emit_signal("confirm")


func _on_cancel_pressed():
	emit_signal("cancel")
