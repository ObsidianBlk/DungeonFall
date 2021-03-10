extends Control

func _ready():
	var world = get_tree().get_root().get_node("World")
	if world:
		world.connect("request_ui_vis_change", self, "_on_change_visible")
	else:
		print("ERROR: Failed to find the World node!!")

func _on_change_visible(e : bool, uiname : String = ""):
	if uiname == "" or uiname == name:
		visible = e
