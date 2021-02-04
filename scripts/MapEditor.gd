extends Node2D

const DEFAULT_TILESET_NAME = "Moldy Dungeon"
const MAIN_WORLD_SCENE = "res://World.tscn"
const EDITORLEVEL_SCENE = "res://levels/EditorLevel.tscn"

var tileset_def = null
var tileset_resource = null

var editorlevel_node = null
var tile_selector_inst = null

var active_floor_type = "B"
var floor_tile_id = -1
var rand_floor = false

onready var camera = $Perma_Objects/Camera
onready var floorList_node = $CanvasLayer/EditorUI/FloorList

onready var generalUI = $CanvasLayer/GeneralUI

func _ready():
	get_tree().paused = false
	var EditorLevel = load(EDITORLEVEL_SCENE)
	if EditorLevel:
		editorlevel_node = EditorLevel.instance()
		$MapView/Port.add_child(editorlevel_node)
		editorlevel_node.attach_camera(camera)

		tileset_def = TilesetStore.get_definition()
		TilesetStore.connect("tileset_activated", self, "_on_tileset_activated")


func _input(event):
	if event.is_action_pressed("ui_cancel"):
		generalUI.visible = not generalUI.visible
		get_tree().paused = generalUI.visible
	if event.is_action_pressed("ui_select"):
		if editorlevel_node != null:
			if rand_floor or floor_tile_id < 0:
				match(active_floor_type):
					"B":
						editorlevel_node.set_rand_breakable_floor_at_tracker()
					"S":
						editorlevel_node.set_rand_safe_floor_at_tracker()
					"E":
						editorlevel_node.set_rand_exit_floor_at_tracker()
			else:
				editorlevel_node.set_floor_at_tracker(floor_tile_id)
	if event.is_action_pressed("ui_deselect"):
		if editorlevel_node != null:
			editorlevel_node.clear_floor_at_tracker()


func _on_tileset_activated(def):
	tileset_def = def


func _on_active_floor_type(type : String):
	if type == "B" or type == "S" or type == "E":
		active_floor_type = type


func _on_editor_quit():
	var world = load(MAIN_WORLD_SCENE)
	if world:
		get_tree().paused = true
		var world_node = world.instance()
		var p = get_parent()
		p.remove_child(self)
		p.add_child(world_node)
		queue_free()


func _on_tile_selected(id : int):
	floor_tile_id = id

func _on_random_floor(button_pressed):
	rand_floor = button_pressed
	floorList_node.visible = not rand_floor
