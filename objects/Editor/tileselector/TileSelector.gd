extends Button

signal tile_selected(id)

func set_tile(id : int, tileset : Resource):
	if id >= 0:
		$TileMap.tile_set = tileset
		$TileMap.set_cell(0, 0, id)
	else:
		$TileMap.set_cell(0, 0, -1)
		$TileMap.tile_set = null


func _on_toggled(button_pressed):
	if button_pressed:
		if $TileMap.tile_set != null:
			emit_signal("tile_selected", $TileMap.get_cell(0, 0))
