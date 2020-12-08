extends "res://objects/player/states/move.gd"


const BREATH_DELAY = 0.5 # In seconds
const BREATH_DELAY_VARIANCE = 0.5 # in percentage (0.0 - 1.0)

var cur_breath_delay = 0.0
var await_anim = false

func enter(host : Node):
	.enter(host)
	self.host.set_anim_param("parameters/moving/current", 1)

func resume(host : Node = null):
	.resume(host)

func exit():
	# Handle exit, then call the base method
	.exit()

func pause():
	# Handle pausing, then call the base method
	.pause()

func handle_physics(delta):
	if host.is_over_pit():
		emit_signal("finished", "death")
		return
	move(delta)
	if host.velocity.length() > 0:
		emit_signal("finished", "move")
		return

	if cur_breath_delay > 0.0:
		cur_breath_delay -= delta
	elif not await_anim:
		# TODO: Call breath animation
		await_anim = true

func handle_animation_finished(anim_name):
	if anim_name == "breath":
		await_anim = false
		var dv = BREATH_DELAY * BREATH_DELAY_VARIANCE
		cur_breath_delay = BREATH_DELAY + rand_range(-dv, dv)

