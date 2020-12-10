extends "res://scripts/FSM/FSM.gd"


func _on_animation_finished(anim_name : String):
	if cur_state != null and state_map[cur_state].has_method("handle_animation_finished"):
		state_map[cur_state].handle_animation_finished(anim_name)
