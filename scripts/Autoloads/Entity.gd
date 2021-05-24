extends Node

var _Entity = {
	"Coin" : {
		"desc" : "An singular coin. Oooo... shiney",
		"obj-src" : "res://objects/gold/Gold.gd",
		"obj" : null,
		"icon-src" : "res://assets/graphics/objects/Coin.png",
		"icon-region" : {"x": 0, "y": 0, "w": 16, "h": 16},
		"type" : ["pickup"]
	}
}

var _Type = {}
var _LoadedEntities = []

func _ready():
	for key in _Entity:
		var item = _Entity[key]
		for type in item["type"]:
			if not type in _Type:
				_Type[type] = []
			_Type[type].append(key)


func of_type(type_name : String) -> Array:
	var elist = []
	if type_name in _Type:
		for key in _Type[type_name]:
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
				elist.append({
					"name" : key,
					"desc" : item.desc,
					"obj-src" : item["obj-src"],
					"obj" : item.obj,
					"icon-src" : item["icon-src"],
					"icon-region" : ir
				})
	return elist


func get_object(key : String):
	if key in _Entity:
		var item = _Entity[key]
		if item.obj == null:
			item.obj = load(item["obj-src"])
			if not item.obj:
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



