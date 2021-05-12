extends Node
class_name State


signal finished(next_state)

var host = null
var paused = false

func enter(_host : Node):
	host = _host

func resume(_host : Node = null):
	if _host != null: # Only change the host if given an actual Node.
		host = _host
	paused = false

func exit():
	self.host = null

func pause():
	paused = true

func handle_input(_event):
	pass

func handle_update(_delta):
	pass

func handle_physics(_delta):
	pass
