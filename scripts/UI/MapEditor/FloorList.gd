extends Container

var tileset_def = null

func _ready():
	tileset_def = TilesetStore.get_definition()
	TilesetStore.connect("tileset_activated", self, "_on_tileset_activated")
	
	#tileset_resource = load(tileset_def.base_path + tileset_def.resource_path)
	#tile_selector_inst = load("res://objects/Editor/tileselector/TileSelector.tscn")
	#for bindex in range(0, tileset_def.floors.breakable.size()):
	#	var fdef = tileset_def.floors.breakable[bindex]
	#	var selector = tile_selector_inst.instance()
	#	floor_tile_list.add_child(selector)
	#	selector.set_tile(fdef.index, tileset_resource)
	#	selector.connect("tile_pressed", self, "_on_tile_pressed")


func _on_floor_btn_toggle(pressed : bool, btn : String):
	if pressed:
		pass

func _on_tileset_activated(def):
	tileset_def = def

