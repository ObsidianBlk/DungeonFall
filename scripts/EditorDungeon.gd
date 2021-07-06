extends Node2D

signal floor_changed(amount)

# TODO: Do these *really* need to be Export variables.
export var dungeon_name : String = "Level"
export var engineer_name : String = ""
export var dungeon_collapse_timer : float = 0.0
export var dungeon_timer_autostart : bool = true
export var tile_break_time : float = 1.0 setget _set_tile_break_time
export var tile_break_variance : float = 0.2 setget _set_tile_break_variance
export var gold_amount : int = 0 setget _set_gold_amount
export var gold_seed : String = "" setget _set_gold_seed

var isRoyal = false
var camera_node = null
var cell = Vector2(16.0, 16.0)

onready var DungeonBT_node = $DungeonBuildTools
onready var walls_node = $Walls
onready var cam_container_node = $Camera_Container
onready var tracker = $Tracker
onready var player_start = $Player_Start

func _set_tile_break_time(v):
	if v < 0.1:
		v = 0.1
	elif v > 2.0:
		v = 2.0
	
	if v != tile_break_time:
		tile_break_time = v
		if v < tile_break_variance:
			tile_break_variance = v


func _set_tile_break_variance(v):
	if v < 0.0:
		v = 0.0
	elif v > tile_break_time:
		v = tile_break_time
	
	if v < tile_break_variance:
		tile_break_variance = v


func _set_gold_amount(a):
	if a >= 0 and gold_amount != a:
		gold_amount = a
		regen_gold()

func _set_gold_seed(s):
	if s != gold_seed:
		gold_seed = s
		regen_gold()


func _ready():
	DungeonBT_node.connect("floor_changed", self, "_on_floor_changed")
	#TilesetStore.connect("tileset_activated", self, "_on_tileset_activated")
	#set_tileset_name(TilesetStore.get_active_tileset_name())

func _on_floor_changed():
	emit_signal("floor_changed", DungeonBT_node.get_floor_count())


func player_start_to_tracker():
	player_start.position = tracker.position + (cell * 0.5)
	
	var tindex = DungeonBT_node.get_floor_at_pos(player_start.position)
	if tindex >= 0:
		if DungeonBT_node.is_tile_breakable(tindex):
			return {"status":"warning", "msg":"Player starting on breakable tile"}
	else:
		return {"status":"error", "msg":"Player outside map bounds"}
	
	return {"status":"success"}

func position_player_start(x, y):
	player_start.position = Vector2(
		(cell.x * floor(x)) + (cell.x * 0.5),
		(cell.y * floor(y)) + (cell.y * 0.5)
	)

func position_player_start_to(pos : Vector2):
	pos = walls_node.world_to_map(pos)
	position_player_start(pos.x, pos.y)

func set_tracker_ghost_entity(entity_name : String) -> void:
	tracker.ghost_entity = entity_name

func clear_tracker_ghost_entity() -> void:
	tracker.ghost_entity = "" # Don't look at me like that! :p

func move_tracker(x, y):
	if abs(x) > 0:
		tracker.position.x += cell.x * floor(x)
	if abs(y) > 0:
		tracker.position.y += cell.y * floor(y)

func position_tracker(x, y):
	tracker.position.x = cell.x * floor(x)
	tracker.position.y = cell.y * floor(y)
	

func position_tracker_to(pos : Vector2):
	pos = walls_node.world_to_map(pos)
	position_tracker(pos.x, pos.y)

func get_tracker_position():
	return tracker.position


func get_camera_position():
	if camera_node == null:
		return Vector2.ZERO
	return camera_node.position

func set_camera_position_to(pos : Vector2):
	if camera_node != null:
		camera_node.position = pos

func move_camera(relative : Vector2):
	if camera_node != null:
		camera_node.relative_move(relative)

func enable_camera_tracking(enable : bool = true):
	if camera_node == null:
		return
	camera_node.ignore_target = not enable


func attach_camera(camera : Node2D, autoTrack : bool = true):
	if camera_node != null:
		return
	camera_node = camera
	var parent = camera.get_parent()
	parent.remove_child(camera)
	cam_container_node.add_child(camera)
	if autoTrack:
		camera.target_node_path = camera.get_path_to(tracker)
	camera.current = true

func detach_camera_to_container(container : Node2D):
	if camera_node != null:
		camera_node.current = false
		camera_node.target_node_path = ""
		cam_container_node.remove_child(camera_node)
		container.add_child(camera_node)
		camera_node = null

func clear_floor_at_tracker():
	return DungeonBT_node.set_floor_at_pos(tracker.position, -1)

func set_floor_at_tracker(floor_tile, wall_tile : int = -1):
	return DungeonBT_node.set_floor_at_pos(tracker.position, floor_tile, wall_tile)

func set_rand_breakable_floor_at_tracker(wall_tile : int = -1):
	return set_rand_breakable_floor_at_pos(tracker.position, wall_tile)

func set_rand_safe_floor_at_tracker(wall_tile: int = -1):
	return set_rand_safe_floor_at_pos(tracker.position, wall_tile)

