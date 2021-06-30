extends Node2D

func _process(delta):
	update()

func _draw():
	var cell = get_parent().cell
	var x = int(position.x) % int(cell.x)
	var y = int(position.y) % int(cell.y)
	var rect = Rect2(x, y, cell.x, cell.y)
	draw_rect(rect, Color(1.0, 0.0, 0.0, 0.5), false, 1.0)
