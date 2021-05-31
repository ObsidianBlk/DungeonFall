extends Control


onready var tab_pickups = $MC/vbox/Tabs/Pickups
onready var tab_traps = $MC/vbox/Tabs/Traps
onready var tab_monsters = $MC/vbox/Tabs/Monsters


func _add_entity_btns(tab : Control, entity_type : String) -> void:
	var entlist = Entity.of_type(entity_type)
	if entlist.size() <= 0:
		return
	
	var lcn = tab.get_node("MC/Cols/Left")
	var rcn = tab.get_node("MC/Cols/Right")
	var placeleft = true
	
	for ent in entlist:
		var tex = AtlasTexture.new()
		tex.atlas = load(ent["icon-src"])
		if ent["icon-region"] != null:
			var r = ent["icon-region"]
			tex.region = Rect2(r.x, r.y, r.w, r.h)
		else:
			var size = tex.atlas.get_size()
			tex.region = Rect2(0, 0, size.x, size.y)
		
		var btn = Button.new()
		
		if placeleft:
			lcn.add_child(btn)
		else:
			rcn.add_child(btn)
		placeleft = not placeleft

		btn.icon = tex
		btn.expand_icon = true
		btn.rect_min_size = Vector2(128, 128)
		btn.connect("pressed", self, "_on_btn_pressed", [ent.name])


func _ready():
	_add_entity_btns(tab_pickups, "pickup")
	_add_entity_btns(tab_traps, "trap")
	_add_entity_btns(tab_monsters, "monster")


func _on_btn_pressed(entity_name : String) -> void:
	print("Entity: ", entity_name)
	hide()


func _on_Close_pressed():
	hide()


