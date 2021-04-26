extends Control


const BREAK_LABEL_POSTFIX = " second(s)"

# The DB to connect to.
export var db_name : String = ""

var DB = null


onready var DungeonName_node = $"Margins/GridContainer/Left Column/DungeonName/Value"
onready var EngineerName_node = $"Margins/GridContainer/Left Column/EngineerName/Value"

onready var BreakTime_node = $"Margins/GridContainer/Right Column/BreakTime/Slider/Value"
onready var BreakTimeLabel_node = $"Margins/GridContainer/Right Column/BreakTime/Slider/Label"
onready var BreakVariance_node = $"Margins/GridContainer/Right Column/BreakVariance/Slider/Value"
onready var BreakVarianceLabel_node = $"Margins/GridContainer/Right Column/BreakVariance/Slider/Label"

onready var AutoTimer_node = $"Margins/GridContainer/Center Column/AutoTimer/Check"

func _ready():
	if db_name != "":
		MemDB.connect("database_added", self, "_on_db_added")
		if MemDB.has_db(db_name):
			_SetDB(db_name)

func _update_break_variance_limits(val):
	if BreakVariance_node.value > val:
		BreakVariance_node.value = val
		BreakVarianceLabel_node.text = String(val).pad_decimals(1) + BREAK_LABEL_POSTFIX
		_set_value("tile_break_variance", val)
	BreakVariance_node.max_value = val

func _SetDB(name : String):
	if DB != null:
		return
	if MemDB.has_db(name):
		DB = MemDB.get_db(name)
		DB.connect("value_changed", self, "_on_db_value_changed")

func _set_value(key, val):
	if DB != null:
		DB.set_value(key, val)


func _on_db_added(name : String):
	if DB != null:
		return
	if name == db_name:
		_SetDB(name)

func _on_db_value_changed(name : String, val):
	match(name):
		"dungeon_name":
			if typeof(val) == TYPE_STRING and DungeonName_node.text != val:
				DungeonName_node.text = val
		"engineer_name":
			if typeof(val) == TYPE_STRING and EngineerName_node.text != val:
				EngineerName_node.text = val
		"tile_break_time":
			if typeof(val) == TYPE_REAL:
				_update_break_variance_limits(val)
				BreakTime_node.value = val
				BreakTimeLabel_node.text = String(val).pad_decimals(1) + BREAK_LABEL_POSTFIX
		"tile_break_variance":
			if typeof(val) == TYPE_REAL:
				BreakVariance_node.value = val
				BreakVarianceLabel_node.text = String(val).pad_decimals(1) + BREAK_LABEL_POSTFIX
		"auto_start_timer":
			if typeof(val) == TYPE_BOOL:
				AutoTimer_node.pressed = val

func _on_DungeonName_text_changed(new_text):
	_set_value("dungeon_name", new_text)

func _on_Engineername_text_changed(new_text):
	_set_value("engineer_name", new_text)

func _on_BreakTime_value_changed(value):
	BreakTimeLabel_node.text = String(value).pad_decimals(1) + BREAK_LABEL_POSTFIX
	_update_break_variance_limits(value)
	_set_value("tile_break_time", value)

func _on_BreakVariance_value_changed(value):
	BreakVarianceLabel_node.text = String(value).pad_decimals(1) + BREAK_LABEL_POSTFIX
	_set_value("tile_break_variance", value)

func _on_AutoTimer_toggled(button_pressed):
	_set_value("auto_start_timer", button_pressed)

