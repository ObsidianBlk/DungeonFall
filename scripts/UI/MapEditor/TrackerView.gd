extends Node2D

onready var tracker = get_parent().get_node("Tracker")

func _process(delta):
	update()

func _draw():
	var cell = get_parent().cell
	var x = floor(tracker.position.x / cell.x) * cell.x
	var y = floor(tracker.position.y / cell.y) * cell.y
	var rect = Rect2(x, y, cell.x, cell.y)
	draw_rect(rect, Color(1.0, 0.0, 0.0, 0.5), false, 1.0)


