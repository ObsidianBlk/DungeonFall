extends Node2D


signal pickup()

func _on_pickup(body):
	emit_signal("pickup")
	var parent = get_parent()
	if parent:
		parent.remove_child(self)
	queue_free()
