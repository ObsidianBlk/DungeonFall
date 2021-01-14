extends Node2D

var camera_node = null
onready var map_node = $Map
onready var cam_container_node = $Camera_Container

func _ready():
	print("I'm the editor level!!")

func attach_camera(camera : Node2D):
	if camera_node != null:
		return
	camera_node = camera
	cam_container_node.add_child(camera)

func clear_floor_at_pos(pos : Vector2):
	return map_node.set_floor_at_pos(pos, -1)

func set_rand_breakable_floor_at_pos(pos : Vector2, wall_tile : int = -1):
	var floor_tile = map_node.get_random_breakable_tile_index()
	if floor_tile >= 0:
		return map_node.set_floor_at_pos(pos, floor_tile, wall_tile)
	return false

func set_rand_safe_floor_at_pos(pos : Vector2, wall_tile : int = -1):
	var floor_tile = map_node.get_random_safe_tile_index()
	if floor_tile >= 0:
		return map_node.set_floor_at_pos(pos, floor_tile, wall_tile)
	return false

func set_rand_breakable_floor(x : int, y : int, wall_tile : int = -1):
	var floor_tile = map_node.get_random_breakable_tile_index()
	if floor_tile >= 0:
		return map_node.set_floor(x, y, floor_tile, wall_tile)
	return false

func set_rand_safe_floor(x : int, y : int, wall_tile : int = -1):
	var floor_tile = map_node.get_random_safe_tile_index()
	if floor_tile >= 0:
		return map_node.set_floor(x, y, floor_tile, wall_tile)
	return false

func clear_floor(x : int, y : int):
	return map_node.set_floor(x, y, -1)
