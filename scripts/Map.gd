tool
extends Node2D


signal pickup


export var map_seed : int = 0
export (float, 0.1, 10.0) var time_to_collapse = 0.65
export var tileset_name : String = "" setget _set_tileset_name
export var clear_on_new_tileset : bool = false

var ready = false

var RNG = null

var tileset_def = null
var breakable_tile_resources = {}

var last_tile_pos = null
var tile_collapse_time = 0
var collapsing_tiles = {}

onready var floors_map = get_parent().get_node("Floors")
onready var walls_map = get_parent().get_node("Walls")
onready var doors_map = get_parent().get_node("Doors")

onready var gold_container = get_parent().get_node("Gold_Container")

var player = null


func _set_tileset_name(name : String, force : bool = false):
	if name != "":
		if tileset_def == null or tileset_def.name != name or force:
			if TilesetStore.TILESETS.has(name):
				tileset_name = name
				tileset_def = TilesetStore.TILESETS[name]
				
				if ready:
					var res = load(tileset_def.base_path + tileset_def.resource_path)
					if res:
						if walls_map.tile_set != res:
							walls_map.clear()
							walls_map.tile_set = res
						
						if floors_map.tile_set != res:
							floors_map.clear()
							floors_map.tile_set = res
						
						if doors_map.tile_set != res:
							doors_map.clear()
							doors_map.tile_set = res
	else:
		tileset_def = null
		tileset_name = ""
		if ready and clear_on_new_tileset:
			# TODO: Do I need to remove the .tile_set resource?
			walls_map.clear()
			floors_map.clear()
			doors_map.clear()


func _ready():
	ready = true
	# Setting up a seeded Random Number Generator
	reset_rng()
	
	# Connect to TilesetStore...
	TilesetStore.connect("tile_defs_scanned", self, "_on_tile_def_scanned")
	_set_tileset_name(tileset_name, true)
	
	#_set_walls_tilemap_path(walls_tilemap_path, true)
	#_set_floors_tilemap_path(floors_tilemap_path, true)
	#_set_doors_tilemap_path(doors_tilemap_path, true)
	#_set_gold_container_path(gold_container_path, true)
	if gold_container != null:
		for child in gold_container.get_children():
			child.connect("pickup", self, "_on_gold_pickup")

func is_valid():
	return tileset_def != null and tileset_def.name == tileset_name

func reset_rng():
	RNG = RandomNumberGenerator.new()
	RNG.seed = map_seed

func set_player(p : Node2D):
	player = p

func set_floor_at_pos(pos : Vector2, floor_tile : int, wall_tile : int = -1):
	pos = floors_map.world_to_map(pos)
	return set_floor(floor(pos.x), floor(pos.y), floor_tile, wall_tile)

func set_floor(x : int, y : int, floor_tile : int, wall_tile : int = -1):
	if not is_valid():
		return false
	if floor_tile >= 0 and not (_is_tile_breakable(floor_tile) or _is_tile_safe(floor_tile) or _is_tile_exit(floor_tile)):
		return false
	elif floor_tile < 0:
		floor_tile = -1
	if wall_tile >= 0 and not _is_tile_wall(wall_tile):
		return false
	elif wall_tile < 0:
		wall_tile = tileset_def.walls[0]
	
	floors_map.set_cell(x, y, floor_tile)
	_recalculate_walls(wall_tile)


func get_random_breakable_tile_index():
	if tileset_def == null:
		return -1
	var i = RNG.randi_range(0, tileset_def.floors.breakable.size() - 1)
	return tileset_def.floors.breakable[i].index

func get_random_safe_tile_index():
	if tileset_def == null:
		return -1
	var i = RNG.randi_range(0, tileset_def.floors.safe.size() - 1)
	return tileset_def.floors.safe[i]

func get_random_exit_tile_index():
	if tileset_def == null:
		return -1
	var i = RNG.randi_range(0, tileset_def.floors.exit.size() - 1)
	return tileset_def.floors.exit[i]

func _process(delta):
	if Engine.editor_hint:
		if Input.is_key_pressed(KEY_CONTROL) and Input.is_key_pressed(KEY_SHIFT) and Input.is_key_pressed(KEY_R):
			_redraw_floors()
	else:
		if floors_map != null and player != null and not player.inair:
			if player.footprint > 0:
				var px = player.position.x
				var py = player.position.y
				var fp = player.footprint
				_check_for_collapsable_tile(Vector2(px + fp, py))
				_check_for_collapsable_tile(Vector2(px - fp, py))
				_check_for_collapsable_tile(Vector2(px, py + fp))
				_check_for_collapsable_tile(Vector2(px, py - fp))
			else:
				_check_for_collapsable_tile(player.position)


func _physics_process(delta):
	if not Engine.editor_hint:
		_update_collapsing_tiles(delta)


func _is_tile_breakable(tindex : int):
	if is_valid():
		for i in range(0, tileset_def.floors.breakable.size()):
			if tileset_def.floors.breakable[i].index == tindex:
				return true
	return false

func _is_tile_safe(tindex : int):
	if is_valid():
		return tileset_def.floors.safe.has(float(tindex))
	return false

func _is_tile_exit(tindex : int):
	if is_valid():
		return tileset_def.floors.exit.has(float(tindex))
	return false

func _is_tile_wall(tindex : int):
	if is_valid():
		return tileset_def.walls.has(tindex)
	return false

