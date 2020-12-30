extends Node2D
#class_name DFLevel


signal end_of_run
signal level_exit(next_level_info)
signal play_timer_changed(tim_val)
signal level_timer_changed(time_val)
signal point_update(point_val)


export var level_name : String = "Level"
export var level_max_timer : float = 0.0
export var level_timer_autostart : bool = true
export var is_last_level : bool = false
export var next_level_path : String = ""
export var next_level_proceedural : bool = false
export var next_level_seed : int = 0
export var next_level_seed_random : bool = false
export var map_node_path : NodePath = ""
export var player_container_node_path : NodePath = ""
export var camera_container_node_path : NodePath = ""
export var player_start_path : NodePath = ""


var start_pos = null
var player_node : Node2D = null
var camera_node : Node2D = null

var timer_started = false
var play_timer = 0.0
var last_play_timer = ""
var last_level_timer = ""
var collpased = false

var points = 0


func _ready():
	var map = get_node(map_node_path)
	if map != null:
		map.connect("pickup", self, "_on_pickup")
	emit_signal("point_update", points)
	emit_signal("play_timer_changed", play_timer)
	if level_max_timer > 0.0:
		emit_signal("level_timer_changed", level_max_timer - play_timer)
	else:
		emit_signal("level_timer_changed", 0)
	timer_started = level_timer_autostart

func _physics_process(delta):
	if timer_started:
		play_timer += delta
		var new_play_timer = str(play_timer).pad_decimals(2)
		if new_play_timer != last_play_timer:
			last_play_timer = new_play_timer
			emit_signal("play_timer_changed", play_timer)
		if level_max_timer > 0.0 and not collpased:
			if level_max_timer - play_timer <= 0.0:
				collpased = true
				emit_signal("level_timer_changed", 0.0)
				print("Collapse the floors!")
				var map = get_node(map_node_path)
				if map != null:
					map._collapse_level()
			else:
				var new_level_timer = str(level_max_timer - play_timer).pad_decimals(2)
				if new_level_timer != last_level_timer:
					last_level_timer = new_level_timer
					emit_signal("level_timer_changed", level_max_timer - play_timer)
	elif start_pos != null:
		if start_pos != player_node.global_position or player_node.inair:
			timer_started = true


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
	if player_start_path == null:
		return

	var map = get_node(map_node_path)
	if map == null:
		return

	var container = get_node(player_container_node_path)
	var player_start = get_node(player_start_path)
	
	if container != null and player_start != null:
		player_node = player
		start_pos = player_start.global_position
		_swap_to_container(container, player)
		player.global_position = start_pos
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
	
	var container = get_node(camera_container_node_path)
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


func is_over_pit(pos : Vector2, footprint : int = 0):
	if map_node_path != "":
		var map = get_node(map_node_path)
		if map != null:
			return map._is_over_pit(pos, footprint)
	return false


func exit_level():
	if is_last_level:
		emit_signal("end_of_run")
	else:
		var level_seed = next_level_seed
		if next_level_proceedural and next_level_seed_random:
			level_seed = randi()
		
		# TODO: Create singleton which will generate this object block from parameters.
		var info = {
			"src": next_level_path,
			"proceedural": next_level_proceedural,
			"seed": level_seed
		}
		emit_signal("level_exit", info)
	set_physics_process(false)
	
func _on_pickup():
	points += 1
	emit_signal("point_update", points)
