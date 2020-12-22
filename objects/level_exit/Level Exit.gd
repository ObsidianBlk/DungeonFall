extends Area2D

signal level_exit


const TRIGGER_MAX_DIST = 2.0
const TRIGGER_TIMER = 1.0 # Should be in seconds

var player_node = null
var timer = 0.0

func _ready():
	_enable_process(false)

func _enable_process(e : bool = true):
	set_process(e)
	set_physics_process(e)

func _process(delta):
	if player_node != null:
		if self.global_position.distance_to(player_node.global_position) < 2.0:
			emit_signal("level_exit")
			_enable_process(false)


func _physics_process(delta):
	if player_node != null:
		timer = timer + delta
		if timer >= TRIGGER_TIMER:
			emit_signal("level_exit")
			_enable_process(false)


func _on_Level_Exit_body_entered(body):
	if player_node == null:
		player_node = body
		_enable_process()
