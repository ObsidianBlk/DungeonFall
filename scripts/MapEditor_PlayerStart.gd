extends Node

var editorlevel_node = null

func set_leveleditor_node(lenode : Node):
	editorlevel_node = lenode


func _handleInput(event):
	if editorlevel_node == null:
		return
	
	var psresult = {"status":"success"}
	if event is InputEventMouseButton:
		if event.is_action_pressed("MapEditor_MousePlace"):
			psresult = editorlevel_node.player_start_to_tracker()
	else:
		if event.is_action_pressed("ui_select"):
			psresult = editorlevel_node.player_start_to_tracker()
	
	if psresult.status != "success":
		# TODO: Change this to an actual on-screen error message
		print ("[", psresult.status, "]: ", psresult.msg)
