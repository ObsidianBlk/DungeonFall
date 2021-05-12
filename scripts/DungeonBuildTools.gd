tool
extends Node2D

export var map_seed : int = 0
export var clear_on_new_tileset : bool = true

var ready = false
var tileset_def = null
var RNG = null

var breakable_tile_resources = {}
var dungeon_exits = []

onready var parent_node = get_parent()
onready var floors_map = get_parent().get_node("Floors")
onready var walls_map = get_parent().get_node("Walls")
onready var doors_map = get_parent().get_node("Doors")
var ghost_map = null


func _ready():
	ready = true
	# Connect to TilesetStore...
	TilesetStore.connect("tile_defs_scanned", self, "_on_tile_def_scanned")
	TilesetStore.connect("tileset_activated", self, "_on_tileset_activated")
	
	reset_rng()
	tileset_def = TilesetStore.get_definition()
	
	if parent_node.has_node("Ghost"):
		ghost_map = parent_node.get_node("Ghost")


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
	
	if ghost_map.tile_set != res:
		if clear_on_new_tileset:
			ghost_map.clear()
		ghost_map.tile_set = res


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


func _removeExitIfOverlap(einfo):
	if dungeon_exits.size() > 0:
		# TODO: Check if I can range() backwards!!!
		var i = dungeon_exits.size() - 1
		while i >= 0:
			var de = dungeon_exits[i]
			var derect = Rect2(
				de.position - (de.size * 0.5),
				de.size
			)
			
			var einforect = Rect2(
				einfo.position - (einfo.size * 0.5),
				einfo.size
			)
			
			if derect.intersects(einforect):
				dungeon_exits.remove(i)
			i -= 1


func _IDMatch(id1, id2):
	var tid1 = typeof(id1)
	var tid2 = typeof(id2)
	if tid1 == TYPE_STRING and tid1 == tid2:
		return id1 == id2
	elif (tid1 == TYPE_INT or tid1 == TYPE_REAL) and (tid2 == TYPE_INT or tid2 == TYPE_REAL):
		return int(id1) == int(id2)
	return false

# -----------------------------------------------------------------------------
# "PUBLIC" METHODS

func is_valid():
	return tileset_def != null

func reset_rng():
	RNG = RandomNumberGenerator.new()
	RNG.seed = map_seed

func reset():
	reset_rng()
	clearTileMaps()
	dungeon_exits = []


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

#func get_map_name():
#	return map_name

#func set_map_name(name : String):
#	if name != "":
#		map_name = name

func is_tile_breakable(tile_id):
	if is_valid():
		for i in range(0, tileset_def.floors.breakable.size()):
			var fi = tileset_def.floors.breakable[i].index
			if _IDMatch(fi, tile_id):
				if fi == tile_id:
					return true
	return false

func is_tile_safe(tile_id):
	if is_valid():
		for i in range(0, tileset_def.floors.safe.size()):
			var si = tileset_def.floors.safe[i]
			if _IDMatch(si, tile_id):
				if si == tile_id:
					return true
	return false

func is_tile_exit(tile_id):
	if is_valid():
		for i in range(0, tileset_def.floors.exit.size()):
			var ei = tileset_def.floors.exit[i]
			if _IDMatch(ei, tile_id):
				if ei == tile_id:
					return true
	return false

func is_tile_placeable(tile_id):
	return is_tile_breakable(tile_id) or is_tile_safe(tile_id) or is_tile_exit(tile_id)

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


func set_floor_at_pos(pos : Vector2, floor_tile, wall_tile : int = -1):
	pos = floors_map.world_to_map(pos)
	return set_floor(int(floor(pos.x)), int(floor(pos.y)), floor_tile, wall_tile)

