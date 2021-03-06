extends Node2D
class_name DFWorld

signal request_ui_vis_change(vis, uiname)
signal points_value_changed(val)
signal play_time_changed(val)
signal total_play_time(val)
signal total_points_obtained(val)
signal total_dungeon_runs(val)
signal level_time_changed(val)
signal level_time_visible(enable)

signal total_run_time(val)
signal total_run_points(val)

const EDITOR_WORLD_SCENE = "res://DungeonEditor.tscn"
const DUNGEON_SCENE = "res://levels/Dungeon.tscn"

# TODO:
# Setup an over-all game "state" system to determine what menu player is in or if they are actively in the game.
var in_game_pause_state = false

#var TEST_LEVEL = "res://levels/test_level/Test_Level.tscn"
#var FIRST_LEVEL = "res://levels/Run_Set_A/Level1.tscn"
var FIRST_LEVEL = "user://maps/MyMap.dfm"
#var scene = null
var level = null
var cur_level_info = {
	"src":FIRST_LEVEL,
	"proceedural": false,
	"seed": 0
}

var run_results = []
var cur_level_stats = null

onready var gameview = $GameView/Port
onready var dungeonload_node = $CanvasLayer/UI/DungeonLoad

func _ready():
	# Initialize IO
	Io.initialize()
	
	# ------------------ START OF BRAIN DRIVIL
	#print("Bin Val: ", 0b0000000100000001)
	#print("Val: ", (int(257) >> 8) & 0x0F)
	#print("Val2: ", (int(1) << 8))
	#print("Val3: ", ((int(1) << 8) | int(1)))
	
	#var v = 1
	#print("V: ", v << 8)
	#print("V2: ", (v << 8) | v)
	#var test = PoolByteArray()
	#var v = var2bytes(257)
	#  00000001 00000001
	#print("V Size: ", v.size())
	#for i in range(0, v.size()):
	#	print("idx: ", i, " | val: ", v[i])
	#v = bytes2var(v)
	#print("OG Val: ", v)
	#GD.var2byes()
	# ------------------ END OF BRAIN DRIVIL
	
	# Connect required signals
	$Perma_Objects/Player.connect("request_game_pause", self, "_on_game_pause")
	emit_signal("request_ui_vis_change", false, "Game")
	emit_signal("request_ui_vis_change", false, "LevelTransition")
	emit_signal("request_ui_vis_change", false, "LastLevelResults")
	emit_signal("request_ui_vis_change", false, "RunCompletion")
	emit_signal("request_ui_vis_change", false, "PauseMenu")
	emit_signal("request_ui_vis_change", true, "MainMenu")
	get_tree().paused = true


func _unhandled_input(event):
	if in_game_pause_state == true:
		if event.is_action_pressed("ui_cancel"):
			_on_game_resume()


func _store_run():
	if cur_level_stats != null:
		run_results.append(cur_level_stats)
	cur_level_stats = {
		"points": 0,
		"time": 0.00
	}

func unload_level():
	if level != null:
		level.disconnect("end_of_run", self, "_on_end_of_run")
		level.disconnect("level_exit", self, "_on_level_exit")
		level.disconnect("point_update", self, "_on_point_update")
		level.disconnect("play_timer_changed", self, "_on_play_timer_changed")
		if level.dungeon_collapse_timer > 0.0:
			level.disconnect("level_timer_changed", self, "_on_level_timer_changed")
		level.detach_player_to($Perma_Objects)
		level.detach_camera_to($Perma_Objects)
		gameview.remove_child(level)
		level.queue_free()
		level = null

