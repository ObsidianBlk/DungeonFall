tool
extends Node2D

signal floor_changed

export var editor_mode : bool = false
export var map_seed : int = 0
export var clear_on_new_tileset : bool = true

var ready = false
var tileset_def = null
var RNG = null

var breakable_tile_resources = {}
var dungeon_exits = []
var placed_entities = {}

onready var parent_node = get_parent()
onready var floors_map = get_parent().get_node("Floors")
onready var walls_map = get_parent().get_node("Walls")
onready var doors_map = get_parent().get_node("Doors")
onready var entity_container = get_parent().get_node("Entity_Container")
var ghost_map = null
var gold_container_node = null


func _ready():
	ready = true
	# Connect to TilesetStore...
	TilesetStore.connect("tile_defs_scanned", self, "_on_tile_def_scanned")
	TilesetStore.connect("tileset_activated", self, "_on_tileset_activated")
	
	reset_rng()
	tileset_def = TilesetStore.get_definition()
	
	if parent_node.has_node("Ghost"):
		ghost_map = parent_node.get_node("Ghost")
	if parent_node.has_node("Entity_Container"):
		gold_container_node = parent_node.get_node("Entity_Container")


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
	clear_dungeon_gold()
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
			if typeof(ei) == TYPE_STRING:
				return TilesetStore.is_tile_partof_meta(tileset_def, ei, tile_id)
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
	var emit_update = false
		
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
						emit_update = true
					else:
						floors_map.set_cell(x + tx, y + ty, -1)
						emit_update = true
			var einfo = TilesetStore.get_meta_exit_info(tileset_def, floor_tile, x, y)
			_removeExitIfOverlap(einfo)
			if is_tile_exit(floor_tile):
				if einfo != null:
					dungeon_exits.append(einfo)
		else:
			print("ERROR: Failed to set meta tile '", floor_tile, "'. Size does not match given tiles.")
	else:
		floors_map.set_cell(x, y, floor_tile)
		emit_update = true
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
	
	if emit_update:
		emit_signal("floor_changed")
	_recalculate_walls(wall_tile)
	return true

func get_floor_at_pos(pos : Vector2):
	pos = floors_map.world_to_map(pos)
	return get_floor(int(floor(pos.x)), int(floor(pos.y)))

func get_floor(x : int, y : int):
	if not is_valid():
		return -1
	return floors_map.get_cell(x, y)

func get_floor_count():
	return floors_map.get_used_cells().size()


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

func clear_dungeon_gold():
	var rem_keys = []
	for key in placed_entities:
		var ent = placed_entities[key]
		if ent.tags != null and ent.tags.find("__proc_gen__") >= 0:
			var parent = ent.entity.get_parent()
			parent.remove_child(ent.entity)
			rem_keys.append(key)
	for i in range(0, rem_keys.size()):
		placed_entities.erase(rem_keys[i])

func gen_entity_key_from_pos(pos : Vector2, floor_must_exist : bool = false) -> String:
	var tpos = floors_map.world_to_map(pos)
	if floor_must_exist:
		var tindex = floors_map.get_cell(tpos.x, tpos.y)
		if tindex < 0:
			return ""
	return "%sx%s" % [tpos.x, tpos.y]

func is_entity_at_pos(pos : Vector2, floor_must_exist : bool = false) -> bool:
	var key = gen_entity_key_from_pos(pos, floor_must_exist)
	if key in placed_entities:
		return true
	return false

func insert_entity_at_pos(pos : Vector2, entity_name : String, tags : Array = []) -> void:
	var eobj = Entity.get_object(entity_name)
	var ekey = gen_entity_key_from_pos(pos, true)
	if eobj != null and ekey != "" and !(ekey in placed_entities):
		var ent = eobj.instance()
		entity_container.add_child(ent)
		ent.position = pos
		if editor_mode:
			if ent.get("editor_mode") != null:
				ent.editor_mode = true
			placed_entities[ekey] = {"name":entity_name, "entity":ent, "tags":null}
			if tags.size() > 0:
				placed_entities[ekey].tags = tags

func remove_entity_at_pos(pos : Vector2) -> void:
	var ekey = gen_entity_key_from_pos(pos, true)
	if ekey in placed_entities:
		entity_container.remove_child(placed_entities[ekey].entity)
		if editor_mode:
			placed_entities[ekey].entity.queue_free()
			placed_entities.erase(ekey)

