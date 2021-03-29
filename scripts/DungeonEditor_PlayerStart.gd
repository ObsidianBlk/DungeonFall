extends Node

var editordungeon_node = null

func set_editordungeon_node(lenode : Node):
	editordungeon_node = lenode


func _handleInput(event):
	if editordungeon_node == null:
		return
	
	var psresult = {"status":"success"}
	if event is InputEventMouseButton:
		if event.is_action_pressed("MapEditor_MousePlace"):
			psresult = editordungeon_node.player_start_to_tracker()
	else:
		if event.is_action_pressed("ui_select"):
			psresult = editordungeon_node.player_start_to_tracker()
	
	if psresult.status != "success":
		# TODO: Change this to an actual on-screen error message
		print ("[", psresult.status, "]: ", psresult.msg)
