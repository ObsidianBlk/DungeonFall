extends "res://scripts/UI/CTRLDBMon.gd"

var value_node = null

func _ready():
	value_node = get_node("Value")
	if not (value_node is LineEdit):
		value_node = null
		return
	value_node.connect("text_changed", self, "_on_value_changed")

func _db_value_changed(val):
	if typeof(val) != TYPE_STRING:
		return
	if not value_node:
		return
	
	if value_node.text != val:
		value_node.text = val

func _on_value_changed(val : String):
	_set_value(val)
