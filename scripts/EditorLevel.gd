extends Node2D

# TODO: Do these *really* need to be Export variables.
export var level_name : String = "Level"
export var level_max_timer : float = 0.0
export var level_timer_autostart : bool = true
export var tile_break_time : float = 1.0 setget _set_tile_break_time
export var tile_break_variance : float = 0.2 setget _set_tile_break_variance

var camera_node = null
var cell = Vector2(16.0, 16.0)

onready var mapBT_node = $MapBuildTools
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


func _ready():
	pass
	#TilesetStore.connect("tileset_activated", self, "_on_tileset_activated")
	#set_tileset_name(TilesetStore.get_active_tileset_name())


func player_start_to_tracker():
	player_start.position = tracker.position + (cell * 0.5)
	
	var tindex = mapBT_node.get_floor_at_pos(player_start.position)
	if tindex >= 0:
		if mapBT_node.is_tile_breakable(tindex):
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
	return mapBT_node.set_floor_at_pos(tracker.position, -1)

func set_floor_at_tracker(floor_tile, wall_tile : int = -1):
	return mapBT_node.set_floor_at_pos(tracker.position, floor_tile, wall_tile)

func set_rand_breakable_floor_at_tracker(wall_tile : int = -1):
	return set_rand_breakable_floor_at_pos(tracker.position, wall_tile)

func set_rand_safe_floor_at_tracker(wall_tile: int = -1):
	return set_rand_safe_floor_at_pos(tracker.position, wall_tile)

func set_rand_exit_floor_at_tracker(wall_tile : int = -1):
	return set_rand_exit_floor_at_pos(tracker.position, wall_tile)

func clear_floor_at_pos(pos : Vector2):
	return mapBT_node.set_floor_at_pos(pos, -1)

func set_floor_at_pos(pos : Vector2, floor_tile, wall_tile : int = -1):
	return mapBT_node.set_floor_at_pos(pos, floor_tile, wall_tile)

func set_rand_breakable_floor_at_pos(pos : Vector2, wall_tile : int = -1):
	var floor_tile = mapBT_node.get_random_breakable_tile_index()
	if mapBT_node.is_tile_placeable(floor_tile):
		return mapBT_node.set_floor_at_pos(pos, floor_tile, wall_tile)
	return false

func set_rand_safe_floor_at_pos(pos : Vector2, wall_tile : int = -1):
	var floor_tile = mapBT_node.get_random_safe_tile_index()
	if mapBT_node.is_tile_placeable(floor_tile):
		return mapBT_node.set_floor_at_pos(pos, floor_tile, wall_tile)
	return false

func set_rand_exit_floor_at_pos(pos : Vector2, wall_tile : int = -1):
	var floor_tile = mapBT_node.get_random_exit_tile_index()
	if mapBT_node.is_tile_placeable(floor_tile):
		return mapBT_node.set_floor_at_pos(pos, floor_tile, wall_tile)
	return false

func set_rand_breakable_floor(x : int, y : int, wall_tile : int = -1):
	var floor_tile = mapBT_node.get_random_breakable_tile_index()
	if mapBT_node.is_tile_placeable(floor_tile):
		return mapBT_node.set_floor(x, y, floor_tile, wall_tile)
	return false

func set_rand_safe_floor(x : int, y : int, wall_tile : int = -1):
	var floor_tile = mapBT_node.get_random_safe_tile_index()
	if mapBT_node.is_tile_placeable(floor_tile):
		return mapBT_node.set_floor(x, y, floor_tile, wall_tile)
	return false

func clear_floor(x : int, y : int):
	return mapBT_node.set_floor(x, y, -1)


func set_ghost_rand_breakable_at_pos(pos: Vector2):
	var tile_id = mapBT_node.get_random_breakable_tile_index()
	return set_ghost_tile_at_pos(pos, tile_id)

func set_ghost_rand_breakable_at_tracker():
	return set_ghost_rand_breakable_at_pos(tracker.position)

func set_ghost_rand_safe_at_pos(pos: Vector2):
	var tile_id = mapBT_node.get_random_safe_tile_index()
	return set_ghost_tile_at_pos(pos, tile_id)

func set_ghost_rand_safe_at_tracker():
	return set_ghost_rand_safe_at_pos(tracker.position)

func set_ghost_rand_exit_at_pos(pos: Vector2):
	var tile_id = mapBT_node.get_random_exit_tile_index()
	return set_ghost_tile_at_pos(pos, tile_id)

func set_ghost_rand_exit_at_tracker():
	return set_ghost_rand_exit_at_pos(tracker.position)

func set_ghost_tile_at_pos(pos: Vector2, tile_id):
	if mapBT_node.is_tile_placeable(tile_id):
		return mapBT_node.set_ghost_tile_at_pos(pos, tile_id)
	return false

func set_ghost_tile_at_tracker(tile_id):
	if mapBT_node.is_tile_placeable(tile_id):
		return mapBT_node.set_ghost_tile_at_pos(tracker.position, tile_id)
	return false

func set_ghost_tile(x: int, y: int, tile_id):
	if mapBT_node.is_tile_placeable(tile_id):
		return mapBT_node.set_ghost_tile(x, y, tile_id)
	return false

func clear_ghost_tiles():
	mapBT_node.clear_ghost_tiles()


func generateMapData():
	return mapBT_node.generateMapData()

func buildMapFromData(data):
	mapBT_node.buildMapFromData(data)
