extends "res://scripts/UI/SimpleUI.gd"

signal game_resume
signal game_restart
signal game_options
signal game_escape
signal escape_dungeon


onready var btn_resume = $Center/Panel/MC/VBC/Buttons/BTN_Resume

func _on_BTN_Resume_pressed():
	visible = false
	emit_signal("game_resume")


func _on_BTN_Restart_pressed():
	visible = false
	emit_signal("game_restart")


func _on_BTN_Options_pressed():
	visible = false
	emit_signal("game_options")


func _on_BTN_EscDung_pressed():
	visible = false
	emit_signal("escape_dungeon")


func _on_BTN_EscDesk_pressed():
	emit_signal("game_escape")


func _on_change_visible(e : bool, uiname : String = ""):
	if uiname == "" or uiname == name:
		visible = e
		if visible and btn_resume:
			btn_resume.grab_focus()

func _on_visibility_changed():
	if visible and btn_resume:
		btn_resume.grab_focus()
