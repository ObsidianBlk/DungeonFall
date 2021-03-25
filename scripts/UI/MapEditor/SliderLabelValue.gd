extends Container

signal value_changed(val)

export var Value_Node_Path : NodePath = ""
export var Label_Node_Path : NodePath = ""
export var Label_Prefix : String = ""
export var Label_Postfix : String = ""
export var Value_Decimal_Padding : int = 0

# The DB key to send the value to
export var db_val_key : String = ""
# The DB key to listen for to set the minimum value.
export var db_val_to_min : String = ""
# The DB key to listen for to set the maximum value.
export var db_val_to_max : String = ""


var value_node = null
var label_node = null
var DB = null

func _ready():
	#DB = MemDB.get_db("MapEditor")
	#if DB:
	#	DB.connect("value_change", self, "_on_db_value_change")
	#else:
	#	print("We have NO database")
	MemDB.connect("database_added", self, "_on_db_added")
	if MemDB.has_db("MapEditor"):
		_SetDB("MapEditor")
	
	value_node = get_node(Value_Node_Path)
	if not value_node:
		return
	
	label_node = get_node(Label_Node_Path)
	value_node.connect("value_changed", self, "_on_value_changed")


func _SetDB(name : String):
	if DB != null:
		return
	if MemDB.has_db(name):
		DB = MemDB.get_db(name)
		DB.connect("value_changed", self, "_on_db_value_changed")
	


func _on_value_changed(val : float):
	if label_node:
		var valstr = String(val);
		if Value_Decimal_Padding > 0:
			valstr = valstr.pad_decimals(Value_Decimal_Padding)
		label_node.text = Label_Prefix + valstr + Label_Postfix
	if db_val_key != "" and DB:
		DB.set_value(db_val_key, val)
	emit_signal("value_changed", val)


func _on_db_added(name : String):
	if DB != null:
		return

	if name == "MapEditor":
		_SetDB(name)

func _on_db_value_changed(name : String, val):
	if typeof(val) != TYPE_REAL:
		return
	if not value_node:
		return
	if not (value_node is Range):
		return
	
	if name == db_val_key:
		value_node.value = val
	if name == db_val_to_min:
		if value_node.value < val:
			value_node.value = val
		value_node.min_value = val
	elif name == db_val_to_max:
		if value_node.value > val:
			value_node.value = val
		value_node.max_value = val