func set_rand_exit_floor_at_tracker(wall_tile : int = -1):
	return set_rand_exit_floor_at_pos(tracker.position, wall_tile)

func clear_floor_at_pos(pos : Vector2):
	return DungeonBT_node.set_floor_at_pos(pos, -1)

func set_floor_at_pos(pos : Vector2, floor_tile, wall_tile : int = -1):
	return DungeonBT_node.set_floor_at_pos(pos, floor_tile, wall_tile)

func set_rand_breakable_floor_at_pos(pos : Vector2, wall_tile : int = -1):
	var floor_tile = DungeonBT_node.get_random_breakable_tile_index()
	if DungeonBT_node.is_tile_placeable(floor_tile):
		return DungeonBT_node.set_floor_at_pos(pos, floor_tile, wall_tile)
	return false

func set_rand_safe_floor_at_pos(pos : Vector2, wall_tile : int = -1):
	var floor_tile = DungeonBT_node.get_random_safe_tile_index()
	if DungeonBT_node.is_tile_placeable(floor_tile):
		return DungeonBT_node.set_floor_at_pos(pos, floor_tile, wall_tile)
	return false

func set_rand_exit_floor_at_pos(pos : Vector2, wall_tile : int = -1):
	var floor_tile = DungeonBT_node.get_random_exit_tile_index()
	if DungeonBT_node.is_tile_placeable(floor_tile):
		return DungeonBT_node.set_floor_at_pos(pos, floor_tile, wall_tile)
	return false

func set_rand_breakable_floor(x : int, y : int, wall_tile : int = -1):
	var floor_tile = DungeonBT_node.get_random_breakable_tile_index()
	if DungeonBT_node.is_tile_placeable(floor_tile):
		return DungeonBT_node.set_floor(x, y, floor_tile, wall_tile)
	return false

func set_rand_safe_floor(x : int, y : int, wall_tile : int = -1):
	var floor_tile = DungeonBT_node.get_random_safe_tile_index()
	if DungeonBT_node.is_tile_placeable(floor_tile):
		return DungeonBT_node.set_floor(x, y, floor_tile, wall_tile)
	return false

func clear_floor(x : int, y : int):
	return DungeonBT_node.set_floor(x, y, -1)


func set_ghost_rand_breakable_at_pos(pos: Vector2):
	var tile_id = DungeonBT_node.get_random_breakable_tile_index()
	return set_ghost_tile_at_pos(pos, tile_id)

func set_ghost_rand_breakable_at_tracker():
	return set_ghost_rand_breakable_at_pos(tracker.position)

func set_ghost_rand_safe_at_pos(pos: Vector2):
	var tile_id = DungeonBT_node.get_random_safe_tile_index()
	return set_ghost_tile_at_pos(pos, tile_id)

func set_ghost_rand_safe_at_tracker():
	return set_ghost_rand_safe_at_pos(tracker.position)

func set_ghost_rand_exit_at_pos(pos: Vector2):
	var tile_id = DungeonBT_node.get_random_exit_tile_index()
	return set_ghost_tile_at_pos(pos, tile_id)

func set_ghost_rand_exit_at_tracker():
	return set_ghost_rand_exit_at_pos(tracker.position)

func set_ghost_tile_at_pos(pos: Vector2, tile_id):
	if DungeonBT_node.is_tile_placeable(tile_id):
		return DungeonBT_node.set_ghost_tile_at_pos(pos, tile_id)
	return false

func set_ghost_tile_at_tracker(tile_id):
	if DungeonBT_node.is_tile_placeable(tile_id):
		return DungeonBT_node.set_ghost_tile_at_pos(tracker.position, tile_id)
	return false

func set_ghost_tile(x: int, y: int, tile_id):
	if DungeonBT_node.is_tile_placeable(tile_id):
		return DungeonBT_node.set_ghost_tile(x, y, tile_id)
	return false

func clear_ghost_tiles():
	DungeonBT_node.clear_ghost_tiles()

func insert_entity_at_tracker(entity_name : String) -> void:
	insert_entity_at_pos(tracker.position, entity_name)

func insert_entity_at_pos(pos : Vector2, entity_name : String) -> void:
	pass

func clearMapData():
	isRoyal = false
	DungeonBT_node.reset()
	position_player_start_to(Vector2(0, 8))
	position_tracker_to(Vector2(0,8))
	set_camera_position_to(Vector2(0, 8))
	dungeon_name = ""
	engineer_name = ""
	dungeon_collapse_timer = 0.0
	dungeon_timer_autostart = true
	tile_break_time = 1.0
	tile_break_variance = 0.2
	gold_amount = 0
	gold_seed = ""
	emit_signal("floor_changed", 0)

func regen_gold():
	DungeonBT_node.generate_dungeon_gold()

func generateMapData():
	if not isRoyal:
		return DungeonBT_node.generateMapData()
	return null

func buildMapFromData(data):
	DungeonBT_node.buildMapFromData(data)
	emit_signal("floor_changed", DungeonBT_node.get_floor_count())
