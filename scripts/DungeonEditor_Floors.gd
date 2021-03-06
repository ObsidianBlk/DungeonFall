extends Node

var dungeonlevel_node = null

var active_floor_type = "B"
var floor_tile_id = -1
var rand_floor = false
var active = false
var clear = false


func set_editordungeon_node(lenode : Node):
	dungeonlevel_node = lenode

func set_active_floor_type(type):
	if type == "B" or type == "S" or type == "E":
		active_floor_type = type

func set_active_tile_id(id):
	if typeof(id) == TYPE_STRING:
		if id == "":
			floor_tile_id = -1
		else:
			floor_tile_id = id
	else:
		if id < 0:
			floor_tile_id = -1
		else:
			floor_tile_id = id

func set_random_tile(enable : bool = true):
	rand_floor = enable

func is_random_tiles():
	return rand_floor

func _handleInput(event):
	if event is InputEventMouseButton:
		if event.is_action_pressed("MapEditor_MousePlace"):
			active = true
			clear = false
			get_parent().reset_repeater()
		if event.is_action_pressed("MapEditor_MouseClear"):
			active = true
			clear = true
			get_parent().reset_repeater()
		if event.is_action_released("MapEditor_MousePlace") or event.is_action_released("MapEditor_MouseClear"):
			active = false
			clear = false
	else:
		if event.is_action_pressed("ui_select"):
			active = true
			clear = false
			get_parent().reset_repeater()
		if event.is_action_pressed("ui_deselect"):
			active = true
			clear = true
			get_parent().reset_repeater()
		if event.is_action_released("ui_select") or event.is_action_released("ui_deselect"):
			active = false
			clear = false

func _updateProcess(delta):
	if active:
		dungeonlevel_node.clear_ghost_tiles()
		_updateFloor(clear)
	else:
		_updateGhost()


func _floorTileIDPlaceable():
	if typeof(floor_tile_id) == TYPE_STRING:
		if floor_tile_id != "":
			return true
	if floor_tile_id >= 0:
		return true
	return false

func _updateFloor(clear : bool = false):
	if dungeonlevel_node != null:
		if clear:
			dungeonlevel_node.clear_floor_at_tracker()
		elif rand_floor or not _floorTileIDPlaceable():
			match(active_floor_type):
				"B":
					dungeonlevel_node.set_rand_breakable_floor_at_tracker()
				"S":
					dungeonlevel_node.set_rand_safe_floor_at_tracker()
				"E":
					dungeonlevel_node.set_rand_exit_floor_at_tracker()
		else:
			dungeonlevel_node.set_floor_at_tracker(floor_tile_id)


func _updateGhost():
	if dungeonlevel_node != null:
		if rand_floor or not _floorTileIDPlaceable():
			match(active_floor_type):
				"B":
					dungeonlevel_node.set_ghost_rand_breakable_at_tracker()
				"S":
					dungeonlevel_node.set_ghost_rand_safe_at_tracker()
				"E":
					dungeonlevel_node.set_ghost_rand_exit_at_tracker()
		else:
			dungeonlevel_node.set_ghost_tile_at_tracker(floor_tile_id)
