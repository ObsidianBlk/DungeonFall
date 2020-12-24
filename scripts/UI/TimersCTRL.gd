extends Control

func _ready():
	get_tree().get_root().get_node("World").connect("level_time_visible", self, "_on_level_time_visible")


func _on_level_time_visible(enable):
	$"Level Time".visible = enable
