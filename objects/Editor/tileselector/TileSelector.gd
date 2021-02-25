extends Button

signal tile_selected(id)

var tile_id = -1

func set_tile(icon_id : int, tile_id, tileset : Resource):
	if icon_id >= 0:
		$TileMap.tile_set = tileset
		$TileMap.set_cell(0, 0, icon_id)
		self.tile_id = tile_id
	else:
		$TileMap.set_cell(0, 0, -1)
		$TileMap.tile_set = null
		self.tile_id = -1


func _haveValidTileID():
	if typeof(tile_id) == TYPE_STRING:
		return tile_id != ""
	return tile_id >= 0

func _on_toggled(button_pressed):
	if button_pressed:
		if _haveValidTileID():
			emit_signal("tile_selected", tile_id)
