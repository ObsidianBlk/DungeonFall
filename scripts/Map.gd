tool
extends Node2D


export var walls_tilemap_path : NodePath = "" setget _set_walls_tilemap_path
export var floors_tilemap_path : NodePath = "" setget _set_floors_tilemap_path
export var doors_tilemap_path : NodePath = "" setget _set_doors_tilemap_path
export (int, 1) var cell_size = 16 setget _set_cell_size
export (float, 0.1, 10.0) var time_to_collapse = 0.65
export (int, 0) var auto_tile_index = 0
export (int, 1, 100) var floor_tile_count = 1
export (Array, Resource) var floor_collapsing_nodes = []

var ready = false

var last_tile_pos = null
var tile_collapse_time = 0
var collapsing_tiles = {}

var floors_map = null
var walls_map = null
var doors_map = null

var player = null


func _set_walls_tilemap_path(wtp : NodePath, force : bool = false):
	if wtp != walls_tilemap_path or force:
		if ready:
			if wtp == "":
				walls_map = null
			else:
				var nwm = get_node(walls_tilemap_path)
				if nwm != null:
					walls_map = nwm
				else:
					wtp = walls_tilemap_path
		walls_tilemap_path = wtp

func _set_floors_tilemap_path(ftp : NodePath, force : bool = false):
	if ftp != floors_tilemap_path or force:
		if ready:
			if ftp == "":
				floors_map = null
			else:
				var nfm = get_node(floors_tilemap_path)
				if nfm != null:
					floors_map = nfm
				else:
					ftp = floors_tilemap_path
		floors_tilemap_path = ftp

func _set_doors_tilemap_path(dtp : NodePath, force : bool = false):
	if dtp != doors_tilemap_path or force:
		if ready:
			if dtp == "":
				doors_map = null
			else:
				var ndm = get_node(doors_tilemap_path)
				if ndm != null:
					doors_map = ndm
				else:
					dtp = doors_tilemap_path
		doors_tilemap_path = dtp

func _set_cell_size(cs):
	if cs != cell_size:
		cell_size = cs
		if ready:
			if walls_map != null:
				walls_map.cell_size = Vector2(cell_size, cell_size)
			if floors_map != null:
				floors_map.cell_size = Vector2(cell_size, cell_size)

func _ready():
	ready = true
	_set_walls_tilemap_path(walls_tilemap_path, true)
	_set_floors_tilemap_path(floors_tilemap_path, true)
	_set_doors_tilemap_path(doors_tilemap_path, true)

func set_player(p : Node2D):
	player = p


func _process(delta):
	if Engine.editor_hint:
		if Input.is_key_pressed(KEY_CONTROL) and Input.is_key_pressed(KEY_SHIFT) and Input.is_key_pressed(KEY_R):
			_redraw_floors()
	else:
		if floors_map != null and player != null and not player.inair:
			var mpos = floors_map.world_to_map(player.position)
			var tindex = floors_map.get_cellv(mpos)
			if tindex >= 1 and tindex <= floor_tile_count:
				_set_collapsing_tile(mpos)


func _physics_process(delta):
	if not Engine.editor_hint:
		_update_collapsing_tiles(delta)

func _get_ctile_obj_from_map_position(mpos : Vector2):
	if floors_map != null:
		var ti = floors_map.get_cellv(mpos)
		if ti >= 1 and ti <= floor_tile_count:
			if ti-1 < floor_collapsing_nodes.size():
				return floor_collapsing_nodes[ti - 1]
	return null

func _update_collapsing_tiles(delta):
	if floors_map == null:
		return
	
	var rkeys = []
	var hcell_size = cell_size * 0.5
	for key in collapsing_tiles:
		var tpos = collapsing_tiles[key].pos
		var ttc = collapsing_tiles[key].ttc
		ttc += delta
		if ttc >= time_to_collapse:
			var ctile = _get_ctile_obj_from_map_position(tpos)
			floors_map.set_cellv(tpos, -1)
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
	if floors_map == null or walls_map == null:
		return
	
	var used_cells = walls_map.get_used_cells_by_id(0)
	for cell in used_cells:
		var atv = walls_map.get_cell_autotile_coord(cell[0], cell[1])
		if atv == Vector2(1,1):
			floors_map.set_cell(cell[0], cell[1], floor(rand_range(1, 4.9)))


func _set_collapsing_tile(mpos : Vector2):
	var key = String(mpos.x) + "x" + String(mpos.y)
	if not (key in collapsing_tiles):
		collapsing_tiles[key] = {
			"pos": mpos,
			"ttc": 0
		} 

func _is_over_pit(pos : Vector2):
	if floors_map == null:
		return false

	var mpos = floors_map.world_to_map(pos)
	var tindex = floors_map.get_cellv(mpos)
	return tindex < 1



