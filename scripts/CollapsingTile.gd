extends Node2D
class_name CollapsingTile


var safe = true

func is_safe():
	return safe

func _unsafe():
	safe = false


