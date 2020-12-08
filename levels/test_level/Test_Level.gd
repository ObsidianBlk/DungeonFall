extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func is_over_pit(pos : Vector2):
	var mpos = $TileMap.world_to_map(pos)
	var tindex = $TileMap.get_cellv(mpos)
	return tindex < 0

	
