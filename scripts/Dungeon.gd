extends Node2D

signal end_of_run
signal level_exit(next_level_info)
signal play_timer_changed(tim_val)
signal level_timer_changed(time_val)
signal open_exits
signal point_update(point_val)

# Map configuration options
export var dungeon_name : String = "Level"
export var engineer_name : String = ""
export var dungeon_collapse_timer : float = 0.0
export var dungeon_timer_autostart : bool = true
export var tile_break_time : float = 1.0 setget _set_tile_break_time
export var tile_break_variance : float = 0.2 setget _set_tile_break_variance
export var gold_amount : int = 0 setget _set_gold_amount
export var gold_seed : String = ""

# "Next" Map loading/selection/generation options
export var is_last_level : bool = false
export var next_level_path : String = ""
export var next_level_proceedural : bool = false
export var next_level_seed : int = 0
export var next_level_seed_random : bool = false

# Do I even need these now?!?!?!
export var player_container_node_path : NodePath = ""
export var camera_container_node_path : NodePath = ""
export var player_start_path : NodePath = ""


var ready = false
var isRoyal = false
var started_exit_areas = false
var map_data = null

var start_pos = null
var player_node : Node2D = null
var camera_node : Node2D = null

var timer_started = false
var play_timer = 0.0
var last_play_timer = ""
var last_dungeon_timer = ""
var collpased = false

var points = 0

onready var dungeonBT_node = $DungeonBuildTools
onready var dungeonCTRL = $DungeonCTRL


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
	if a >= 0:
		gold_amount = a

func _ready():
	ready = true
	if map_data != null:
		_build_from_data(map_data)
		map_data = null
	
	dungeonCTRL.connect("pickup", self, "_on_pickup")
	emit_signal("point_update", points)
	emit_signal("play_timer_changed", play_timer)
	if dungeon_collapse_timer > 0.0:
		emit_signal("level_timer_changed", dungeon_collapse_timer - play_timer)
	else:
		emit_signal("level_timer_changed", 0)
	timer_started = dungeon_timer_autostart
	


func _physics_process(delta):
	if player_node == null or camera_node == null:
		return

	if timer_started:
		play_timer += delta
		var new_play_timer = str(play_timer).pad_decimals(2)
		if new_play_timer != last_play_timer:
			last_play_timer = new_play_timer
			emit_signal("play_timer_changed", play_timer)
		if dungeon_collapse_timer > 0.0 and not collpased:
			if dungeon_collapse_timer - play_timer <= 0.0:
				collpased = true
				emit_signal("level_timer_changed", 0.0)
				#print("Collapse the floors!")
				dungeonCTRL._collapse_level()
			else:
				var new_dungeon_timer = str(dungeon_collapse_timer - play_timer).pad_decimals(2)
				if new_dungeon_timer != last_dungeon_timer:
					last_dungeon_timer = new_dungeon_timer
					emit_signal("level_timer_changed", dungeon_collapse_timer - play_timer)
	elif start_pos != null:
		if start_pos != player_node.global_position or player_node.inair:
			timer_started = true
	
	if not started_exit_areas and start_pos != player_node.global_position:
		started_exit_areas = true
		emit_signal("open_exits")

func _swap_to_container(container : Node2D, obj : Node2D):
	var parent = obj.get_parent()
	parent.remove_child(obj)
	container.add_child(obj)

func _connect_camera_to_player():
	if player_node != null and camera_node != null:
		camera_node.target_node_path = player_node.get_path()


func _build_from_data(data):
	dungeonBT_node.buildMapFromData(data)
	dungeonCTRL.update_gold_container()


func load_user_level(path : String):
	var data = Io.readMapData(path)
	if data:
		if ready:
			_build_from_data(data)
		else:
			map_data = data
		return true
	return false

func attach_player(player : Node2D):
	if player_node != null:
		return
	if player_start_path == null:
		return

	var container = get_node(player_container_node_path)
	var player_start = get_node(player_start_path)
	
	if container != null and player_start != null:
		start_pos = player_start.global_position
		_swap_to_container(container, player)
		player.global_position = start_pos
		player.map_node_path = self.get_path()
		dungeonCTRL.set_player(player)
		player_node = player
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

func position_player_start(x, y):
	var player_start = get_node(player_start_path)
	if !player_start:
		return
	
	var cell = $Floors.cell_size
	player_start.position = Vector2(
		(cell.x * floor(x)) + (cell.x * 0.5),
		(cell.y * floor(y)) + (cell.y * 0.5)
	)
	if player_node != null:
		player_node.global_position = player_start.global_position

func position_player_start_to(pos : Vector2):
	pos = $Floors.world_to_map(pos)
	position_player_start(pos.x, pos.y)

func is_over_pit(pos : Vector2, footprint : int = 0):
	return dungeonCTRL._is_over_pit(pos, footprint)

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
