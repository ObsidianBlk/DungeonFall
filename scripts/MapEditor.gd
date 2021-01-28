extends Node2D

const MAIN_WORLD_SCENE = "res://World.tscn"
const EDITORLEVEL_SCENE = "res://levels/EditorLevel.tscn"

var tileset_def = null
var tileset_resource = null

var editorlevel_node = null
var tile_selector_inst = null

onready var camera = $Perma_Objects/Camera
onready var floor_tile_list = $CanvasLayer/EditorUI/FloorList/Margins/Scroll/Tiles

onready var generalUI = $CanvasLayer/GeneralUI

func _ready():
	get_tree().paused = false
	var EditorLevel = load(EDITORLEVEL_SCENE)
	if EditorLevel:
		editorlevel_node = EditorLevel.instance()
		$MapView/Port.add_child(editorlevel_node)
		editorlevel_node.attach_camera(camera)
		editorlevel_node.set_tileset_name("Moldy Dungeon")

		#tileset_def = TilesetStore.TILESETS["Moldy Dungeon"]
		#tileset_resource = load(tileset_def.base_path + tileset_def.resource_path)
		#tile_selector_inst = load("res://objects/Editor/tileselector/TileSelector.tscn")
		#for bindex in range(0, tileset_def.floors.breakable.size()):
		#	var fdef = tileset_def.floors.breakable[bindex]
		#	var selector = tile_selector_inst.instance()
		#	floor_tile_list.add_child(selector)
		#	selector.set_tile(fdef.index, tileset_resource)
		#	selector.connect("tile_pressed", self, "_on_tile_pressed")


func _input(event):
	if event.is_action_pressed("ui_cancel"):
		generalUI.visible = not generalUI.visible
		get_tree().paused = generalUI.visible
	if event.is_action_pressed("ui_select"):
		if editorlevel_node != null:
			editorlevel_node.set_rand_breakable_floor_at_tracker()


#func _on_tile_pressed(id : int):
#	print("Tile ID ", id, " selected!")


func _on_editor_quit():
	var world = load(MAIN_WORLD_SCENE)
	if world:
		get_tree().paused = true
		var world_node = world.instance()
		var p = get_parent()
		p.remove_child(self)
		p.add_child(world_node)
		queue_free()

