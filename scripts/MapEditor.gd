extends Node2D

const DEFAULT_TILESET_NAME = "Moldy Dungeon"
const MAIN_WORLD_SCENE = "res://World.tscn"
const EDITORLEVEL_SCENE = "res://levels/EditorLevel.tscn"
const REPEATER_UPDATE_STEP = 0.25

var tileset_def = null
var tileset_resource = null

var editorlevel_node = null
var tile_selector_inst = null

var active_floor_type = "B"
var floor_tile_id = -1
var rand_floor = false

var repeater_update_step = 0.0
var tracker_motion = Vector2.ZERO
var floor_place_active = false
var floor_clear = false
var map_dragging = false

onready var camera = $Perma_Objects/Camera
onready var floorList_node = $CanvasLayer/EditorUI/FloorList

onready var vp_container = $MapView
onready var vp_port = $MapView/Port

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


func _mousepos_to_vp(pos : Vector2, campos : Vector2):
	var scale = vp_port.size / vp_container.rect_size
	var offset = campos - (vp_port.size * 0.5)
	return (pos * scale) + offset

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		editorlevel_node.enable_camera_tracking(false)
		var campos = editorlevel_node.get_camera_position()
		var mpos = _mousepos_to_vp(event.position, campos)
		if map_dragging:
			#var pos = mpos - campos
			editorlevel_node.move_camera(event.relative)
			campos = editorlevel_node.get_camera_position()
			mpos = _mousepos_to_vp(event.position, campos)
		
		var tpos = editorlevel_node.get_tracker_position()
		editorlevel_node.position_tracker_to(mpos)
		if floor_place_active and editorlevel_node.get_tracker_position() != tpos:
			repeater_update_step = 0.0
	elif event is InputEventMouseButton:
		if event.is_action_pressed("MapEditor_MousePlace"):
			_updateFloorState(true)
		if event.is_action_pressed("MapEditor_MouseClear"):
			_updateFloorState(true, true)
		if event.is_action_released("MapEditor_MousePlace") or event.is_action_released("MapEditor_MouseClear"):
			_updateFloorState(false)
		
		if event.is_action_pressed("MapEditor_MouseMapDrag"):
			map_dragging = true
		elif event.is_action_released("MapEditor_MouseMapDrag"):
			map_dragging = false
	else:
		if event.is_action_pressed("ui_cancel"):
			generalUI.visible = not generalUI.visible
			get_tree().paused = generalUI.visible
		
		if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
			editorlevel_node.enable_camera_tracking(true)
			if event.is_action_pressed("ui_left"):
				tracker_motion.x -= 1
			if event.is_action_pressed("ui_right"):
				tracker_motion.x += 1
			repeater_update_step = 0.0
		if event.is_action_released("ui_left") or event.is_action_released("ui_right"):
			tracker_motion.x = 0
		
		if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
			editorlevel_node.enable_camera_tracking(true)
			if event.is_action_pressed("ui_up"):
				tracker_motion.y -= 1
			if event.is_action_pressed("ui_down"):
				tracker_motion.y += 1
			repeater_update_step = 0.0
		if event.is_action_released("ui_up") or event.is_action_released("ui_down"):
			tracker_motion.y = 0
		
		
		if event.is_action_pressed("ui_select"):
			_updateFloorState(true)
		if event.is_action_pressed("ui_deselect"):
			_updateFloorState(true, true)
		if event.is_action_released("ui_select") or event.is_action_released("ui_deselect"):
			_updateFloorState(false)

func _process(delta):
	if repeater_update_step <= 0.0:
		if tracker_motion.length_squared() > 0:
			editorlevel_node.move_tracker(tracker_motion.x, tracker_motion.y)
		if floor_place_active:
			_updateFloor(floor_clear)
		repeater_update_step += REPEATER_UPDATE_STEP
	else:
		repeater_update_step -= delta


func _updateFloorState(active : bool, clear : bool = false):
	floor_place_active = active
	floor_clear = clear
	if active:
		repeater_update_step = 0.0

func _updateFloor(clear : bool = false):
	if editorlevel_node != null:
		if clear:
			editorlevel_node.clear_floor_at_tracker()
		elif rand_floor or floor_tile_id < 0:
			match(active_floor_type):
				"B":
					editorlevel_node.set_rand_breakable_floor_at_tracker()
				"S":
					editorlevel_node.set_rand_safe_floor_at_tracker()
				"E":
					editorlevel_node.set_rand_exit_floor_at_tracker()
		else:
			editorlevel_node.set_floor_at_tracker(floor_tile_id)


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
