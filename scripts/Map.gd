tool
extends Node2D


export (int, 1) var cell_size = 16 setget _set_cell_size
export (float, 0.1, 10.0) var time_to_collapse = 0.65
export (int, 0) var auto_tile_index = 0
export (int, 1, 100) var floor_tile_count = 1
export (Array, Resource) var floor_collapsing_nodes = []

var ready = false

var last_tile_pos = null
var tile_collapse_time = 0
var collapsing_tiles = {}

var player = null


func _set_cell_size(cs):
	if cs != cell_size:
		cell_size = cs
		if ready:
			$Walls.cell_size = Vector2(cell_size, cell_size)
			$Floors.cell_size = Vector2(cell_size, cell_size)

func _ready():
	ready = true

func set_player(p : Node2D):
	player = p


func _process(delta):
	if Engine.editor_hint:
		if Input.is_action_just_pressed("ui_select"):
			_redraw_floors()
	else:
		if player != null and not player.inair:
			var mpos = $Floors.world_to_map(player.position)
			var tindex = $Floors.get_cellv(mpos)
			if tindex >= 1 and tindex <= floor_tile_count:
				_set_collapsing_tile(mpos)


func _physics_process(delta):
	if not Engine.editor_hint:
		_update_collapsing_tiles(delta)

func _get_ctile_obj_from_map_position(mpos : Vector2):
	var ti = $Floors.get_cellv(mpos)
	if ti >= 1 and ti <= floor_tile_count:
		if ti-1 < floor_collapsing_nodes.size():
			return floor_collapsing_nodes[ti - 1]
	return null

func _update_collapsing_tiles(delta):
	var rkeys = []
	var hcell_size = cell_size * 0.5
	for key in collapsing_tiles:
		var tpos = collapsing_tiles[key].pos
		var ttc = collapsing_tiles[key].ttc
		ttc += delta
		if ttc >= time_to_collapse:
			var ctile = _get_ctile_obj_from_map_position(tpos)
			$Floors.set_cellv(tpos, -1)
			var t = ctile.instance()
			t.position = (tpos * cell_size) + Vector2(hcell_size, hcell_size)
			# TODO: Shouldn't "Collapsing" be a NodePath export variable?
			get_parent().get_node("Collapsing").add_child(t)
			rkeys.append(key)
		else:
			collapsing_tiles[key].ttc = ttc
	
	for key in rkeys:
		collapsing_tiles.erase(key)

# NOTE: Should only ever be used in the editor!
# I've been warned
func _redraw_floors():
	var used_cells = $Walls.get_used_cells_by_id(0)
	for cell in used_cells:
		var atv = $Walls.get_cell_autotile_coord(cell[0], cell[1])
		if atv == Vector2(1,1):
			$Floors.set_cell(cell[0], cell[1], floor(rand_range(1, 4.9)))


func _set_collapsing_tile(mpos : Vector2):
	var key = String(mpos.x) + "x" + String(mpos.y)
	if not (key in collapsing_tiles):
		collapsing_tiles[key] = {
			"pos": mpos,
			"ttc": 0
		} 

func _is_over_pit(pos : Vector2):
	var mpos = $Floors.world_to_map(pos)
	var tindex = $Floors.get_cellv(mpos)
	return tindex < 1

