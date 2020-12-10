extends Node2D
#class_name DFLevel


export var level_name : String = "Level"
export var collapsing_floor_map : NodePath = ""
export var player_container_path : NodePath = ""
export var camera_container_path : NodePath = ""
export var player_start_path : NodePath = ""


var player_node : Node2D = null
var camera_node : Node2D = null

func _ready():
	pass # Replace with function body.

func _swap_to_container(container : Node2D, obj : Node2D):
	var parent = obj.get_parent()
	parent.remove_child(obj)
	container.add_child(obj)

func _connect_camera_to_player():
	if player_node != null and camera_node != null:
		camera_node.target_node_path = player_node.get_path()

func attach_player(player : Node2D):
	if player_node != null:
		return
	if player_container_path == null or collapsing_floor_map == null or player_start_path == null:
		return

	var container = get_node(player_container_path)
	var map = get_node(collapsing_floor_map)
	var player_start = get_node(player_start_path)
	if container != null and map != null and player_start != null:
		player_node = player
		_swap_to_container(container, player)
		player.global_position = player_start.global_position
		player.map_node_path = self.get_path()
		map.set_player(player)
		_connect_camera_to_player()

func detach_player_to(container : Node2D):
	if player_node == null:
		return
	
	if camera_node != null:
		camera_node.target_node_path = ""

	_swap_to_container(container, player_node)
	player_node.map_node_path = ""
	player_node = null

func attach_camera(camera : Node2D):
	if camera_node != null:
		return

	var container = get_node(camera_container_path)
	if container != null:
		camera_node = camera
		_swap_to_container(container, camera)
		_connect_camera_to_player()

func detach_camera_to(container : Node2D):
	if camera_node == null:
		return
	
	camera_node.target_node_path = ""
	_swap_to_container(container, camera_node)
	camera_node = null


func is_over_pit(pos : Vector2):
	var mpos = $TileMap.world_to_map(pos)
	var tindex = $TileMap.get_cellv(mpos)
	return tindex < 0

	
