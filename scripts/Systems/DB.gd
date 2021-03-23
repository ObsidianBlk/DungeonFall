extends Node

signal value_changed(name, val)

var _SrcGroup = ""

func init(group : String):
	if _SrcGroup == "" and group != "":
		_SrcGroup = group
		MemDB.connect("database_value_changed", self, "_on_db_value_changed")

func get_value(name : String):
	if name in MemDB._DB[_SrcGroup]:
		return MemDB._DB[_SrcGroup][name]
	return null

func set_value(name : String, v):
	MemDB._change_value(_SrcGroup, name, v)

func has_value(name : String):
	return (name in MemDB._DB[_SrcGroup])

func get_value_type(name : String):
	return typeof(get_value(name))

func group_name():
	return _SrcGroup;


func _on_db_value_changed(group : String, name: String, v):
	if group == _SrcGroup:
		emit_signal("value_changed", name, v)
