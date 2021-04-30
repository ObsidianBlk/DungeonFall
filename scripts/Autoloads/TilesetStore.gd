tool
extends Node

signal tile_defs_scanned
signal tileset_activated(def)

var TILESETS = {}
var active_tileset = null

func rescan(scan_res : bool = true, scan_user : bool = true):
	if scan_res:
		_find_tilesets("res://tilesets/")
	if scan_user:
		_find_tilesets("user://tilesets/", true)
	if scan_res or scan_user:
		emit_signal("tile_defs_scanned")
		if active_tileset == null or not TILESETS.has(active_tileset):
			var keys = TILESETS.keys()
			if keys.size() > 0:
				activate_tileset(keys[0])

func has_tileset(name : String):
	return TILESETS.has(name)

func get_active_tileset_name():
	if active_tileset != null:
		return active_tileset
	return ""

func get_definition(name : String = ""):
	if name == "" and active_tileset != null:
		name = active_tileset
		
	if TILESETS.has(name):
		return TILESETS[name]
	return null


func activate_tileset(name : String):
	if TILESETS.has(name):
		active_tileset = name
		emit_signal("tileset_activated", TILESETS[name])


func meta_tile_exists(def, meta_name):
	if def.has("metas"):
		return def.metas.has(meta_name)

func get_meta_icon(def, meta_name):
	if meta_tile_exists(def, meta_name):
		return def.metas[meta_name].icon
	return -1

func get_meta_size(def, meta_name):
	if meta_tile_exists(def, meta_name):
		return Vector2(def.metas[meta_name].size[0], def.metas[meta_name].size[1])
	return Vector2.ZERO

func get_meta_tiles(def, meta_name):
	if meta_tile_exists(def, meta_name):
		return def.metas[meta_name].tiles
	return []

func get_meta_exit_info(def, meta_name, x=0, y=0):
	if meta_tile_exists(def, meta_name):
		if def.metas[meta_name].has("exit"):
			var mte = def.metas[meta_name].exit
			return {
				"position": Vector2(
					(x + mte.x) * def.size,
					(y + mte.y) * def.size
				),
				"type": mte.type,
				"size": Vector2(
					mte.size[0] * def.size,
					mte.size[1] * def.size
				)
			}
		else:
			var size = get_meta_size(def, meta_name) * def.size
			return {
				"position": Vector2(
					x * def.size,
					y * def.size
				),
				"type": "circle",
				"size": size
			}
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
					_load_tileset_def(dir.get_current_dir() + "/" + file_name + "/", "def.json")
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


func _validate_meta_tile(def, meta_name):
	var meta = def.metas[meta_name]
	if not meta.has("size"):
		print("Meta tile missing size.")
		return false
	if typeof(meta.size) != TYPE_ARRAY and meta.size.size() != 2:
		print("Meta tile size invalid.")
		return false
	if not meta.has("tiles"):
		print("meta tile missing tile ids")
		return false
	if typeof(meta.tiles) != TYPE_ARRAY && meta.tiles.size() != meta.size[0] * meta.size[1]:
		print("Meta tile tile id list does not match size.")
		return false
	if not meta.has("icon"):
		print("Meta tile missing icon tile id.")
		return false
	if typeof(meta.icon) != TYPE_REAL:
		print("Meta tile icon id invalid type.")
		return false
	meta.icon = floor(meta.icon)
	if meta.icon < 0:
		print("Meta tile icon id out of bounds.")
		return false
	
	if meta.has("exit"):
		var einfo = meta.exit;
		if not einfo.has("x"):
			print("Meta tile exit info missing 'x' parameter.")
			return false
		if typeof(einfo.x) != TYPE_REAL:
			print("Meta tile exit info 'x' parameter contains invalid data type.")
			return false
		if not einfo.has("y"):
			print("Meta tile exit info missing 'y' parameter.")
			return false
		if typeof(einfo.y) != TYPE_REAL:
			print("Meta tile exit info 'y' parameter contains invalid data type.")
			return false
		if not einfo.has("size"):
			print("Meta tile exit info missing 'size' parameter")
			return false
		if typeof(einfo.size) != TYPE_ARRAY:
			print("Meta tile exit info 'size' parameter contains invalid data type.")
			return false
		if einfo.size.size() != 2:
			print("Meta tile exit info 'size' must only contains two values.")
			return false
		if not einfo.has("type"):
			print("Meta tile exit info missing 'type' parameter")
			return false
		if typeof(einfo.type) != TYPE_STRING:
			print("Meta tile exit info 'type' must be a string");
			return false
		if einfo.type != "circle" and einfo.type != "rect":
			print("Meta tile exit info 'type' unknown. Expecting 'circle' or 'rect'.")
			return false
	return true


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
	
	if def.has("metas"):
		for key in def.metas.keys():
			if not _validate_meta_tile(def, key):
				# TODO: Send to a error/warning manager?
				print("WARNING: Failed to parse meta tile [", key, "].")
				def.metas.erase(key)
		# NOTE: When validating floors, check if meta tile exists.
	
	# TODO: Validate the .walls attribute is all integers
	# TODO: Validate the .floors sub-attribute
	TILESETS[def.name] = def
	
	return true



