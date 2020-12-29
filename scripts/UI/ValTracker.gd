extends Control


export var signal_name : String = ""
export var value_label_node_path : NodePath = ""

var value_label_node = null

func _ready():
	value_label_node = get_node(value_label_node_path)
	if signal_name != "":
		get_tree().get_root().get_node("World").connect(signal_name, self, "_on_value_changed")


func _on_value_changed(val):
	if value_label_node != null:
		value_label_node.text = val


