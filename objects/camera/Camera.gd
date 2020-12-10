extends Camera2D

export var target_node_path : NodePath = "" setget _set_target_node_path
export(float, 0.01, 120.0) var track_time = 0.1

var ready = false
var target_node = null
var last_pos = Vector2.ZERO


func _set_target_node_path(p : NodePath, force : bool = false):
	if p != target_node_path or force:
		if ready and p != "":
			var ntn = get_node(p)
			if ntn != null:
				target_node_path = p
				target_node = ntn
		else:
			target_node_path = p
			target_node = null


# Called when the node enters the scene tree for the first time.
func _ready():
	ready = true
	_set_target_node_path(target_node_path, true)

func _physics_process(delta):
	if target_node != null:
		var tpos = target_node.global_position
		if global_position != tpos and tpos != last_pos:
			last_pos = tpos
			$Tween.interpolate_property(self, "global_position", global_position, tpos, track_time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			$Tween.start()