func _get_breakable_tile_resource(tindex : int):
	if is_valid():
		for i in range(0, tileset_def.floors.breakable.size()):
			if tileset_def.floors.breakable[i].index == tindex:
				var res_path = tileset_def.floors.breakable[i].sprite_src
				if res_path in breakable_tile_resources:
					return breakable_tile_resources[res_path]
				else:
					# TODO: Need to get base path and combine sprite_src with base path
					var btr = load(tileset_def.base_path + res_path)
					if btr:
						breakable_tile_resources[res_path] = btr
						return btr
	return null

func _check_for_collapsable_tile(pos : Vector2):
	var mpos = floors_map.world_to_map(pos)
	var tindex = floors_map.get_cellv(mpos)
	if _is_tile_breakable(tindex):
		_set_collapsing_tile(mpos)

func _get_breakable_tile_from_map_position(mpos : Vector2):
	if floors_map != null:
		var ti = floors_map.get_cellv(mpos)
		return _get_breakable_tile_resource(ti)
	return null

func _update_collapsing_tiles(delta):
	if not is_valid() or floors_map == null:
		return
	
	var cell_size = tileset_def.size
	
	var rkeys = []
	var hcell_size = cell_size * 0.5
	for key in collapsing_tiles:
		var tpos = collapsing_tiles[key].pos
		var ttc = collapsing_tiles[key].ttc
		ttc += delta
		if ttc >= time_to_collapse:
			var breakable_tile = _get_breakable_tile_from_map_position(tpos)
			if breakable_tile != null:
				floors_map.set_cellv(tpos, -1)
				var t = breakable_tile.instance()
				t.name = "BT_" + key
				t.position = (tpos * cell_size) + Vector2(hcell_size, hcell_size)
				# TODO: Shouldn't "Collapsing" be a NodePath export variable?
				get_parent().get_node("Collapsing").add_child(t)
				rkeys.append(key)
		else:
			collapsing_tiles[key].ttc = ttc
	
	for key in rkeys:
		collapsing_tiles.erase(key)


func _fill_in_floors():
	if not is_valid():
		return
		
	for i in range(0, tileset_def.walls.size()):
		var used_cells = walls_map.get_used_cells_by_id(tileset_def.walls[i])
		for cell in used_cells:
			var atv = walls_map.get_cell_autotile_coord(cell[0], cell[1])
			if atv == Vector2(1,1):
				var findex = floors_map.get_cell(cell[0], cell[1])
				if findex < 0:
					var tindex = get_random_breakable_tile_index()
					if tindex >= 0:
						floors_map.set_cell(cell[0], cell[1], tindex)


func _recalculate_walls(wall_tile : int):
	if not is_valid():
		return
	
	walls_map.clear()
	var used_cells = floors_map.get_used_cells()
	for cell in used_cells:
		for wx in range(cell[0] - 1, cell[0] + 2):
			for wy in range(cell[1] - 1, cell[1] + 2):
				walls_map.set_cell(wx, wy, wall_tile)
	walls_map.update_bitmask_region()
	

# NOTE: Should only ever be used in the editor!
# I've been warned
func _redraw_floors():
	if not is_valid() or floors_map == null or walls_map == null:
		return
	
	for i in range(0, tileset_def.walls.size()):
		var used_cells = walls_map.get_used_cells_by_id(tileset_def.walls[i])
		for cell in used_cells:
			var atv = walls_map.get_cell_autotile_coord(cell[0], cell[1])
			if atv == Vector2(1,1):
				var tindex = get_random_breakable_tile_index()
				if tindex >= 0:
					floors_map.set_cell(cell[0], cell[1], tindex)


func _set_collapsing_tile(mpos : Vector2):
	var key = String(mpos.x) + "x" + String(mpos.y)
	if not (key in collapsing_tiles):
		collapsing_tiles[key] = {
			"pos": mpos,
			"ttc": 0
		}


func _collapse_level():
	# floors_map
	print("Collapsing the level!!")
	var floors = floors_map.get_used_cells()
	for f in floors:
		_set_collapsing_tile(f)


func _is_over_pit(pos : Vector2, footprint : int = 0):
	if floors_map == null:
		return false
	
	var result = false
	if footprint > 0:
		result = true
		for i in range(0, footprint):
			var npos1 = Vector2(pos.x + footprint, pos.y)
			var npos2 = Vector2(pos.x - footprint, pos.y)
			var npos3 = Vector2(pos.x, pos.y + footprint)
			var npos4 = Vector2(pos.x, pos.y - footprint)
			result = _is_over_pit(npos1) and _is_over_pit(npos2) and _is_over_pit(npos3) and _is_over_pit(npos4)
			if not result:
				return false
		result = _is_over_pit(pos)
	else:
		var mpos = floors_map.world_to_map(pos)
		var tindex = floors_map.get_cellv(mpos)
		if tindex < 1:
			result = true
			var key = String(mpos.x) + "x" + String(mpos.y)
			# TODO: Shouldn't "Collapsing" be a NodePath export variable?
			var ctn = get_parent().get_node("Collapsing/CT_" + key)
			if ctn != null:
				result = not ctn.is_safe()
	return result


func _on_tile_def_scanned():
	if not is_valid() and tileset_name != "":
		_set_tileset_name(tileset_name)

func _on_gold_pickup():
	emit_signal("pickup")



