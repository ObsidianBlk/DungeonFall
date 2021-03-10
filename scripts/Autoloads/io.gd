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


func _ByteArray2Int(ba : PoolByteArray, byteCount = 0, offset = 0):
	if ba.size() <= 0 or offset < 0 or offset >= ba.size():
		return 0
	if byteCount == 0:
		byteCount = ba.size() - offset
		if byteCount > 8:
			byteCount = 8
	if byteCount < 1 or byteCount > 8:
		return 0
	
	var val = 0
	for i in range(offset, offset + byteCount):
		val |= int(ba[i]) << ((i - offset) * 8)
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
				if file_name.get_extension().to_lower() == "dfm":
					var header = readMapData(file_name, true)
					if header:
						maps.append({"file":file_name, "map_name":header.name})
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
			mapData.append_array(_Int2ByteArray(size, 2))
			#mapData.append(int(size) >> 8)
			#mapData.append(size)
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
				mapData.append_array(var2bytes(data.map.exits[i].position.x))
				mapData.append_array(var2bytes(data.map.exits[i].position.y))
				mapData.append_array(var2bytes(data.map.exits[i].size.x))
				mapData.append_array(var2bytes(data.map.exits[i].size.y))
				val = data.map.exits[i].type.to_utf8()
				mapData.append(val.size())
				mapData.append_array(val)
			
			# Store uncompressed size
			file.store_64(mapData.size())
			mapData = mapData.compress(File.COMPRESSION_GZIP)
			# Store compressed size
			file.store_64(mapData.size())
			file.store_buffer(mapData)
			
			file.close()
			return true
	
	return false


func readMapData(filePath : String, headerOnly : bool = false):
	var file = File.new()
	var status = file.open(filePath, File.READ)
	if status == OK:
		var data = {}
		var id = file.get_buffer(5)
		if id.get_string_from_ascii() != "DFMAP":
			print("READ MAP ERROR: ID does not match 'DFMAP'.")
			return null
		data.version = Array(file.get_buffer(3))
		if data.version[0] != 0 or data.version[1] != 1 or data.version[2] != 0:
			print("READ MAP ERROR: Version mismatch.")
			return null
		var size = file.get_16()
		data.name = file.get_buffer(size).get_string_from_utf8()
		
		if headerOnly:
			file.close()
			return data
		
		data.map = {}
		
		var ucsize = file.get_64()
		var csize = file.get_64()
		
		var mapData = file.get_buffer(csize)
		var index = 0
		mapData = mapData.decompress(ucsize, File.COMPRESSION_GZIP)
		if mapData.size() != ucsize:
			print("READ MAP ERROR: Uncompressed map data size invalid.")
			return null
		
		size = _ByteArray2Int(mapData, 2, index)
		index += 2
		
		data.map.tileset_name = mapData.subarray(index, index + (size-1)).get_string_from_utf8()
		index += size
		
		data.map.player_start = Vector2.ZERO
		data.map.player_start.x = bytes2var(mapData.subarray(index, index+7))
		index += 8
		data.map.player_start.y = bytes2var(mapData.subarray(index, index+7))
		index += 8
		
		
		# ----- Loading Floor tile data
		size = _ByteArray2Int(mapData, 4, index)
		index += 4
		data.map.floors = []
		for i in range(0, size):
			var x = _ByteArray2Int(mapData, 4, index)
			index += 4
			var y = _ByteArray2Int(mapData, 4, index)
			index += 4
			var idx = mapData[index]
			index += 1
			data.map.floors.append({"x":x, "y":y, "idx":idx})
		
		# ----- Loading Wall tile data
		size = _ByteArray2Int(mapData, 4, index)
		index += 4
		data.map.walls = []
		for i in range(0, size):
			var x = _ByteArray2Int(mapData, 4, index)
			index += 4
			var y = _ByteArray2Int(mapData, 4, index)
			index += 4
			var idx = mapData[index]
			index += 1
			data.map.walls.append({"x":x, "y":y, "idx":idx})
		
		# ----- Loading dungeon exit information
		size = mapData[index] #_ByteArray2Int(mapData, 4, index)
		index += 1
		data.map.exits = []
		for i in range(0, size):
			var x = bytes2var(mapData.subarray(index, index + 7))
			index += 8
			var y = bytes2var(mapData.subarray(index, index + 7))
			index += 8
			var sa = mapData.subarray(index, index + 7)
			var sizex = bytes2var(mapData.subarray(index, index + 7))
			index += 8
			var sizey = bytes2var(mapData.subarray(index, index + 7))
			index += 8
			var tsize = mapData[index]
			index += 1
			var type = mapData.subarray(index, index + (tsize-1)).get_string_from_utf8()
			index += tsize
			
			# TODO: Validate type = "circle" or "rect"
			# TODO: Validate position ON a floor tile
			# TODO: Validate size x and y are both positive!
			
			data.map.exits.append({
				"position": Vector2(x, y),
				"size":Vector2(sizex, sizey),
				"type":type
			})
		
		return data
	
	print("ERROR: Failed to open map file.")
	return null