func generate_dungeon_gold():
	if gold_container_node == null:
		return
	if parent_node.gold_amount <= 0 or parent_node.gold_seed == "":
		clear_dungeon_gold()
		return
	
	var ucl = floors_map.get_used_cells()
	if ucl.size() <= 0:
		return
	
	clear_dungeon_gold()
	var grng = RandomNumberGenerator.new()
	grng.seed = parent_node.gold_seed.hash()

	for _i in range(0, parent_node.gold_amount):
		var pos = null
		for _j in range(0, 100): # NOTE: May never loop near this much!
			var tindex = grng.randi_range(0, ucl.size()-1)
			var tpos = ucl[tindex]
			ucl.remove(tindex)

			var tid = floors_map.get_cell(tpos.x, tpos.y)
			if not is_tile_exit(tid):
				pos = floors_map.map_to_world(tpos)
				pos += floors_map.cell_size * 0.5
				break
		#var pos = floors_map.map_to_world(
		if pos != null:
			insert_entity_at_pos(pos, "Coin", ["__proc_gen__"])
	

#func generate_dungeon_gold():
#	if gold_container_node == null:
#		return
#	if parent_node.gold_amount <= 0 or parent_node.gold_seed == "":
#		clear_dungeon_gold()
#		return
#
#	var ucl = floors_map.get_used_cells()
#	if ucl.size() <= 0:
#		return
#
#	var gobj = load("res://objects/gold/Gold.tscn")
#	if gobj:
#		var grng = RandomNumberGenerator.new()
#		grng.seed = parent_node.gold_seed.hash()
#
#		clear_dungeon_gold()
#
#		for _i in range(0, parent_node.gold_amount):
#			var pos = null
#			for _j in range(0, 100): # NOTE: May never loop near this much!
#				var tindex = grng.randi_range(0, ucl.size()-1)
#				var tpos = ucl[tindex]
#				ucl.remove(tindex)
#
#				var tid = floors_map.get_cell(tpos.x, tpos.y)
#				if not is_tile_exit(tid):
#					pos = floors_map.map_to_world(tpos)
#					pos += floors_map.cell_size * 0.5
#					break
#			#var pos = floors_map.map_to_world(
#			if pos != null:
#				var gld = gobj.instance()
#				if gld:
#					gld.position = pos
#					gold_container_node.add_child(gld)
#					gld.editor_mode = true
#			if ucl.size() <= 0:
#				break


func generateMapData():
	var player_start = parent_node.get_node("Player_Start")
	if not player_start:
		return
		
	var data = {
		"name": parent_node.dungeon_name,
		"engineer": parent_node.engineer_name,
		"version": [0,1,3],
		"map":{
			"tileset_name": tileset_def.name,
			"player_start": player_start.position,
			"timer_autostart": parent_node.dungeon_timer_autostart,
			"collapse_timer": parent_node.dungeon_collapse_timer,
			"tile_break_time": parent_node.tile_break_time,
			"tile_break_variance": parent_node.tile_break_variance,
			"gold_amount": parent_node.gold_amount,
			"gold_seed": parent_node.gold_seed,
			"entities": null,
			"floors": [],
			"walls": [],
			"exits": null
		}
	}
	
	# Storing entities...
	if placed_entities.size() > 0:
		data.map.entities = []
		for key in placed_entities:
			var ent = placed_entities[key]
			data.map.entities.append({
				"name": ent.name,
				"position": ent.entity.position
			})
	
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
		if data.version[2] < 0 || data.version[2] > 2:
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
	
	if data.version[2] >= 1:
		parent_node.dungeon_timer_autostart = data.map.timer_autostart
		parent_node.dungeon_collapse_timer = data.map.collapse_timer
	else:
		parent_node.dungeon_timer_autostart = false
		parent_node.dungeon_collapse_timer = 0
	
	parent_node.tile_break_time = data.map.tile_break_time
	parent_node.tile_break_variance = data.map.tile_break_variance
	
	if data.version[2] >= 2:
		parent_node.gold_amount = data.map.gold_amount
		parent_node.gold_seed = data.map.gold_seed
	else:
		parent_node.gold_amount = 0
		parent_node.gold_seed = ""
	
	
	floors_map.clear()
	for i in range(0, data.map.floors.size()):
		floors_map.set_cell(data.map.floors[i].x, data.map.floors[i].y, data.map.floors[i].idx)
	
	walls_map.clear()
	for i in range(0, data.map.walls.size()):
		walls_map.set_cell(data.map.walls[i].x, data.map.walls[i].y, data.map.walls[i].idx)
	walls_map.update_bitmask_region()
	
	
	dungeon_exits = []
	var trigger_node = get_parent().get_node("Triggers") # This is NOT an error!!!
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
	
	# ----
	# Loading in entities!
	if data.version[2] >= 3 and data.map.entities != null:
		for ent in data.map.entities:
			insert_entity_at_pos(ent.position, ent.name)
	
	# ----
	# Generating "proceedural" gold placement
	if data.version[2] >= 2 and data.map.gold_amount > 0 and gold_container_node != null:
		generate_dungeon_gold()



# -----------------------------------------------------------------------------
# EVENT HANDLERS

func _on_tile_def_scanned():
	if not TilesetStore.has_tileset(tileset_def.name):
		if clear_on_new_tileset:
			clearTileMaps()
		tileset_def = null

func _on_tileset_activated(def):
	set_tileset_definition(def)
			


