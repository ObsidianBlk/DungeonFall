extends Node2D
class_name DFWorld

var TEST_LEVEL = "res://levels/test_level/Test_Level.tscn"
var level = null

func _ready():
	load_level(TEST_LEVEL)

func unload_level():
	if level != null:
		level.detach_player_to($Perma_Objects)
		level.detach_camera_to($Perma_Objects)
		remove_child(level)
		level.queue_free()
		level = null

func load_level(res_path : String):
	var scene = load(res_path)
	if scene != null:
		unload_level()
		level = scene.instance()
		add_child(level)
		$Perma_Objects/Player.revive() # Make sure player is alive again!
		level.attach_player($Perma_Objects/Player)
		level.attach_camera($Perma_Objects/Camera)
		


func _on_player_death():
	unload_level()
	load_level(TEST_LEVEL)
