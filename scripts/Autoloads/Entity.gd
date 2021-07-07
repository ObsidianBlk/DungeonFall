extends Node

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
const ENTITY_DEF_PREFIX = "entity_"
const ENTITY_DEF_EXT = ".json"


# ---------------------------------------------------------------------------
# Variables
# ---------------------------------------------------------------------------
var _Entity : Dictionary = {}
var _Type : Dictionary = {}
var _LoadedEntities : Array = []

# ---------------------------------------------------------------------------
# Method Overrides
# ---------------------------------------------------------------------------

func _ready():
	_load_entities("res://Data/Entities")

# ---------------------------------------------------------------------------
# Private Methods
# ---------------------------------------------------------------------------

func _dict_has_keys(d : Dictionary, keyval : Array) -> bool:
	for kv in keyval:
		var key = kv[0]
		var type = kv[1]
		if not (key in d):
			return false
		if typeof(d[key]) != type:
			return false
	return true

func _file_exists(filepath : String) -> bool:
	var dir : Directory = Directory.new()
	return dir.file_exists(filepath)

func _load_entities(entdef_path : String, depth : int = 4) -> void:
	var file : File = File.new()
	var dir : Directory = Directory.new()
	if dir.open(entdef_path) == OK:
		dir.list_dir_begin()
		var filename : String = dir.get_next()
		while filename != "":
			if filename != "." and filename != "..":
				if dir.current_is_dir():
					if depth > 0 and not filename.begins_with("_"):
						_load_entities(entdef_path + "/" + filename, depth - 1)
				elif filename.begins_with(ENTITY_DEF_PREFIX) and filename.ends_with(ENTITY_DEF_EXT):
					file.open(entdef_path + "/" + filename, File.READ)
					var jsondict : Dictionary = parse_json(file.get_as_text())
					if jsondict:
						_validate_entities_dict(jsondict)
					file.close()
			filename = dir.get_next()
		dir.list_dir_end()


func _validate_entities_dict(data : Dictionary) -> void:
	for entkey in data:
		if not (entkey in _Entity):
			var newent = {
				"desc" : "",
				"obj-src" : "",
				"obj" : null,
				"icon-src" : "",
				"icon-region" : {},
				"type" : []
			}
			var res = _dict_has_keys(data[entkey], [
				["desc", TYPE_STRING],
				["obj-src", TYPE_STRING],
				["icon-src", TYPE_STRING],
				["icon-region", TYPE_DICTIONARY], #{"x": 0, "y": 0, "w": 16, "h": 16},
				["type", TYPE_ARRAY] #["pickup"]
			])
			if res:
				var obj_exists = _file_exists(data[entkey]["obj-src"])
				if not obj_exists:
					print("[WARNING] Entity '", entkey, "' object source not found.")
				var icon_exists = _file_exists(data[entkey]["icon-src"])
				if not icon_exists:
					print("[WARNING] Entity '", entkey, "' icon source not found.")
				res = _dict_has_keys(data[entkey]["icon-region"], [
					["x", TYPE_REAL],
					["y", TYPE_REAL],
					["w", TYPE_REAL],
					["h", TYPE_REAL]
				])
				if obj_exists and icon_exists and res:
					newent.desc = data[entkey].desc
					newent["obj-src"] = data[entkey]["obj-src"]
					newent["icon-src"] = data[entkey]["icon-src"]
					newent["icon-region"] = data[entkey]["icon-region"]
					for type_name in data[entkey].type:
						if typeof(type_name) == TYPE_STRING and type_name != "":
							type_name = type_name.to_lower()
							newent.type.append(type_name)
							if not (type_name in _Type):
								_Type[type_name] = []
							_Type[type_name].append(entkey)
					if newent.type.size() > 0:
						_Entity[entkey] = newent
					else:
						print("[WARNING] Entity '", entkey, "' missing type information.")
				else:
					print("[WARNING] Entity '", entkey, "' icon region invalid.")
		else:
			print("[WARNING] Entity with name '", entkey, "' already stored in system. Skipping.")

# ---------------------------------------------------------------------------
# Public Methods
# ---------------------------------------------------------------------------

func get_entity_types() -> Array:
	return _Type.keys()

func has(key : String) -> bool:
	return key in _Entity

func get(key : String) -> Dictionary:
	if key in _Entity:
		var item = _Entity[key]
		var ir = null
		if item["icon-region"]:
			var reg = item["icon-region"]
			ir = {
				"x": reg.x,
				"y": reg.y,
				"w": reg.w,
				"h": reg.h
			}
		return {
			"name" : key,
			"desc" : item.desc,
			"obj-src" : item["obj-src"],
			"obj" : item.obj,
			"icon-src" : item["icon-src"],
			"icon-region" : ir
		}
	return {"name": ""}

func of_type(type_name : String) -> Array:
	var elist = []
	if type_name in _Type:
		for key in _Type[type_name]:
			var ent = get(key)
			if ent.name != "":
				elist.append(ent)
	return elist


func get_object(key : String):
	# Returns the entities instanciator
	if key in _Entity:
		var item = _Entity[key]
		if item.obj == null:
			item.obj = load(item["obj-src"])
			if not item.obj:
				# TODO: Maybe identify that loading failed the first time and don't keep trying
				item.obj = null
				print("ERROR: Failed to load _Entity '", key, "' object at '", item["obj-src"], "'.")
			else:
				_LoadedEntities.append(key)
		return item.obj
	return null


func clear_loaded():
	for key in _LoadedEntities:
		if key in _Entity:
			var item = _Entity[key]
			item.obj = null
	_LoadedEntities = []



