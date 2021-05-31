extends Control

signal new_dungeon_pressed
signal load_dungeon_pressed
signal save_dungeon_pressed
signal dungeon_settings_pressed

signal playerstart_selected
signal floortool_selected(id)

var _curtool = "B"

onready var btn_breakable = $HBC/DrawTools/BTN_FloorBreakable
onready var btn_safe = $HBC/DrawTools/BTN_FloorSafe
onready var btn_exit = $HBC/DrawTools/BTN_FloorExit
onready var btn_ps = $HBC/DrawTools/BTN_PlayerStart

func _ready():
	var btngrp = ButtonGroup.new()
	btn_breakable.group = btngrp
	btn_safe.group = btngrp
	btn_exit.group = btngrp
	btn_ps.group = btngrp

func get_current_tool():
	return _curtool

func _unselect_cur_drawtool_btn():
	match _curtool:
		"B":
			btn_breakable.pressed = false
		"S":
			btn_safe.pressed = false
		"E":
			btn_exit.pressed = false
		"P":
			btn_ps.pressed = false


func _on_BTN_NewDngn_pressed():
	emit_signal("new_dungeon_pressed")


func _on_BTN_LoadDngn_pressed():
	emit_signal("load_dungeon_pressed")


func _on_BTN_SaveDngn_pressed():
	emit_signal("save_dungeon_pressed")

func _on_DrawTool_selected(pressed : bool, btn : String):
	if pressed:
		if btn == "B" or btn == "S" or btn == "E":
			_curtool = btn
			emit_signal("floortool_selected", btn)
		else:
			print("WARNING: Unknown Dungeon Editor Draw Tool '", btn, "'.")


func _on_PlayerStart_selected(pressed : bool):
	if pressed and _curtool != "P":
		_curtool = "P"
		emit_signal("playerstart_selected")


func _on_BTN_DngnSettings_pressed():
	emit_signal("dungeon_settings_pressed")
