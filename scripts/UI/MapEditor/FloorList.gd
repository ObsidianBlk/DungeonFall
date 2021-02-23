extends Container

signal tile_selected(tile_index)

const TILE_SELECTOR_RESOURCE = "res://objects/Editor/tileselector/TileSelector.tscn"

var tile_selector_inst = null
var tileset_def = null
var tileset_resource = null
var current_tile_type = "B"

onready var tile_list_node = $Margins/Scroll/Tiles

func _ready():
	TilesetStore.connect("tileset_activated", self, "_on_tileset_activated")
	_on_tileset_activated(TilesetStore.get_definition())
	
	tile_selector_inst = load(TILE_SELECTOR_RESOURCE)
	_clear_tile_list()
	_fill_tile_list()

func _clear_tile_list():
	for child in tile_list_node.get_children():
		tile_list_node.remove_child(child)

func _add_selector(tile_index, btngrp : ButtonGroup, select : bool = false):
	if not tile_selector_inst:
		return
	if typeof(tile_index) == TYPE_STRING:
		tile_index = TilesetStore.get_meta_icon(tileset_def, tile_index)
		if tile_index < 0:
			return

	var selector = tile_selector_inst.instance()
	tile_list_node.add_child(selector)
	selector.group = btngrp
	selector.set_tile(tile_index, tileset_resource)
	selector.connect("tile_selected", self, "_on_tile_selected")
	selector.pressed = true

func _fill_tile_list():
	var bg = ButtonGroup.new()
	match(current_tile_type):
		"B":
			for tindex in range(0, tileset_def.floors.breakable.size()):
				var fdef = tileset_def.floors.breakable[tindex]
				_add_selector(fdef.index, bg, tindex == 0)
		"S":
			for tindex in range(0, tileset_def.floors.safe.size()):
				_add_selector(tileset_def.floors.safe[tindex], bg, tindex == 0)
		"E":
			for tindex in range(0, tileset_def.floors.exit.size()):
				_add_selector(tileset_def.floors.exit[tindex], bg, tindex == 0)


func _on_floor_btn_toggle(pressed : bool, btn : String):
	if pressed:
		current_tile_type = btn
		_clear_tile_list()
		_fill_tile_list()


func _on_tileset_activated(def):
	if tileset_def == null or def.name != tileset_def.name:
		tileset_def = def
		tileset_resource = load(tileset_def.base_path + tileset_def.resource_path)
		_clear_tile_list()
		_fill_tile_list()

func _on_tile_selected(tile_index : int):
	emit_signal("tile_selected", tile_index)

