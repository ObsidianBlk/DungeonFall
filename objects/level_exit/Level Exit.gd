extends Area2D

signal level_exit


const TRIGGER_MAX_DIST = 2.0
const TRIGGER_TIMER = 1.0 # Should be in seconds

var ready = false
var player_node = null
var timer = 0.0

func _initialize():
	ready = true
	_enable_process(false)

func _enable_process(e : bool = true):
	set_process(e)
	set_physics_process(e)

func _process(delta):
	if player_node != null:
		if self.global_position.distance_to(player_node.global_position) < 2.0:
			print("Calling for exit level ... Distance")
			emit_signal("level_exit")
			_enable_process(false)


func _physics_process(delta):
	if player_node != null:
		timer = timer + delta
		if timer >= TRIGGER_TIMER:
			print("Calling for exit level ... Time")
			emit_signal("level_exit")
			_enable_process(false)


func _on_Level_Exit_body_entered(body):
	if player_node == null and ready:
		if overlaps_body(body):
			player_node = body
			print("Body Entered ... ", body.global_position)
			print("Self position ... ", self.global_position)
			print(self)
			print("Ready: ", ready)
			#print("Collision Position: ", $CollisionShape2D.global_position)
			_enable_process()


func _on_Level_Exit_body_exited(body):
	if body == player_node:
		player_node = null
		_enable_process(false)
