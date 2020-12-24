extends Node2D
class_name DFWorld

signal play_time_changed(val)
signal level_time_changed(val)
signal level_time_visible(enable)


var TEST_LEVEL = "res://levels/test_level/Test_Level.tscn"
var scene = null
var level = null
var cur_level_info = {"src":TEST_LEVEL}

onready var gameview = $GameView/Port

func _ready():
	load_level(cur_level_info.src)

func unload_level():
	if level != null:
		level.disconnect("level_exit", self, "_on_level_exit")
		level.disconnect("point_update", self, "_on_point_update")
		level.disconnect("play_timer_changed", self, "_on_play_timer_changed")
		if level.level_max_timer > 0.0:
			level.disconnect("level_timer_changed", self, "_on_level_timer_changed")
		level.detach_player_to($Perma_Objects)
		level.detach_camera_to($Perma_Objects)
		gameview.remove_child(level)
		level.queue_free()
		level = null

func load_level(res_path : String):
	var scene = load(res_path)
	if scene != null:
		unload_level()
		level = scene.instance()
		gameview.add_child(level)
		level.connect("level_exit", self, "_on_level_exit")
		level.connect("point_update", self, "_on_point_update")
		level.connect("play_timer_changed", self, "_on_play_timer_changed")
		emit_signal("play_time_changed", "0.00")
		if level.level_max_timer > 0.0:
			emit_signal("level_time_visible", true)
			emit_signal("level_time_changed", "0.00")
			level.connect("level_timer_changed", self, "_on_level_timer_changed")
		else:
			emit_signal("level_time_visible", false)
		$Perma_Objects/Player.revive() # Make sure player is alive again!
		level.attach_player($Perma_Objects/Player)
		level.attach_camera($Perma_Objects/Camera)
		return true
	return false


func _on_point_update(points):
	print("Points: ", points)

func _on_play_timer_changed(time_val):
	emit_signal("play_time_changed", str(time_val).pad_decimals(2))

func _on_level_timer_changed(time_val):
	emit_signal("level_time_changed", str(time_val).pad_decimals(2))

func _on_level_exit(next_level_info):
	# TODO: Handle proceedural levels when ready!
	cur_level_info = next_level_info
	$CanvasLayer/UI/Game.visible = false
	$"CanvasLayer/UI/Level Transition".visible = true
	get_tree().paused = true
	
func _on_continue_to_level():
	$"CanvasLayer/UI/Level Transition".visible = false
	$CanvasLayer/UI/Game.visible = true
	get_tree().paused = false
	load_level(cur_level_info.src)

func _on_player_death():
	unload_level()
	load_level(cur_level_info.src)
