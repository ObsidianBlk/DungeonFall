extends Node2D

var camera_node = null
var cell = Vector2(16.0, 16.0)

#onready var map_node = $Map
onready var mapCTRL_node = $MapCTRL
onready var mapBT_node = $MapBuildTools
onready var walls_node = $Walls
onready var cam_container_node = $Camera_Container
onready var tracker = $Tracker

func _ready():
	pass
	#TilesetStore.connect("tileset_activated", self, "_on_tileset_activated")
	#set_tileset_name(TilesetStore.get_active_tileset_name())

func _input(event):
	if event.is_action_pressed("move_left"):
		tracker.position.x -= cell.x
	if event.is_action_pressed("move_right"):
		tracker.position.x += cell.x
	if event.is_action_pressed("move_up"):
		tracker.position.y -= cell.y
	if event.is_action_pressed("move_down"):
		tracker.position.y += cell.y


#func _on_tileset_activated(def):
#	set_tileset_name(def.name)


#func set_tileset_name(name : String):
#	map_node.tileset_name = name
#	if map_node.is_valid():
#		cell = walls_node.cell_size
#		return true
#	return false

func attach_camera(camera : Node2D):
	if camera_node != null:
		return
	camera_node = camera
	var parent = camera.get_parent()
	parent.remove_child(camera)
	cam_container_node.add_child(camera)
	camera.target_node_path = camera.get_path_to(tracker)
	camera.current = true

func detach_camera_to_container(container : Node2D):
	if camera_node != null:
		camera_node.current = false
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
