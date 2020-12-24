extends Control


export var signal_name : String = ""

func _ready():
	if signal_name != "":
		get_tree().get_root().get_node("World").connect(signal_name, self, "_on_time_changed")


func _on_time_changed(val):
	$Time.text = val


