extends "res://objects/player/states/move.gd"


func enter(host : Node):
	.enter(host)
	if self.host.jump_time >= 0.0:
		self.host.set_anim_param("parameters/air/current", 0)
	else:
		self.host.set_anim_param("parameters/air/current", 2)
	self.host.set_anim_param("parameters/state/current", 1)

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
	var airstate = host.get_anim_param("parameters/air/current")
	if airstate == 3:
		return

	host.update_inair(delta)
	if not host.inair:
		if host.is_over_pit():
			emit_signal("finished", "death")
			return
		host.set_anim_param("parameters/air/current", 3)
	else:
		move(delta)
		if host.jump_time >= 0.0: # Jumping
			var d = 1.0 - (host.jump_time / host.jump_height_time)
			#print("Up Height Delta: ", d)
			host.set_sprite_jump_scale(d)
		else: # Falling
			if airstate != 2:
				host.set_anim_param("parameters/air/current", 2)
			var d = 1.0 - (abs(host.jump_time) / host.jump_height_time)
			#print("Down Height Delta: ", d)
			host.set_sprite_jump_scale(d)

func handle_animation_finished(anim_name : String):
	var airstate = host.get_anim_param("parameters/air/current")
	if airstate == 0 and anim_name == "\"launch\"":
		host.set_anim_param("parameters/air/current", 1)
	elif airstate == 3 and anim_name == "\"landing\"":
		emit_signal("finished", "idle")
