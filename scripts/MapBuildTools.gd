tool
extends Node2D

export var map_seed : int = 0
export var clear_on_new_tileset : bool = true

var ready = false
var tileset_def = null
var RNG = null

var breakable_tile_resources = {}

onready var floors_map = get_parent().get_node("Floors")
onready var walls_map = get_parent().get_node("Walls")
onready var doors_map = get_parent().get_node("Doors")


func _ready():
	ready = true
	# Connect to TilesetStore...
	TilesetStore.connect("tile_defs_scanned", self, "_on_tile_def_scanned")
	TilesetStore.connect("tileset_activated", self, "_on_tileset_activated")
	
	reset_rng()
	tileset_def = TilesetStore.get_definition()


func _set_tilemaps_tileset(res : Resource):
	if walls_map.tile_set != res:
		if clear_on_new_tileset:
			walls_map.clear()
		walls_map.tile_set = res
	
	if floors_map.tile_set != res:
		if clear_on_new_tileset:
			floors_map.clear()
		floors_map.tile_set = res
	
	if doors_map.tile_set != res:
		if clear_on_new_tileset:
			doors_map.clear()
		doors_map.tile_set = res


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


# -----------------------------------------------------------------------------
# "PUBLIC" METHODS

func is_valid():
	return tileset_def != null

func reset_rng():
	RNG = RandomNumberGenerator.new()
	RNG.seed = map_seed

func set_tileset_definition(def):
	if not TilesetStore.has_tileset(def.name):
		return

	if tileset_def == null or def.name != tileset_def.name:
		if tileset_def != null:
			breakable_tile_resources = {}
		var res = load(def.base_path + def.resource_path)
		if res:
			tileset_def = def
			_set_tilemaps_tileset(res)


func is_tile_breakable(tindex : int):
	if is_valid():
		for i in range(0, tileset_def.floors.breakable.size()):
			if tileset_def.floors.breakable[i].index == tindex:
				return true
	return false

func is_tile_safe(tindex : int):
	if is_valid():
		return tileset_def.floors.safe.has(float(tindex))
	return false

func is_tile_exit(tindex : int):
	if is_valid():
		return tileset_def.floors.exit.has(float(tindex))
	return false

func is_tile_wall(tindex : int):
	if is_valid():
		return tileset_def.walls.has(tindex)
	return false

func get_breakable_tile_resource(tindex : int):
	if is_valid():
		for i in range(0, tileset_def.floors.breakable.size()):
			if tileset_def.floors.breakable[i].index == tindex:
				var res_path = tileset_def.floors.breakable[i].sprite_src
				if res_path in breakable_tile_resources:
					return breakable_tile_resources[res_path]
				else:
					var btr = load(tileset_def.base_path + res_path)
					if btr:
						breakable_tile_resources[res_path] = btr
						return btr
	return null

func get_cell_size():
	if tileset_def == null:
		return -1
	return tileset_def.size

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

func clearTileMaps():
	walls_map.clear()
	floors_map.clear()
	doors_map.clear()


func set_floor_at_pos(pos : Vector2, floor_tile : int, wall_tile : int = -1):
	pos = floors_map.world_to_map(pos)
	return set_floor(floor(pos.x), floor(pos.y), floor_tile, wall_tile)

func set_floor(x : int, y : int, floor_tile : int, wall_tile : int = -1):
	if not is_valid():
		return false
	if floor_tile >= 0 and not (is_tile_breakable(floor_tile) or is_tile_safe(floor_tile) or is_tile_exit(floor_tile)):
		return false
	elif floor_tile < 0:
		floor_tile = -1
	if wall_tile >= 0 and not is_tile_wall(wall_tile):
		return false
	elif wall_tile < 0:
		wall_tile = tileset_def.walls[0]
	
	floors_map.set_cell(x, y, floor_tile)
	_recalculate_walls(wall_tile)



# -----------------------------------------------------------------------------
# EVENT HANDLERS

func _on_tile_def_scanned():
	if not TilesetStore.has_tileset(tileset_def.name):
		if clear_on_new_tileset:
			clearTileMaps()
		tileset_def = null

func _on_tileset_activated(def):
	set_tileset_definition(def)
			


