extends TileMap

var ctile = preload("res://objects/FallingTile.tscn")

export (float, 0.1, 10.0) var time_to_collapse = 0.65

var last_tile_pos = null
var tile_collapse_time = 0

var collapsing_tiles = {}


var player = null
func _ready():
	pass

func set_player(p : Node2D):
	player = p


func _set_collapsing_tile(tile_pos):
	var key = String(tile_pos.x) + "x" + String(tile_pos.y)
	if not (key in collapsing_tiles):
		collapsing_tiles[key] = {
			"pos": tile_pos,
			"ttc": 0
		}

func _update_collapsing_tiles(delta):
	var rkeys = []
	for key in collapsing_tiles:
		var tpos = collapsing_tiles[key].pos
		var ttc = collapsing_tiles[key].ttc
		ttc += delta
		if ttc >= time_to_collapse:
			set_cell(tpos.x, tpos.y, -1)
			var t = ctile.instance()
			t.position = (tpos * cell_size) + (cell_size * 0.5)
			get_parent().get_node("Collapsing").add_child(t)
			rkeys.append(key)
		else:
			collapsing_tiles[key].ttc = ttc
	
	for key in rkeys:
		collapsing_tiles.erase(key)


func _process(delta):
	if player != null and not player.inair:
		var mpos = world_to_map(player.position)
		var taindex = get_cell_autotile_coord(mpos.x, mpos.y)
		if taindex == Vector2(1,1):
			_set_collapsing_tile(mpos)

func _physics_process(delta):
	_update_collapsing_tiles(delta)
