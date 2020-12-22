extends Node2D
class_name DFWorld

var TEST_LEVEL = "res://levels/test_level/Test_Level.tscn"
var scene = null
var level = null


func _ready():
	load_level(TEST_LEVEL)

func unload_level():
	if level != null:
		level.disconnect("level_exit", self, "_on_level_exit")
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
		level.connect("level_exit", self, "_on_level_exit")
		$Perma_Objects/Player.revive() # Make sure player is alive again!
		level.attach_player($Perma_Objects/Player)
		level.attach_camera($Perma_Objects/Camera)


func _on_level_exit(next_level_info):
	# TODO: Handle proceedural levels when ready!
	load_level(next_level_info.src)

func _on_player_death():
	unload_level()
	load_level(TEST_LEVEL)
