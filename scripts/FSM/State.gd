extends Node
class_name State


signal finished(next_state)

var host = null
var paused = false

func enter(host : Node):
	self.host = host
	print("Name: ", self.name, " | VAR: ", self.host)

func resume(host : Node = null):
	if host != null: # Only change the host if given an actual Node.
		self.host = host
	paused = false

func exit():
	self.host = null

func pause():
	paused = true

func handle_input(event):
	pass

func handle_update(delta):
	pass

func handle_physics(delta):
	pass
