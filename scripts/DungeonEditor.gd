extends Node2D

const DEFAULT_TILESET_NAME = "Moldy Dungeon"
const MAIN_WORLD_SCENE = "res://World.tscn"
const DUNGEONLEVEL_SCENE = "res://levels/EditorDungeon.tscn"
const REPEATER_UPDATE_STEP = 0.25

const DB_NAME = "Editor"

enum EDITOR_MODE {NONE, FLOORS, PLAYER_START, PLACEABLES}

var DB = null

var tileset_def = null
var tileset_resource = null

var dungeonlevel_node = null
var tile_selector_inst = null

var repeater_update_step = 0.0
var tracker_motion = Vector2.ZERO
var editor_mode = EDITOR_MODE.FLOORS;
var map_dragging = false

onready var confirmpopup_node = $CanvasLayer/ConfirmPopup
onready var dungeonload_node = $CanvasLayer/DungeonLoadPopup

onready var flooreditor_node = $FloorEditor
onready var playerstarteditor_node = $PlayerStartEditor

onready var camera = $Perma_Objects/Camera
#onready var floorList_node = $CanvasLayer/EditorUI/VBoxContainer/FloorList

onready var vp_container = $DungeonView
onready var vp_port = $DungeonView/Port

onready var toolbarUI = $CanvasLayer/EditorUI/UI_Toolbar
onready var dungeonSettingsUI = $CanvasLayer/DungeonSettingsUI
onready var placeablesUI = $CanvasLayer/Placeables
#onready var generalUI = $CanvasLayer/GeneralUI

func _ready():
	MemDB.connect("database_added", self, "_on_db_added")
	if not MemDB.has_db(DB_NAME):
		MemDB.add_db(DB_NAME)
	else:
		DB = MemDB.get_db(DB_NAME)

	get_tree().paused = false
	var DungeonLevel = load(DUNGEONLEVEL_SCENE)
	if DungeonLevel:
		dungeonlevel_node = DungeonLevel.instance()
		vp_port.add_child(dungeonlevel_node)
		dungeonlevel_node.attach_camera(camera)
		
		flooreditor_node.set_editordungeon_node(dungeonlevel_node)
		playerstarteditor_node.set_editordungeon_node(dungeonlevel_node)

		tileset_def = TilesetStore.get_definition()
		TilesetStore.connect("tileset_activated", self, "_on_tileset_activated")
		
		dungeonlevel_node.connect("floor_changed", dungeonSettingsUI, "_update_placeable_tiles")
		_newDungeon()


func _mousepos_to_vp(pos : Vector2, campos : Vector2):
	var scale = vp_port.size / vp_container.rect_size
	var offset = campos - (vp_port.size * 0.5)
	return (pos * scale) + offset

func _ShowConfirmPopup(text : String, confirm_only : bool, method : String, binds : Array = []):
	if method == "" or confirmpopup_node.visible:
		return false
	confirmpopup_node.text = text
	confirmpopup_node.confirm_only = confirm_only
	confirmpopup_node.connect("confirm", self, method, binds)
	confirmpopup_node.popup()
	return true

func _unhandled_input(event):
	var ctrlInFocus = toolbarUI.get_focus_owner() != null
	if event is InputEventMouseMotion:
		dungeonlevel_node.enable_camera_tracking(false)
		var campos = dungeonlevel_node.get_camera_position()
		var mpos = _mousepos_to_vp(event.position, campos)
		if map_dragging:
			#var pos = mpos - campos
			dungeonlevel_node.move_camera(event.relative)
			campos = dungeonlevel_node.get_camera_position()
			mpos = _mousepos_to_vp(event.position, campos)
		
		var tpos = dungeonlevel_node.get_tracker_position()
		dungeonlevel_node.position_tracker_to(mpos)
		#var floor_mode = editor_mode == EDITOR_MODE.PLACE_FLOOR or editor_mode == EDITOR_MODE.CLEAR_FLOOR
		if editor_mode == EDITOR_MODE.FLOORS and dungeonlevel_node.get_tracker_position() != tpos:
			repeater_update_step = 0.0
	elif event is InputEventMouseButton:
		if event.is_action_pressed("MapEditor_MouseMapDrag"):
			map_dragging = true
		elif event.is_action_released("MapEditor_MouseMapDrag"):
			map_dragging = false
	else:
		if event.is_action_pressed("MapEditor_Placeables"):
			if editor_mode != EDITOR_MODE.PLACEABLES:
				editor_mode = EDITOR_MODE.PLACEABLES
				placeablesUI.popup_centered()
		if event.is_action_pressed("MapEditor_DeviceMode_Toggle"):
			if not ctrlInFocus:
				toolbarUI.set_focus()
			elif toolbarUI.in_focus():
				toolbarUI.drop_focus()
		if event.is_action_pressed("ui_cancel"):
			if dungeonSettingsUI.visible:
				dungeonSettingsUI.hide()
			elif editor_mode == EDITOR_MODE.PLACEABLES:
				if placeablesUI.visible:
					placeablesUI.hide()
			elif not _ShowConfirmPopup("Exit Dungeon Editor?", false, "_on_editor_quit"):
				_on_ConfirmPopup_cancel()
			#generalUI.visible = not generalUI.visible
			#get_tree().paused = generalUI.visible
		
		if not ctrlInFocus: # Only handle below if NO Control has input focus.
			if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
				dungeonlevel_node.enable_camera_tracking(true)
				if event.is_action_pressed("ui_left"):
					tracker_motion.x -= 1
				if event.is_action_pressed("ui_right"):
					tracker_motion.x += 1
				repeater_update_step = 0.0
			if event.is_action_released("ui_left") or event.is_action_released("ui_right"):
				tracker_motion.x = 0
			
			if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
				dungeonlevel_node.enable_camera_tracking(true)
				if event.is_action_pressed("ui_up"):
					tracker_motion.y -= 1
				if event.is_action_pressed("ui_down"):
					tracker_motion.y += 1
				repeater_update_step = 0.0
			if event.is_action_released("ui_up") or event.is_action_released("ui_down"):
				tracker_motion.y = 0
	
	if not ctrlInFocus: # Only handle below if NO Control has input focus.
		match(editor_mode):
			EDITOR_MODE.FLOORS:
				flooreditor_node._handleInput(event)
			EDITOR_MODE.PLAYER_START:
				playerstarteditor_node._handleInput(event)


