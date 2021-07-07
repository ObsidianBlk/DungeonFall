extends "res://scripts/DungeonEditor_Base.gd"

var active_entity_name = ""

func _handleInput(event):
	if event is InputEventMouseButton:
		if event.is_action_pressed("MapEditor_MousePlace"):
			editordungeon_node.insert_entity_at_tracker(active_entity_name)
			get_parent().reset_repeater()
		if event.is_action_pressed("MapEditor_MouseClear"):
			editordungeon_node.remove_entity_at_tracker()
			get_parent().reset_repeater()
	else:
		if event.is_action_pressed("ui_select"):
			editordungeon_node.insert_entity_at_tracker(active_entity_name)
			get_parent().reset_repeater()
		if event.is_action_pressed("ui_deselect"):
			editordungeon_node.remove_entity_at_tracker()
			get_parent().reset_repeater()

func clear():
	editordungeon_node.clear_tracker_ghost_entity()

func set_ghost_entity(entity_name : String) -> void:
	editordungeon_node.set_tracker_ghost_entity(entity_name)
	active_entity_name = entity_name

