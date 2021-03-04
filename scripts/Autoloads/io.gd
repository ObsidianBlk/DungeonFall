extends Node

const MAP_PATH = "maps/"


func initialize():
	var user_paths = [MAP_PATH]
	
	var dir = Directory.new()
	if dir.open("user://") == OK:
		for i in range(0, user_paths.size()):
			if not dir.dir_exists(user_paths[i]):
				dir.make_dir(user_paths[i])


func _Int2ByteArray(v : int, byteCount = 8):
	if byteCount < 1 or byteCount > 8:
		return v
	
	var pool = PoolByteArray()
	for i in range(0, byteCount):
		pool.append(v)
		v = v >> 8
	return pool


func _ByteArray2Int(ba : PoolByteArray):
	if ba.size() <= 0:
		return 0
	
	var val = 0
	for i in range(0, ba.size()):
		val |= int(ba[i]) << (i * 8)
	return val


func _GetAvailableMaps(mapBasePath : String = ""):
	if mapBasePath == "":
		mapBasePath = "user://" + MAP_PATH;
	var maps = []
	
	var dir = Directory.new()
	if dir.open(mapBasePath) == OK:
		dir.list_dir_begin(false, true)
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				maps.append_array(_GetAvailableMaps(dir.get_current_dir() + file_name))
			else:
				pass # TODO: Get map's name
			file_name = dir.get_next()
	
	return maps

func getAvailableMaps():
	return _GetAvailableMaps()

func storeMapData(filePath : String, data):
	if not filePath.is_valid_filename():
		return false
	
	var mapBasePath = "user://" + MAP_PATH;
	
	var dir = Directory.new()
	if dir.open(mapBasePath) == OK:
		var path = filePath.get_base_dir()
		var filename = filePath.get_file()
		if not dir.dir_exists(path):
			dir.make_dir(path)
		dir.change_dir(path)
		
		var file = File.new()
		var status = file.open(dir.get_current_dir() + "/" + filename, File.WRITE)
		if status == OK:
			file.store_buffer("DFMAP".to_ascii())
			file.store_buffer(PoolByteArray(data.version))
			var val = data.name.to_utf8()
			file.store_16(val.size())
			file.store_buffer(val)
			
			var mapData = PoolByteArray()
			val = data.map.tileset_name.to_utf8()
			var size = val.size()
			mapData.append(int(size) >> 8)
			mapData.append(size)
			mapData.append_array(val)
			mapData.append_array(var2bytes(data.map.player_start.x))
			mapData.append_array(var2bytes(data.map.player_start.y))
			
			mapData.append_array(_Int2ByteArray(data.map.floors.size(), 4))
			for i in range(0, data.map.floors.size()):
				mapData.append_array(_Int2ByteArray(data.map.floors[i].x, 4))
				mapData.append_array(_Int2ByteArray(data.map.floors[i].y, 4))
				mapData.append(data.map.floors[i].idx)
			
			mapData.append_array(_Int2ByteArray(data.map.walls.size(), 4))
			for i in range(0, data.map.walls.size()):
				mapData.append_array(_Int2ByteArray(data.map.walls[i].x, 4))
				mapData.append_array(_Int2ByteArray(data.map.walls[i].y, 4))
				mapData.append(data.map.walls[i].idx)
			
			mapData.append(data.map.exits.size())
			for i in range(0, data.map.exits.size()):
				mapData.append_array(var2bytes(data.map.exits[i].x))
				mapData.append_array(var2bytes(data.map.exits[i].y))
				mapData.append_array(var2bytes(data.map.exits[i].size))
			
			# Store uncompressed size
			file.store_64(mapData.size())
			mapData = mapData.compress(File.COMPRESSION_GZIP)
			# Store compressed size
			file.store_64(mapData.size())
			file.store_buffer(mapData)
			
			file.close()
			return true
	
	return false


func readMapHeader(filePath : String):
	var file = File.new()
	var status = file.open(filePath, File.READ)
	if status == OK:
		var id = file.get_buffer(5)
		if id.get_string_from_ascii() != "DFMAP":
			print("READ MAP ERROR: ID does not match 'DFMAP'.")
			return null
		var version = file.get_buffer(3)
		if version[0] != 0 or version[1] != 1 or version[2] != 0:
			print("READ MAP ERROR: Version mismatch.")
			return null
		var size = file.get_16()
		var map_name = file.get_buffer(size).get_string_from_utf8()
		
		return {
			"name": map_name,
			"version": [version[0], version[1], version[2]]
		}
	return null


func readMapData(filePath : String):
	pass