func set_floor(x : int, y : int, floor_tile, wall_tile : int = -1, no_exit_info = false):
	if not is_valid():
		return false
		
	if typeof(floor_tile) == TYPE_STRING:
		if floor_tile != "" and not (is_tile_breakable(floor_tile) or is_tile_safe(floor_tile) or is_tile_exit(floor_tile)):
			return false
		elif floor_tile == "":
			floor_tile = -1
	else:
		if floor_tile >= 0 and not (is_tile_breakable(floor_tile) or is_tile_safe(floor_tile) or is_tile_exit(floor_tile)):
			return false
		elif floor_tile < 0:
			floor_tile = -1
		
	if wall_tile >= 0 and not is_tile_wall(wall_tile):
		return false
	elif wall_tile < 0:
		wall_tile = tileset_def.walls[0]
	
	if typeof(floor_tile) == TYPE_STRING:
		var size = TilesetStore.get_meta_size(tileset_def, floor_tile)
		var tiles = TilesetStore.get_meta_tiles(tileset_def, floor_tile)
		if tiles.size() > 0 and tiles.size() == (floor(size.x) * floor(size.y)):
			for ty in range(0, floor(size.y)):
				for tx in range(0, floor(size.x)):
					var tileid = tiles[(ty*floor(size.x))+tx];
					if tileid >= 0:
						floors_map.set_cell(x + tx, y + ty, tileid)
					else:
						floors_map.set_cell(x + tx, y + ty, -1)
			var einfo = TilesetStore.get_meta_exit_info(tileset_def, floor_tile, x, y)
			_removeExitIfOverlap(einfo)
			if is_tile_exit(floor_tile):
				if einfo != null:
					dungeon_exits.append(einfo)
		else:
			print("ERROR: Failed to set meta tile '", floor_tile, "'. Size does not match given tiles.")
	else:
		floors_map.set_cell(x, y, floor_tile)
		var einfo = {
			"position": Vector2(
				(x * tileset_def.size) + (floors_map.cell_size.x * 0.5),
				(y * tileset_def.size) + (floors_map.cell_size.y * 0.5)
			),
			"type": "circle",
			"size": floors_map.cell_size * 0.5
		}
		_removeExitIfOverlap(einfo)
		if no_exit_info == false and is_tile_exit(floor_tile):
			dungeon_exits.append(einfo)
	
	_recalculate_walls(wall_tile)
	return true

func get_floor_at_pos(pos : Vector2):
	pos = floors_map.world_to_map(pos)
	return get_floor(int(floor(pos.x)), int(floor(pos.y)))

func get_floor(x : int, y : int):
	if not is_valid():
		return -1
	return floors_map.get_cell(x, y)


func set_ghost_tile_at_pos(pos: Vector2, tile_id):
	pos = ghost_map.world_to_map(pos)
	return set_ghost_tile(int(floor(pos.x)), int(floor(pos.y)), tile_id)

func set_ghost_tile(x: int, y: int, tile_id):
	if not is_valid():
		return false
	
	if typeof(tile_id) == TYPE_STRING:
		if tile_id == "":
			tile_id = -1
	else:
		if tile_id < 0:
			tile_id = -1
	
	ghost_map.clear()
	if typeof(tile_id) == TYPE_STRING:
		var size = TilesetStore.get_meta_size(tileset_def, tile_id)
		var tiles = TilesetStore.get_meta_tiles(tileset_def, tile_id)
		if tiles.size() > 0 and tiles.size() == (floor(size.x) * floor(size.y)):
			for ty in range(0, floor(size.y)):
				for tx in range(0, floor(size.x)):
					var tileid = tiles[(ty*floor(size.x))+tx];
					if tileid >= 0:
						ghost_map.set_cell(x + tx, y + ty, tileid)
		else:
			print("ERROR: Failed to set meta tile '", tile_id, "'. Size does not match given tiles.")
	else:
		ghost_map.set_cell(x, y, tile_id)
	
	return true

func clear_ghost_tiles():
	ghost_map.clear()



