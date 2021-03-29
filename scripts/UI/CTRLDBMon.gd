extends Control

signal value_changed(val)

# The DB to connect to.
export var db_name : String = ""
# The DB key to send the value to
export var db_val_key : String = ""

var DB = null
var DB_Listener_Keys = []

func _ready():
	if db_name != "" and db_val_key != "":
		MemDB.connect("database_added", self, "_on_db_added")
		if MemDB.has_db(db_name):
			_SetDB(db_name)


func _SetDB(name : String):
	if DB != null:
		return
	if MemDB.has_db(name):
		DB = MemDB.get_db(name)
		DB.connect("value_changed", self, "_on_db_value_changed")


func _add_listener_key(name : String):
	if DB_Listener_Keys.find(name) < 0:
		DB_Listener_Keys.append(name)
		

# NOTE: This should be overwritten by children
func _db_value_changed(val):
	pass

func _db_listener_changed(name : String, val):
	pass

func _set_value(val):
	if DB != null:
		DB.set_value(db_val_key, val)
	emit_signal("value_changed", val)

func _on_db_added(name : String):
	if DB != null:
		return
	if name == db_name:
		_SetDB(name)

func _on_db_value_changed(name : String, val):
	if name == db_val_key:
		_db_value_changed(val)
	elif DB_Listener_Keys.size() > 0:
		var idx = DB_Listener_Keys.find(name)
		if idx >= 0:
			_db_listener_changed(name, val)
