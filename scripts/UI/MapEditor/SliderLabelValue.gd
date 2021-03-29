extends "res://scripts/UI/CTRLDBMon.gd"

export var Label_Prefix : String = ""
export var Label_Postfix : String = ""
export var Value_Decimal_Padding : int = 0

# The DB key to listen for to set the minimum value.
export var db_val_to_min : String = ""
# The DB key to listen for to set the maximum value.
export var db_val_to_max : String = ""


var value_node = null
var label_node = null

func _ready():
	if db_val_to_min != "":
		_add_listener_key(db_val_to_min)
	if db_val_to_max != "":
		_add_listener_key(db_val_to_max)
		
	value_node = get_node("Value")
	if not value_node:
		return
	
	label_node = get_node("Label")
	value_node.connect("value_changed", self, "_on_value_changed")


func _on_value_changed(val : float):
	if label_node:
		var valstr = String(val);
		if Value_Decimal_Padding > 0:
			valstr = valstr.pad_decimals(Value_Decimal_Padding)
		label_node.text = Label_Prefix + valstr + Label_Postfix
	_set_value(val)

func _db_value_changed(val):
	if typeof(val) != TYPE_REAL:
		return
	if not value_node:
		return
	if not (value_node is Range):
		return
	value_node.value = val

func _db_listener_changed(name : String, val):
	print("Obtained Listener Key - ", name, " : ", val)
	if typeof(val) != TYPE_REAL:
		return
	if not value_node:
		return
	if not (value_node is Range):
		return
	
	match(name):
		db_val_to_min:
			if value_node.value < val:
				value_node.value = val
			value_node.min_value = val
		db_val_to_max:
			if value_node.value > val:
				value_node.value = val
			value_node.max_value = val


