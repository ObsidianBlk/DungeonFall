extends Node2D

var camera_node = null
var cell = Vector2(16.0, 16.0)
onready var map_node = $Map
onready var cam_container_node = $Camera_Container
onready var tracker = $Tracker

func _ready():
	print("I'm the editor level!!")

func _input(event):
	if event.is_action("move_left"):
		tracker.position.x -= cell.x
	if event.is_action("move_right"):
		tracker.position.x += cell.x
	if event.is_action("move_up"):
		tracker.position.y -= cell.y
	if event.is_action("move_down"):
		tracker.position.y += cell.y

func _process(delta):
	update()

func _draw():
	var x = floor(tracker.position.x / cell.x) * cell.x
	var y = floor(tracker.position.y / cell.y) * cell.y
	var rect = Rect2(x, y, cell.x, cell.y)
	draw_rect(rect, Color(1.0, 0.0, 0.0, 0.5), false, 1.0)

func set_tileset_name(name : String):
	$Map.tileset_name = name
	if $Map.is_valid():
		cell = $Walls.cell_size
		return true
	return false

func attach_camera(camera : Node2D):
	if camera_node != null:
		return
	camera_node = camera
	cam_container_node.add_child(camera)
	camera.target_node_path = camera.get_path_to(tracker)

func detach_camera_to_container(container : Node2D):
	if camera_node != null:
		cam_container_node.remove_child(camera_node)
		container.add_child(camera_node)
		camera_node = null

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
