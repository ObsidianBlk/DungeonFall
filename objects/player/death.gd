extends "res://scripts/FSM/State.gd"

# TODO: Handle "Falling to your death" and "Slain by monster"


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
	pass

func handle_animation_finished(anim_name):
	#print("Anim name: ", anim_name, " | Handling: ", anim_name == "death_fall")
	# TODO: Why this fail??!!!!!!!!!!!!!
	if anim_name == "death_fall":
		print ("We done died damnit!")
