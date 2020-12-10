tool
extends Node2D


func _ready():
	if Engine.editor_hint:
		$Sprite.visible = true
	else:
		$Sprite.visible = false
