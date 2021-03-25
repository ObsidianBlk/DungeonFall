extends Container

signal value_changed(val)

export var Value_Node_Path : NodePath = ""

# The DB key to send the value to
export var db_val_key : String = ""

var DB = null
var value_node = null

func _ready():
	MemDB.connect("database_added", self, "_on_db_added")
	if MemDB.has_db("MapEditor"):
		_SetDB("MapEditor")
	
	value_node = get_node(Value_Node_Path)
	if not (value_node is LineEdit):
		value_node = null
		return
	value_node.connect("text_changed", self, "_on_value_changed")

func _SetDB(name : String):
	if DB != null:
		return
	if MemDB.has_db(name):
		print("Obtaining DB: ", name)
		DB = MemDB.get_db(name)
		DB.connect("value_changed", self, "_on_db_value_changed")


func _on_db_added(name : String):
	if DB != null:
		return

	if name == "MapEditor":
		_SetDB(name)

func _on_db_value_changed(name : String, val):
	if typeof(val) != TYPE_STRING:
		return
	if not value_node:
		return
	
	if name == db_val_key and value_node.text != val:
		value_node.text = val


func _on_value_changed(val : String):
	if db_val_key != "":
		DB.set_value(db_val_key, val)
	emit_signal("value_changed", val)
