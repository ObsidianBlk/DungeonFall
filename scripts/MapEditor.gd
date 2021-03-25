extends Node2D

const DEFAULT_TILESET_NAME = "Moldy Dungeon"
const MAIN_WORLD_SCENE = "res://World.tscn"
const EDITORLEVEL_SCENE = "res://levels/EditorLevel.tscn"
const REPEATER_UPDATE_STEP = 0.25

enum EDITOR_MODE {NONE, FLOORS, PLAYER_START}

var DB = null

var tileset_def = null
var tileset_resource = null

var editorlevel_node = null
var tile_selector_inst = null

#var active_floor_type = "B"
#var floor_tile_id = -1
#var rand_floor = false

var repeater_update_step = 0.0
var tracker_motion = Vector2.ZERO
var editor_mode = EDITOR_MODE.FLOORS;
var map_dragging = false

onready var flooreditor_node = $FloorEditor
onready var playerstarteditor_node = $PlayerStartEditor

onready var camera = $Perma_Objects/Camera
onready var floorList_node = $CanvasLayer/EditorUI/FloorList

onready var vp_container = $MapView
onready var vp_port = $MapView/Port

onready var generalUI = $CanvasLayer/GeneralUI

func _ready():
	MemDB.connect("database_added", self, "_on_db_added")
	if not MemDB.has_db("MapEditor"):
		MemDB.add_db("MapEditor")
	else:
		DB = MemDB.get_db("MapEditor")

	get_tree().paused = false
	var EditorLevel = load(EDITORLEVEL_SCENE)
	if EditorLevel:
		editorlevel_node = EditorLevel.instance()
		$MapView/Port.add_child(editorlevel_node)
		editorlevel_node.attach_camera(camera)
		
		flooreditor_node.set_leveleditor_node(editorlevel_node)
		playerstarteditor_node.set_leveleditor_node(editorlevel_node)

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
		#var floor_mode = editor_mode == EDITOR_MODE.PLACE_FLOOR or editor_mode == EDITOR_MODE.CLEAR_FLOOR
		if editor_mode == EDITOR_MODE.FLOORS and editorlevel_node.get_tracker_position() != tpos:
			repeater_update_step = 0.0
	elif event is InputEventMouseButton:
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
	
	match(editor_mode):
		EDITOR_MODE.FLOORS:
			flooreditor_node._handleInput(event)
		EDITOR_MODE.PLAYER_START:
			playerstarteditor_node._handleInput(event)


func _process(delta):
	if repeater_update_step <= 0.0:
		if tracker_motion.length_squared() > 0:
			editorlevel_node.move_tracker(
				tracker_motion.x,
				tracker_motion.y
			)
		match(editor_mode):
			EDITOR_MODE.FLOORS:
				flooreditor_node._updateProcess(delta)
		repeater_update_step += REPEATER_UPDATE_STEP
	else:
		repeater_update_step -= delta


func reset_repeater():
	repeater_update_step = 0.0

func _listenDB():
	if DB != null:
		DB.connect("value_changed", self, "_on_db_value_changed")

func _unlistenDB():
	if DB != null:
		DB.disconnect("value_changed", self, "_on_db_value_changed")


func _on_tileset_activated(def):
	tileset_def = def


func _on_db_added(name : String):
	if DB != null:
		return

	if name == "MapEditor":
		DB = MemDB.get_db("MapEditor")
		_listenDB()


func _on_db_value_changed(name : String, val):
	match(name):
		"level_name":
			editorlevel_node.level_name = val
		"tile_break_time":
			editorlevel_node.tile_break_time = val
		"tile_break_variance":
			editorlevel_node.tile_break_variance = val

func _on_active_floor_type(type : String):
	if flooreditor_node == null:
		return
	editor_mode = EDITOR_MODE.FLOORS
	flooreditor_node.set_active_floor_type(type)


func _on_editor_quit():
	var world = load(MAIN_WORLD_SCENE)
	if world:
		get_tree().paused = true
		var world_node = world.instance()
		var p = get_parent()
		p.remove_child(self)
		p.add_child(world_node)
		queue_free()


func _on_tile_selected(id):
	if flooreditor_node == null:
		return
	flooreditor_node.set_active_tile_id(id)

func _on_random_floor(button_pressed):
	if flooreditor_node == null:
		return
	flooreditor_node.set_random_tile(button_pressed)
	floorList_node.visible = not flooreditor_node.is_random_tiles()


func _on_player_start(button_pressed):
	if button_pressed:
		editor_mode = EDITOR_MODE.PLAYER_START
		editorlevel_node.clear_ghost_tiles()

func _on_save_map():
	var mapData = editorlevel_node.generateMapData()
	if mapData:
		Io.storeMapData("MyMap.dfm", mapData)

func _on_load_map():
	# TODO: This is just place holder (and a quickie test).
	var data = Io.readMapData("user://maps/MyMap.dfm")
	if data:
		_unlistenDB()
		editorlevel_node.buildMapFromData(data)
		DB.set_value("level_name", data.name)
		DB.set_value("tile_break_time", data.map.tile_break_time)
		DB.set_value("tile_break_variance", data.map.tile_break_variance)
		_listenDB()



func _on_map_settings_toggled(button_pressed):
	$CanvasLayer/MapSettingsUI.visible = button_pressed
