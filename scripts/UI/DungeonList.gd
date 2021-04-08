extends Container


signal dungeon_selected
signal cancel
signal load_dungeon(path)
signal delete_dungeon(name, path)

export var Allow_Dungeon_Deletion: bool = true

onready var tree_node = $VBoxContainer/Tree
onready var btn_load = $VBoxContainer/HBoxContainer/HBoxContainer/BTN_LoadDungeon
onready var btn_delete = $VBoxContainer/HBoxContainer/HBoxContainer/BTN_DeleteDungeon

var selected_dungeon = null

func _ready():
	if not Allow_Dungeon_Deletion:
		btn_delete.visible = false
	requery_tree()
	#var dungeons = Io.getAvailableMaps()
	
	#var root = tree_node.create_item()
	#for i in range(0, dungeons.size()):
	#	var item = tree_node.create_item(root)
	#	item.set_text(i, dungeons[i].dungeon_name)


func _Dict2Tree(parent : TreeItem, d : Dictionary):
	var keys = d.keys()
	
	if "__DUNGEONS__" in d:
		for i in range(0, d["__DUNGEONS__"].size()):
			var dungeon = d["__DUNGEONS__"][i]
			var item = tree_node.create_item(parent)
			item.set_text(0, dungeon.name)
			item.set_metadata(0, dungeon)
	
	for i in range(0, keys.size()):
		if keys[i] != "__DUNGEONS__":
			var item = tree_node.create_item(parent)
			item.set_text(0, keys[i])
			item.set_selectable(0, false)
			item.collapsed = true
			_Dict2Tree(item, d[keys[i]])


func requery_tree():
	if tree_node == null:
		return
		
	tree_node.clear()
	var dtree = Io.getDungeonPathTree()
	if dtree != null:
		selected_dungeon = null
		btn_load.disabled = true
		btn_delete.disabled = true
			
		var root = tree_node.create_item()
		root.set_text(0, "Dungeons")
		_Dict2Tree(root, dtree)



func get_selected():
	return selected_dungeon


func _on_dungeon_selected():
	var item = tree_node.get_selected()
	if item:
		selected_dungeon = item.get_metadata(0)
		if selected_dungeon:
			btn_load.disabled = false
			btn_delete.disabled = false


func _on_visibility_changed():
	if visible:
		requery_tree()


func _on_LoadDungeon_pressed():
	if selected_dungeon != null:
		emit_signal("load_dungeon", selected_dungeon.path + "/" + selected_dungeon.file)


func _on_DeleteDungeon_pressed():
	if selected_dungeon != null:
		emit_signal("delete_dungeon", selected_dungeon.name, selected_dungeon.path + "/" + selected_dungeon.file)


func _on_Reload_pressed():
	requery_tree()


func _on_cancel_pressed():
	emit_signal("cancel")
