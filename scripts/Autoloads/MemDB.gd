extends Node


signal database_value_changed(group, name, val)
signal database_added(group)

var BDO = preload("res://scripts/Systems/DB.gd")
var _DB = {}


func _change_value(group: String, name : String, v):
	if group in _DB:
		# TODO: Name sure <name> is not a string of spaces or ""
		_DB[group][name] = v
		emit_signal("database_value_changed", group, name, v)

func has_db(name : String):
	return (name in _DB)

func add_db(name : String):
	# TODO: Name sure <name> is not a string of spaces or ""
	if not (name in _DB):
		_DB[name] = {}
		emit_signal("database_added", name)
	else:
		print("WARNING: Cannot add new memory group '", name, "'. Group already exists.")

func get_db(name : String):
	if not name in _DB:
		return null
	var db = BDO.new()
	db.init(name)
	return db

