extends "res://scripts/FSM/State.gd"


func handle_input(event):
	if event.is_action_pressed("ui_cancel"):
		host.request_game_pause()
		get_tree().set_input_as_handled()
