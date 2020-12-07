extends "res://scripts/FSM/State.gd"


func enter(host : Node):
	.enter(host)
	self.host.set_anim_param("parameters/moving/current", 0)

func resume(host : Node = null):
	.resume(host)

func exit():
	.exit()

func pause():
	.pause()

func handle_input(event):
	if event.is_action("move_down"):
		host.set_action(host.ACTION.DOWN, not event.is_action_released("move_down"))
	if event.is_action("move_up"):
		host.set_action(host.ACTION.UP, not event.is_action_released("move_up"))
	if event.is_action("move_left"):
		host.set_action(host.ACTION.LEFT, not event.is_action_released("move_left"))
	if event.is_action("move_right"):
		host.set_action(host.ACTION.RIGHT, not event.is_action_released("move_right"))


func handle_physics(delta):
	if host.velocity.length() == 0.0:
		emit_signal("finished", "idle")
		return
	move(delta)


func move(delta):
	var dx = 0
	var dy = 0
	if host.is_moving_v():
		dy = 1
		if host.is_action(host.ACTION.UP):
			dy = -1

	if host.is_moving_h():
		dx = 1
		if host.is_action(host.ACTION.LEFT):
			dx = -1
	
	host.move(delta, dx, dy)
	if host.velocity.length() > 0:
		host.move_and_collide(host.velocity)


