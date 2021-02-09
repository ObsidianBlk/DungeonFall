extends Node2D

var camera_node = null
var cell = Vector2(16.0, 16.0)

onready var mapBT_node = $MapBuildTools
onready var walls_node = $Walls
onready var cam_container_node = $Camera_Container
onready var tracker = $Tracker

func _ready():
	pass
	#TilesetStore.connect("tileset_activated", self, "_on_tileset_activated")
	#set_tileset_name(TilesetStore.get_active_tileset_name())


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

func set_floor_at_tracker(floor_tile : int, wall_tile : int = -1):
	mapBT_node.set_floor_at_pos(tracker.position, floor_tile, wall_tile)

func set_rand_breakable_floor_at_tracker(wall_tile : int = -1):
	return set_rand_breakable_floor_at_pos(tracker.position, wall_tile)

func set_rand_safe_floor_at_tracker(wall_tile: int = -1):
	return set_rand_safe_floor_at_pos(tracker.position, wall_tile)

func set_rand_exit_floor_at_tracker(wall_tile : int = -1):
	return set_rand_exit_floor_at_pos(tracker.position, wall_tile)

func clear_floor_at_pos(pos : Vector2):
	return mapBT_node.set_floor_at_pos(pos, -1)

func set_floor_at_pos(pos : Vector2, floor_tile : int, wall_tile : int = -1):
	return mapBT_node.set_floor_at_pos(pos, floor_tile, wall_tile)

func set_rand_breakable_floor_at_pos(pos : Vector2, wall_tile : int = -1):
	var floor_tile = mapBT_node.get_random_breakable_tile_index()
	if floor_tile >= 0:
		return mapBT_node.set_floor_at_pos(pos, floor_tile, wall_tile)
	return false

func set_rand_safe_floor_at_pos(pos : Vector2, wall_tile : int = -1):
	var floor_tile = mapBT_node.get_random_safe_tile_index()
	if floor_tile >= 0:
		return mapBT_node.set_floor_at_pos(pos, floor_tile, wall_tile)
	return false

func set_rand_exit_floor_at_pos(pos : Vector2, wall_tile : int = -1):
	var floor_tile = mapBT_node.get_random_exit_tile_index()
	if floor_tile >= 0:
		return mapBT_node.set_floor_at_pos(pos, floor_tile, wall_tile)
	return false

func set_rand_breakable_floor(x : int, y : int, wall_tile : int = -1):
	var floor_tile = mapBT_node.get_random_breakable_tile_index()
	if floor_tile >= 0:
		return mapBT_node.set_floor(x, y, floor_tile, wall_tile)
	return false

func set_rand_safe_floor(x : int, y : int, wall_tile : int = -1):
	var floor_tile = mapBT_node.get_random_safe_tile_index()
	if floor_tile >= 0:
		return mapBT_node.set_floor(x, y, floor_tile, wall_tile)
	return false

func clear_floor(x : int, y : int):
	return mapBT_node.set_floor(x, y, -1)