func generateMapData():
	var player_start = parent_node.get_node("Player_Start")
	if not player_start:
		return
		
	var data = {
		"name": parent_node.dungeon_name,
		"engineer": parent_node.engineer_name,
		"version": [0,1,1],
		"map":{
			"tileset_name": tileset_def.name,
			"player_start": player_start.position,
			"timer_autostart": parent_node.dungeon_timer_autostart,
			"collapse_timer": parent_node.dungeon_collapse_timer,
			"tile_break_time": parent_node.tile_break_time,
			"tile_break_variance": parent_node.tile_break_variance,
			"floors": [],
			"walls": [],
			"exits": null
		}
	}
	
	# Storing Floor Tiles
	var tiles = floors_map.get_used_cells()
	for i in range(0, tiles.size()):
		var findex = floors_map.get_cell(tiles[i].x, tiles[i].y)
		data.map.floors.append({
			"x": tiles[i].x,
			"y": tiles[i].y,
			"idx": findex
		})
	
	# Storing Wall Tiles
	tiles = walls_map.get_used_cells()
	for i in range(0, tiles.size()):
		var windex = walls_map.get_cell(tiles[i].x, tiles[i].y)
		data.map.walls.append({
			"x": tiles[i].x,
			"y": tiles[i].y,
			"idx": windex
		})
	
	# Store dungeon exit information
	data.map.exits = dungeon_exits
	
	return data


func buildMapFromData(data):
	if not data.has("version") or not data.has("map"):
		return
	
	# Verify version... this may be crap.
	if typeof(data.version) != TYPE_ARRAY:
		return
	if data.version.size() != 3:
		return
	if data.version[0] != 0 or data.version[1] != 1:
		if data.version[2] < 0 || data.version[2] > 1:
			return
	
	if not TilesetStore.has_tileset(data.map.tileset_name):
		# TODO: Tell user there was an issue.
		print("ERROR: Map tileset not found in system.")
		return # <--- Yes? No? Oh for the love of...
	TilesetStore.activate_tileset(data.map.tileset_name)
	
	parent_node.isRoyal = data.isRoyal
	parent_node.dungeon_name = data.name
	parent_node.engineer_name = data.engineer
	
	# Position the player start.
	parent_node.position_player_start_to(data.map.player_start)
	
	if data.version[2] == 1:
		parent_node.dungeon_timer_autostart = data.map.timer_autostart
		parent_node.dungeon_collapse_timer = data.map.collapse_timer
	else:
		parent_node.dungeon_timer_autostart = false
		parent_node.dungeon_collapse_timer = 0
	
	parent_node.tile_break_time = data.map.tile_break_time
	parent_node.tile_break_variance = data.map.tile_break_variance
	
	
	floors_map.clear()
	for i in range(0, data.map.floors.size()):
		floors_map.set_cell(data.map.floors[i].x, data.map.floors[i].y, data.map.floors[i].idx)
	
	walls_map.clear()
	for i in range(0, data.map.walls.size()):
		walls_map.set_cell(data.map.walls[i].x, data.map.walls[i].y, data.map.walls[i].idx)
	walls_map.update_bitmask_region()
	
	
	dungeon_exits = []
	var trigger_node = get_parent().get_node("Triggers")
	for i in range(0, data.map.exits.size()):
		dungeon_exits.append(data.map.exits[i])
		
		if trigger_node:
			var shape = null
			
			if data.map.exits[i].type == "circle":
				shape = CircleShape2D.new()
				shape.radius = data.map.exits[i].size.x
			elif data.map.exits[i].type == "rect":
				shape = RectangleShape2D.new()
				shape.extents = data.map.exits[i].size
			
			if shape != null:
				var col = CollisionShape2D.new()
				col.shape = shape
				
				var a = Area2D.new()
				a.add_child(col)
				a.collision_layer = 0
				a.collision_mask = 256
				a.global_position = data.map.exits[i].position
				a.set_script(load("res://objects/level_exit/Level Exit.gd"))
				a.connect("body_entered", a, "_on_Level_Exit_body_entered")
				a.connect("level_exit", get_parent(), "exit_level")
				parent_node.connect("open_exits", a, "_on_open_exits")
				trigger_node.add_child(a)
			else:
				print("WARNING: Failed to create exit trigger shape.")
	


# -----------------------------------------------------------------------------
# EVENT HANDLERS

func _on_tile_def_scanned():
	if not TilesetStore.has_tileset(tileset_def.name):
		if clear_on_new_tileset:
			clearTileMaps()
		tileset_def = null

func _on_tileset_activated(def):
	set_tileset_definition(def)
			


