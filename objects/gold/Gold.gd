extends Node2D


signal pickup()

func _on_pickup(body):
	emit_signal("pickup")
	queue_free()
