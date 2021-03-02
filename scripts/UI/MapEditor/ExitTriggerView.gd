extends Node2D

func _process(delta):
	update()

func _draw():
	var mbt = get_parent().get_node("MapBuildTools")
	if mbt:
		var color = Color(0.15, 0, 1.0, 0.5)
		var dungeon_exits = mbt.dungeon_exits
		for i in range(0, dungeon_exits.size()):
			var de = dungeon_exits[i]
			if de.size.x == de.size.y:
				draw_circle(Vector2(de.x, de.y), de.size.x, color)
			else:
				var r = de.size.x
				if de.size.y < r:
					r = de.size.y
					draw_set_transform(Vector2(de.x, de.y), 0, Vector2(de.size.x / r, 1))
				else:
					draw_set_transform(Vector2(de.x, de.y), 0, Vector2(1, de.size.y / r))
				draw_circle(Vector2(de.x, de.y), r, color)
				
