extends "res://scripts/UI/SimpleUI.gd"

signal dungeon_run
signal dungeon_editor
signal game_options
signal game_escape

export var hide_on_operation : bool = false


onready var instr_node : MarginContainer = $Instructions
onready var btn_run = $Menu/Panel/VBC/Buttons/BTN_Run


func _on_change_visible(e : bool, uiname : String = ""):
	print("Menu says hello")
	if uiname == "" or uiname == name:
		visible = e
		if visible and btn_run:
			btn_run.grab_focus()

func _on_BTN_Run_pressed():
	if hide_on_operation:
		visible = false
	emit_signal("dungeon_run")


func _on_BTN_DungEditor_pressed():
	if hide_on_operation:
		visible = false
	emit_signal("dungeon_editor")


func _on_BTN_Escape_pressed():
	if hide_on_operation:
		visible = false
	emit_signal("game_escape")


func _on_BTN_Options_pressed():
	emit_signal("game_options")


func _on_BTN_Instruction_toggled(button_pressed):
	pass # Replace with function body.
