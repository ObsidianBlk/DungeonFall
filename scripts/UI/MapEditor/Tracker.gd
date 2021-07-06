extends Node2D

export var ghost_entity : String = ""	setget _set_ghost_entity

onready var sprite_node = $Sprite


func _set_ghost_entity(e : String) -> void:
	ghost_entity = e
	if sprite_node and (ghost_entity == "" or Entity.has(ghost_entity)):
		if ghost_entity != "":
			var ent = Entity.get(ghost_entity)
			var tex = AtlasTexture.new()
			tex.atlas = load(ent["icon-src"])
			if ent["icon-region"] != null:
				var r = ent["icon-region"]
				tex.region = Rect2(r.x, r.y, r.w, r.h)
			else:
				var size = tex.atlas.get_size()
				tex.region = Rect2(0, 0, size.x, size.y)
			sprite_node.texture = tex
			sprite_node.show()
		else:
			sprite_node.hide()

func _ready():
	_set_ghost_entity(ghost_entity)
	var cell = get_parent().cell
	sprite_node.position = cell * 0.5

func _process(delta : float) ->void:
	update()

func _draw() -> void:
	var cell = get_parent().cell
	var x = int(position.x) % int(cell.x)
	var y = int(position.y) % int(cell.y)
	var rect = Rect2(x, y, cell.x, cell.y)
	draw_rect(rect, Color(1.0, 0.0, 0.0, 0.5), false, 1.0)