func load_level(res_path : String, new_level : bool = true):
	var scene = load(DUNGEON_SCENE)
	
	if scene != null:
		if new_level:
			_store_run()
		
		unload_level()
		level = scene.instance()
		if not level.load_user_level(res_path):
			level.queue_free()
			level = null
			return false
		
		gameview.add_child(level)
		
		$Perma_Objects/Player.revive() # Make sure player is alive again!
		level.attach_player($Perma_Objects/Player)
		level.attach_camera($Perma_Objects/Camera)
		
		level.connect("end_of_run", self, "_on_end_of_run")
		level.connect("level_exit", self, "_on_level_exit")
		level.connect("point_update", self, "_on_point_update")
		level.connect("play_timer_changed", self, "_on_play_timer_changed")
		if level.dungeon_collapse_timer > 0.0:
			emit_signal("level_time_visible", true)
			level.connect("level_timer_changed", self, "_on_level_timer_changed")
		else:
			emit_signal("level_time_visible", false)
			
		return true
	return false


func _load_user_level(path : String):
	var scene = load(DUNGEON_SCENE)
	scene = scene.instance()
	if scene.load_user_level(path):
		return scene
	return null


func _on_start():
	if not dungeonload_node.visible:
		dungeonload_node.popup()

func _on_cancel_dungeonload():
	dungeonload_node.visible = false
	emit_signal("request_ui_vis_change", true, "MainMenu")

func _on_dungeon_start(dungeonPath):
	dungeonload_node.visible = false
	cur_level_info.src = dungeonPath
	run_results = []
	_on_continue_to_level()


func _on_game_pause():
	# print ("Pause requested")
	emit_signal("request_ui_vis_change", false, "Game")
	emit_signal("request_ui_vis_change", true, "PauseMenu")
	get_tree().paused = true
	in_game_pause_state = true

func _on_game_resume():
	emit_signal("request_ui_vis_change", true, "Game")
	emit_signal("request_ui_vis_change", false, "PauseMenu")
	get_tree().paused = false
	in_game_pause_state = false

func _on_point_update(points):
	if cur_level_stats != null:
		cur_level_stats.points = points
	emit_signal("points_value_changed", str(points))

func _on_play_timer_changed(time_val):
	if cur_level_stats != null:
		cur_level_stats.time = time_val
	emit_signal("play_time_changed", str(time_val).pad_decimals(2))

func _on_level_timer_changed(time_val):
	emit_signal("level_time_changed", str(time_val).pad_decimals(2))

func _on_level_exit(next_level_info):
	# TODO: Handle proceedural levels when ready!
	# TODO: Ummm... like, level info objects should have a "create" method to keep
	#   them consistent!
	cur_level_info = next_level_info
	emit_signal("request_ui_vis_change", false, "Game")
	emit_signal("request_ui_vis_change", true, "LevelTransition")
	#$CanvasLayer/UI/Game.visible = false
	#$"CanvasLayer/UI/Level Transition".visible = true
	get_tree().paused = true

func _on_end_of_run():
	_store_run()
	get_tree().paused = true
	
	var total_play_time = 0.0
	var total_points = 0
	for res in run_results:
		total_play_time += res.time
		total_points += res.points
	var total_dungeons = run_results.size()
	
	
	emit_signal("total_play_time", str(total_play_time).pad_decimals(2))
	emit_signal("total_points_obtained", str(total_points).pad_decimals(0))
	emit_signal("total_dungeon_runs", str(total_dungeons).pad_decimals(0))
	
	emit_signal("request_ui_vis_change", false, "Game")
	emit_signal("request_ui_vis_change", true, "LastLevelResults")
	#emit_signal("request_ui_vis_change", true, "MainMenu")

func _on_continue_to_level(is_new_level : bool = true):
	if load_level(cur_level_info.src, is_new_level):
		#$CanvasLayer/UI/Game.visible = true
		emit_signal("request_ui_vis_change", true, "Game")
		get_tree().paused = false
	else:
		emit_signal("request_ui_vis_change", true, "MainMenu")

func _on_player_death():
	load_level(cur_level_info.src, false)

func _on_open_editor():
	var editor = load(EDITOR_WORLD_SCENE)
	if editor:
		var editor_node = editor.instance()
		var p = get_parent()
		p.remove_child(self)
		p.add_child(editor_node)
		queue_free()

func _on_quit():
	get_tree().quit()
