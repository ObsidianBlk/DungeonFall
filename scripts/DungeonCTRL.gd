extends Node2D

signal pickup

var RNG = null

var last_tile_pos = null
var tile_collapse_time = 0
var collapsing_tiles = {}
var player = null

onready var parent_node = get_parent()
onready var dbt_node = get_parent().get_node("DungeonBuildTools")
onready var floors_map = get_parent().get_node("Floors")
onready var walls_map = get_parent().get_node("Walls")
onready var doors_map = get_parent().get_node("Doors")

onready var gold_container = get_parent().get_node("Gold_Container")


func _ready():
	RNG = RandomNumberGenerator.new()

func _process(_delta):
	if floors_map != null and player != null and not player.inair:
		var on_ctile = false
		if player.footprint > 0:
			var px = player.position.x
			var py = player.position.y
			var fp = player.footprint
			on_ctile = _check_for_collapsable_tile(Vector2(px + fp, py))
			on_ctile = on_ctile or _check_for_collapsable_tile(Vector2(px - fp, py))
			on_ctile = on_ctile or _check_for_collapsable_tile(Vector2(px, py + fp))
			on_ctile = on_ctile or _check_for_collapsable_tile(Vector2(px, py - fp))
		else:
			on_ctile = _check_for_collapsable_tile(player.position)
		
		# TODO: Figure out what to do, if anything, with on_ctile... Do I want to
		# actually trigger something?


func _physics_process(delta):
	if not Engine.editor_hint:
		_update_collapsing_tiles(delta)


# -----------------------------------------------------------------------------
# "PRIVATE" METHODS

func _player_on_tile_at(mpos : Vector2):
	if not player.inair:
		if player.footprint > 0:
			var px = player.position.x
			var py = player.position.y
			var fp = player.footprint
			if floors_map.world_to_map(Vector2(px + fp, py)) == mpos:
				return true
			if floors_map.world_to_map(Vector2(px - fp, py)) == mpos:
				return true
			if floors_map.world_to_map(Vector2(px, py + fp)) == mpos:
				return true
			if floors_map.world_to_map(Vector2(px, py - fp)) == mpos:
				return true
		else:
			return floors_map.world_to_map(player.position) == mpos
	return false

func _check_for_collapsable_tile(pos : Vector2):
	var mpos = floors_map.world_to_map(pos)
	var tindex = floors_map.get_cellv(mpos)
	if dbt_node.is_tile_breakable(tindex):
		_set_collapsing_tile(mpos)
		return true
	return false

func _get_breakable_tile_from_map_position(mpos : Vector2):
	if floors_map != null:
		var ti = floors_map.get_cellv(mpos)
		return dbt_node.get_breakable_tile_resource(ti)
	return null

func _update_collapsing_tiles(delta):
	if not dbt_node.is_valid() or floors_map == null:
		return
	
	var cell_size = dbt_node.get_cell_size()
	if cell_size <= 0:
		return
	
	var rkeys = []
	var hcell_size = cell_size * 0.5
	for key in collapsing_tiles:
		if collapsing_tiles[key].force or _player_on_tile_at(collapsing_tiles[key].pos):
			var tpos = collapsing_tiles[key].pos
			var ctm = collapsing_tiles[key].ctm
			var ttc = collapsing_tiles[key].ttc
			ttc += delta
			if ttc >= ctm:
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
		else:
			rkeys.append(key)
	
	for key in rkeys:
		collapsing_tiles.erase(key)

func _set_collapsing_tile(mpos : Vector2, force : bool = false):
	var key = String(mpos.x) + "x" + String(mpos.y)
	if not (key in collapsing_tiles):
		var variance = RNG.randf_range(-(parent_node.tile_break_variance * 0.5), (parent_node.tile_break_variance * 0.5))
		var collapse_time_max = parent_node.tile_break_time + variance
		var ttc = 0
		if force:
			ttc = collapse_time_max
			
		collapsing_tiles[key] = {
			"pos": mpos,
			"ctm": collapse_time_max,
			"ttc": ttc,
			"force": force
		}


func _collapse_level():
	# floors_map
	var floors = floors_map.get_used_cells()
	for f in floors:
		_set_collapsing_tile(f, true)


func _is_over_pit(pos : Vector2, footprint : int = 0):
	if floors_map == null:
		return false
	
	var result = false
	if footprint > 0:
		result = true
		for _i in range(0, footprint):
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
			if parent_node.has_node("Collapsing/CT_" + key):
				var ctn = parent_node.get_node("Collapsing/CT_" + key)
				result = not ctn.is_safe()
	return result

# -----------------------------------------------------------------------------
# "PUBLIC" METHODS

func set_player(p : Node2D):
	player = p


func update_gold_container():
	if gold_container:
		for child in gold_container.get_children():
			if not child.is_connected("pickup", self, "_on_gold_pickup"):
				child.connect("pickup", self, "_on_gold_pickup")


# -----------------------------------------------------------------------------
# EVENT HANDLERS

func _on_gold_pickup():
	emit_signal("pickup")

