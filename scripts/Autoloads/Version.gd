extends Node


var git_info = null

func _ready() -> void:
	var dir = Directory.new()
	if dir.open("res://") == OK:
		if dir.file_exists("gitinfo.json"):
			var f = File.new()
			f.open("res://gitinfo.json", File.READ)
			var data = JSON.parse(f.get_as_text())
			f.close()
			
			if data.error == OK:
				if "hash" in data.result and "tag" in data.result:
					git_info = data.result


func toString() -> String:
	var base_ver = ProjectSettings.get_setting("global/game_base_version")
	var version = "%s.%s.%s" % base_ver
	if git_info != null:
		if git_info.tag != "":
			version = version + (" - %s" % git_info.tag)
		else:
			version = version + (" - %s" % git_info.hash)
	
	return version