func _process(delta):
	if repeater_update_step <= 0.0:
		if tracker_motion.length_squared() > 0:
			dungeonlevel_node.move_tracker(
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


func _newDungeon():
	_unlistenDB()
	dungeonlevel_node.clearMapData()
	DB.set_value("dungeon_name", dungeonlevel_node.dungeon_name)
	DB.set_value("engineer_name", dungeonlevel_node.engineer_name)
	DB.set_value("tile_break_time", dungeonlevel_node.tile_break_time)
	DB.set_value("tile_break_variance", dungeonlevel_node.tile_break_variance)
	DB.set_value("timer_autostart", dungeonlevel_node.dungeon_timer_autostart)
	DB.set_value("collapse_timer", dungeonlevel_node.dungeon_collapse_timer)
	DB.set_value("gold_amount", dungeonlevel_node.gold_amount)
	DB.set_value("gold_seed", dungeonlevel_node.gold_seed)
	_listenDB()

func _loadDungeon(path):
	# TODO: This is just place holder (and a quickie test).
	var data = Io.readMapData(path)
	if data:
		_unlistenDB()
		dungeonlevel_node.buildMapFromData(data)
		DB.set_value("dungeon_name", data.name)
		DB.set_value("engineer_name", data.engineer)
		DB.set_value("tile_break_time", data.map.tile_break_time)
		DB.set_value("tile_break_variance", data.map.tile_break_variance)
		DB.set_value("timer_autostart", data.map.timer_autostart)
		DB.set_value("collapse_timer", data.map.collapse_timer)
		DB.set_value("gold_amount", data.map.gold_amount)
		DB.set_value("gold_seed", data.map.gold_seed)
		_listenDB()



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

	if name == DB_NAME:
		DB = MemDB.get_db(DB_NAME)
		_listenDB()


func _on_db_value_changed(name : String, val):
	match(name):
		"dungeon_name":
			dungeonlevel_node.dungeon_name = val
		"engineer_name":
			dungeonlevel_node.engineer_name = val
		"tile_break_time":
			dungeonlevel_node.tile_break_time = val
		"tile_break_variance":
			dungeonlevel_node.tile_break_variance = val
		"timer_autostart":
			dungeonlevel_node.dungeon_timer_autostart = val
		"collapse_timer":
			dungeonlevel_node.dungeon_collapse_timer = val
		"gold_amount":
			dungeonlevel_node.gold_amount = val
		"gold_seed":
			dungeonlevel_node.gold_seed = val

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
	#floorList_node.visible = not flooreditor_node.is_random_tiles()


func _on_player_start_selected():
	editor_mode = EDITOR_MODE.PLAYER_START
	dungeonlevel_node.clear_ghost_tiles()

func _on_save_dungeon():
	if not dungeonlevel_node.isRoyal:
		if dungeonlevel_node.dungeon_name != "":
			var dungeonData = dungeonlevel_node.generateMapData()
			if dungeonData:
				if Io.storeDungeonData(dungeonData):
					_ShowConfirmPopup("Dungeon '" + dungeonData.name + "' successfully scribed!", true, "_on_ConfirmPopup_cancel")
				else:
					_ShowConfirmPopup("Failed to scribe dungeon '" + dungeonData.name + "'.", true, "_on_ConfirmPopup_cancel")
		else:
			_ShowConfirmPopup("Dungeon cannot be scribed without a name!", true, "_on_ConfirmPopup_cancel")
	else:
		_ShowConfirmPopup("Cannot save a royal dungeon. Only the scribe masters can do that.", true, "_on_ConfirmPopup_cancel")


func _on_requestdelete_dungeon(name : String, path : String):
	if path.begins_with("res://"):
		_ShowConfirmPopup("The dungeon '" + name + "' is part of the royal registry. You cannot remove it!", true, "_on_ConfirmPopup_cancel")
	else:
		_ShowConfirmPopup("Delete dungeon '" + name + "'?", false, "_on_delete_dungeon", [name, path])


func _on_delete_dungeon(name : String, path: String):
	_on_ConfirmPopup_cancel()
	Io.deleteDungeon(path)
	dungeonload_node.visible = false


func _on_dungeon_settings_pressed():
	dungeonSettingsUI.popup_centered()

func _on_ConfirmPopup_cancel():
	if not confirmpopup_node.visible:
		return
	
	var cl = confirmpopup_node.get_signal_connection_list("confirm")
	if cl.size() > 0:
		for i in range(0, cl.size()):
			confirmpopup_node.disconnect("confirm", cl[i].target, cl[i].method)
	confirmpopup_node.visible = false
	confirmpopup_node.text = ""


func _on_dungeonload_cancel():
	dungeonload_node.visible = false


func _on_rquestdungeonload_pressed():
	dungeonload_node.popup()


func _on_loaddungeonfresh_dungeon(path):
	_on_ConfirmPopup_cancel()
	dungeonload_node.visible = false
	# TODO: Check if any changes have been made to existing map... if any.
	_loadDungeon(path)


func _on_newdungeon_pressed():
	_newDungeon()


func _on_Placeables_hide():
	editor_mode = EDITOR_MODE.FLOORS
