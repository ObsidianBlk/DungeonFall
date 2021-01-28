extends MenuButton

var popup = null
var active_tileset_name = null

func _select_tileset(tileset_name):
	if active_tileset_name != tileset_name:
		TilesetStore.activate_tileset(tileset_name)

func _update_tilesets_list():
	if popup != null:
		popup.clear()
		var default_tileset = null
		if active_tileset_name == null or not TilesetStore.TILESETS.has(active_tileset_name):
			default_tileset = ""
		
		for tileset_name in TilesetStore.TILESETS.keys():
			popup.add_item(tileset_name)
			if default_tileset == "":
				default_tileset = tileset_name
		if default_tileset != null and default_tileset != "":
			_select_tileset(default_tileset)

func _ready():
	var default_tileset = ""
	popup = get_popup()
	
	TilesetStore.connect("tile_defs_scanned", self, "_on_update_tilesets")
	TilesetStore.connect("tileset_activated", self, "_on_tileset_activated")
	popup.connect("id_pressed", self, "_on_item_selected")
	_update_tilesets_list()


func _on_item_selected(id):
	_select_tileset(popup.get_item_text(id))

func _on_tileset_activated(def):
	active_tileset_name = def.name
	text = def.name

func _on_update_tilesets():
	_update_tilesets_list()
