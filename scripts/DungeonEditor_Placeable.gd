extends "res://scripts/DungeonEditor_Base.gd"

func clear():
	editordungeon_node.clear_tracker_ghost_entity()

func set_ghost_entity(entity_name : String) -> void:
	editordungeon_node.set_tracker_ghost_entity(entity_name)

