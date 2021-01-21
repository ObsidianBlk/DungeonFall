tool
extends Node2D

export var map_editor_mode : bool = false


func _ready():
	if Engine.editor_hint:
		$Sprite.visible = true
	else:
		$Sprite.visible = map_editor_mode
