extends Control

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
signal entity_selected(entity_name)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
const MARGIN_SIZE = 10


# ---------------------------------------------------------------------------
# Node Variables
# ---------------------------------------------------------------------------
onready var tabs_node : TabContainer = $MC/vbox/Tabs

# ---------------------------------------------------------------------------
# Method Overrides
# ---------------------------------------------------------------------------
func _ready():
	_build_tabs()
	#_add_entity_btns(tab_pickups, "pickup")
	#_add_entity_btns(tab_traps, "trap")
	#_add_entity_btns(tab_monsters, "monster")

# ---------------------------------------------------------------------------
# Private Methods
# ---------------------------------------------------------------------------
func _build_tabs():
	var entity_types = Entity.get_entity_types()
	for etype in entity_types:
		var tab : Tabs = Tabs.new()
		tab.name = etype.capitalize()
		var mc : MarginContainer = MarginContainer.new()
		mc.name = "MC"
		mc.add_constant_override("margin_top", MARGIN_SIZE)
		mc.add_constant_override("margin_bottom", MARGIN_SIZE)
		mc.add_constant_override("margin_left", MARGIN_SIZE)
		mc.add_constant_override("margin_right", MARGIN_SIZE)
		var cols : HBoxContainer = HBoxContainer.new()
		cols.name = "Cols"
		var left : VBoxContainer = VBoxContainer.new()
		left.name = "Left"
		left.size_flags_horizontal = SIZE_EXPAND_FILL
		var right : VBoxContainer = VBoxContainer.new()
		right.name = "Right"
		right.size_flags_horizontal = SIZE_EXPAND_FILL
		
		tabs_node.add_child(tab)
		tab.add_child(mc)
		mc.add_child(cols)
		cols.add_child(left)
		cols.add_child(right)
		_add_entity_btns(tab, etype)


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

# ---------------------------------------------------------------------------
# Public Methods
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Handler Methods
# ---------------------------------------------------------------------------
func _on_btn_pressed(entity_name : String) -> void:
	hide()
	emit_signal("entity_selected", entity_name)


func _on_Close_pressed():
	hide()


