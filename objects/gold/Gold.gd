extends Node2D

signal pickup()

export var editor_mode : bool = false


func _on_pickup(body : Node2D) -> void:
	if not editor_mode:
		emit_signal("pickup")
		var parent = get_parent()
		if parent:
			parent.remove_child(self)
		queue_free()
