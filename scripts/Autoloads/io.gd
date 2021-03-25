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
	return {"offset":offset + byteCount, "value":val}

func _Var2Bytes(v):
	var buff = PoolByteArray()
	var vbuff = var2bytes(v)
	print("Storing variable buffer of size: ", vbuff.size())
	buff.append(vbuff.size())
	buff.append_array(vbuff)
	print("Buffered first value as: ", buff[0])
	return buff

func _Bytes2UTF8(ba : PoolByteArray, size, offset = 0):
	var v = ba.subarray(offset, offset + (size - 1)).get_string_from_utf8()
	return {"offset":offset + size, "value":v}

func _Bytes2Var(ba : PoolByteArray, offset = 0):
	print("Extracting at offset: ", offset)
	var size = ba[offset]
	offset += 1
	print("Extracting ", size, " bytes for variable")
	var v = bytes2var(ba.subarray(offset, offset + (size - 1)))
	return {"offset":offset + size, "value" : v}


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
			mapData.append_array(_Var2Bytes(data.map.player_start.x))
			mapData.append_array(_Var2Bytes(data.map.player_start.y))
			
			var bytes = _Var2Bytes(data.map.tile_break_time)
			mapData.append_array(bytes)
			mapData.append_array(_Var2Bytes(data.map.tile_break_variance))
			
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
				mapData.append_array(_Var2Bytes(data.map.exits[i].position.x))
				mapData.append_array(_Var2Bytes(data.map.exits[i].position.y))
				mapData.append_array(_Var2Bytes(data.map.exits[i].size.x))
				mapData.append_array(_Var2Bytes(data.map.exits[i].size.y))
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
		var res = null
		mapData = mapData.decompress(ucsize, File.COMPRESSION_GZIP)
		if mapData.size() != ucsize:
			print("READ MAP ERROR: Uncompressed map data size invalid.")
			return null
		
		res = _ByteArray2Int(mapData, 2, 0)
		
		res = _Bytes2UTF8(mapData, res.value, res.offset)
		data.map.tileset_name = res.value
		print(res)
		#data.map.tileset_name = mapData.subarray(index, index + (size-1)).get_string_from_utf8()
		#index += size
		
		data.map.player_start = Vector2.ZERO
		#res = _ByteArray2Int(mapData, 1, res.offset)
		#print(res)

		res = _Bytes2Var(mapData, res.offset)
		data.map.player_start.x = res.value
		print(res)

		res = _Bytes2Var(mapData, res.offset)
		data.map.player_start.y = res.value
		print(res)
		
		res = _Bytes2Var(mapData, res.offset)
		data.map.tile_break_time = res.value
		print(res)
		
		res = _Bytes2Var(mapData, res.offset)
		data.map.tile_break_variance = res.value
		print(res)
		
		
		# ----- Loading Floor tile data
		res = _ByteArray2Int(mapData, 4, res.offset)
		size = res.value
		print(res)
		
		data.map.floors = []
		for i in range(0, size):
			res = _ByteArray2Int(mapData, 4, res.offset)
			var x = res.value
			
			res = _ByteArray2Int(mapData, 4, res.offset)
			var y = res.value

			res = _ByteArray2Int(mapData, 1, res.offset)
			var idx = res.value

			data.map.floors.append({"x":x, "y":y, "idx":idx})
		
		# ----- Loading Wall tile data
		res = _ByteArray2Int(mapData, 4, res.offset)
		size = res.value
		
		data.map.walls = []
		for i in range(0, size):
			res = _ByteArray2Int(mapData, 4, res.offset)
			var x = res.value
			
			res = _ByteArray2Int(mapData, 4, res.offset)
			var y = res.value

			res = _ByteArray2Int(mapData, 1, res.offset)
			var idx = res.value
			
			data.map.walls.append({"x":x, "y":y, "idx":idx})
		
		# ----- Loading dungeon exit information
		res = _ByteArray2Int(mapData, 1, res.offset)
		size = res.value
		
		data.map.exits = []
		for i in range(0, size):
			res = _Bytes2Var(mapData, res.offset)
			var x = res.value
			
			res = _Bytes2Var(mapData, res.offset)
			var y = res.value

			res = _Bytes2Var(mapData, res.offset)
			var sizex = res.value

			res = _Bytes2Var(mapData, res.offset)
			var sizey = res.value

			res = _ByteArray2Int(mapData, 1, res.offset)
			res = _Bytes2UTF8(mapData, res.value, res.offset)
			var type = res.value
			
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



