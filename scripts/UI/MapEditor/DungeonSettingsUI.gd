extends Control

const BREAK_LABEL_POSTFIX = " second(s)"

# The DB to connect to.
export var db_name : String = ""

var DB = null
var float_regex = null
var CollapseTimerText = ""


onready var DungeonName_node = $"Margins/GridContainer/Left Column/DungeonName/Value"
onready var EngineerName_node = $"Margins/GridContainer/Left Column/EngineerName/Value"

onready var BreakTime_node = $"Margins/GridContainer/Right Column/BreakTime/Slider/Value"
onready var BreakTimeLabel_node = $"Margins/GridContainer/Right Column/BreakTime/Slider/Label"
onready var BreakVariance_node = $"Margins/GridContainer/Right Column/BreakVariance/Slider/Value"
onready var BreakVarianceLabel_node = $"Margins/GridContainer/Right Column/BreakVariance/Slider/Label"

onready var AutoTimer_node = $"Margins/GridContainer/Center Column/DungeonTimers/AutoTimer/Check"
onready var CollapseTimer_node = $"Margins/GridContainer/Center Column/DungeonTimers/CollapseTimer/Value"

onready var GoldAmount_node = $"Margins/GridContainer/Center Column/GoldRandomizer/GoldAmount/Value"
onready var GoldSeed_node = $"Margins/GridContainer/Center Column/GoldRandomizer/GoldSeed/Value"


func _ready():
	if db_name != "":
		MemDB.connect("database_added", self, "_on_db_added")
		if MemDB.has_db(db_name):
			_SetDB(db_name)
	float_regex = RegEx.new()
	float_regex.compile("([0-9]*[.])?[0-9]+")

func _update_break_variance_limits(val):
	if BreakVariance_node.value > val:
		BreakVariance_node.value = val
		BreakVarianceLabel_node.text = String(val).pad_decimals(1) + BREAK_LABEL_POSTFIX
		_set_value("tile_break_variance", val)
	BreakVariance_node.max_value = val

func _update_placeable_tiles(count):
	count = max(1, count)
	if GoldAmount_node.value > count:
		GoldAmount_node.value = count
		_set_value("gold_amount", count)
	GoldAmount_node.max_value = count

func _is_valid_float(val : String):
	if val != "." and not val.ends_with(".") and not val.is_valid_float():
		return false
	return true

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
		"timer_autostart":
			if typeof(val) == TYPE_BOOL:
				AutoTimer_node.pressed = val
		"collapse_timer":
			if typeof(val) == TYPE_REAL:
				CollapseTimerText = String(val)
				if CollapseTimer_node.text != CollapseTimerText:
					CollapseTimer_node.text = CollapseTimerText
		"gold_amount":
			if typeof(val) == TYPE_INT:
				GoldAmount_node.value = val
		"gold_seed":
			if typeof(val) == TYPE_STRING or typeof(val) == TYPE_INT:
				var text = String(val)
				if GoldSeed_node.text != text:
					GoldSeed_node.text = text

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
	_set_value("timer_autostart", button_pressed)

func _on_CollapseTimer_text_changed(new_text):
	if new_text != "" and not _is_valid_float(new_text):
		CollapseTimer_node.text = CollapseTimerText
	else:
		CollapseTimerText = new_text

func _on_CollapseTimer_focus_exited():
	if CollapseTimerText != ".":
		if CollapseTimerText.ends_with("."):
			CollapseTimerText += "0"
		_set_value("collapse_timer", float(CollapseTimerText))
	else:
		var val = DB.get_value("collapse_timer")
		if val != null:
			CollapseTimerText = String(val)
		else:
			CollapseTimerText = ""
		CollapseTimer_node.text = CollapseTimerText


func _on_GoldSeed_text_changed(new_text):
	_set_value("gold_seed", new_text)

func _on_GoldAmount_changed(value):
	_set_value("gold_amount", value)
