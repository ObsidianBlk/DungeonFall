tool
extends Node

signal tile_defs_scanned

var TILESETS = {}

func rescan(scan_res : bool = true, scan_user : bool = true):
	if scan_res:
		_find_tilesets("res://tilesets/")
	if scan_user:
		_find_tilesets("user://tilesets/", true)
	if scan_res or scan_user:
		emit_signal("tile_defs_scanned")

func get_definition(name : String):
	if TILESETS.has(name):
		return TILESETS[name]
	return null

func _ready():
	rescan()

func _find_tilesets(path : String, is_user_path : bool = false):
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin(false, true)
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				if dir.file_exists(file_name + "/def.json"): # We have a tileset folder
					_load_tileset_def(dir.get_current_dir() + file_name + "/", "def.json")
				elif is_user_path:
					_find_tilesets(dir.get_current_dir() + file_name)
			file_name = dir.get_next()


func _load_tileset_def(path, file_name):
	var full_path = path + file_name
	var file = File.new()
	var err = file.open(full_path, File.READ)
	if err == OK:
		var data = parse_json(file.get_as_text())
		if typeof(data) == TYPE_DICTIONARY:
			data.base_path = path
			if not _process_tileset_definition(data):
				print("ERROR: Failed to process tileset definition JSON, \"", full_path, "\".")
		else:
			print("ERROR: Invalid tileset definition JSON file, \"", full_path, "\".") 
	else:
		printerr("ERROR: Failed to open tileset definition file, \"", full_path, "\"")
	file.close()


func _file_exists(path):
	return (File.new()).file_exists(path)


func _process_tileset_definition(def : Dictionary):
	# TODO: Return an error object instead of true/false
	if not def.has("version"):
		return false
	
	var version = def.version.split(".")
	if version.size() != 2:
		return false
	if int(version[0]) != 0 or int(version[1]) != 1:
		return false
	# If we get here, we have the right version! YAY!
	
	if not ("base_path" in def):
		return false
	
	if not def.has("name") or not def.has("size") or not def.has("walls") or not def.has("floors"):
		return false
	
	if def.name in TILESETS:
		print("WARNING: Tileset \"", def.name, "\" already defined. Skipping tileset.")
		return true
	
	if not def.has("resource_path"):
		return false
	if not _file_exists(def.base_path + def.resource_path):
		print ("WARNING: Tileset resource \"", def.resource_path, "\" does not exist. Skipping tileset.")
		return true
	
	if def.size <= 0:
		return false
	
	
	# TODO: Validate the .walls attribute is all integers
	# TODO: Validate the .floors sub-attribute
	TILESETS[def.name] = def
	
	return true



