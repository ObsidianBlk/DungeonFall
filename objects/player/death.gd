extends "res://scripts/FSM/State.gd"

var check_for_revive = false


func enter(host : Node):
	.enter(host)
	self.host.set_anim_param("parameters/state/current", 2)

func resume(host : Node = null):
	.resume(host)
	# TODO: Resume animation

func exit():
	# Handle exit, then call the base method
	.exit()

func pause():
	# TODO: Pause animation
	.pause()

func handle_physics(delta):
	if check_for_revive and host.alive:
		check_for_revive = false
		emit_signal("finished", "idle")
		return # Might be unneeded, but incase I need to add more, I don't want to forget to put this in.

func handle_animation_finished(anim_name : String):
	if not host.alive:
		return
	
	if anim_name == "\"death_fall\"":
		host.die()
		check_for_revive = true
