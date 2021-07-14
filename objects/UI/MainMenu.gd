extends "res://scripts/UI/SimpleUI.gd"

signal dungeon_run
signal dungeon_editor
signal game_options
signal game_escape

export var hide_on_operation : bool = false
export var inst_toggle_time : float = 0.75		setget _set_inst_toggle_time 

var tween = null

onready var version_lbl = $Menu/Panel/VBC/Heading/Version/Number
onready var instr_node : MarginContainer = $Instructions
onready var btn_run = $Menu/Panel/VBC/Buttons/BTN_Run

func _set_inst_toggle_time(t : float) -> void:
	if t > 0.0:
		inst_toggle_time = t


func _ready() -> void:
	version_lbl.text = Version.toString()
	
	var rect = instr_node.get_rect()
	instr_node.rect_global_position -= Vector2(rect.size.x, 0)
	
	tween = Tween.new()
	add_child(tween)


func _on_change_visible(e : bool, uiname : String = ""):
	if uiname == "" or uiname == name:
		visible = e
		if visible and btn_run:
			btn_run.grab_focus()

func _on_BTN_Run_pressed():
	if hide_on_operation:
		visible = false
	emit_signal("dungeon_run")


func _on_BTN_DungEditor_pressed():
	if hide_on_operation:
		visible = false
	emit_signal("dungeon_editor")


func _on_BTN_Escape_pressed():
	if hide_on_operation:
		visible = false
	emit_signal("game_escape")


func _on_BTN_Options_pressed():
	emit_signal("game_options")


func _on_BTN_Instruction_toggled(button_pressed : bool) -> void:
	var pos = instr_node.rect_global_position
	var size = instr_node.rect_size
	if size.length_squared() <= 0 or tween == null:
		return;
	
	var target_pos = Vector2.ZERO
	if button_pressed:
		target_pos = Vector2(0, pos.y)
	else:
		target_pos = Vector2(-size.x, pos.y)
		
	var d = pos.distance_to(target_pos)
	var ptt = (d/size.x) # Percent To Target (PTT)
	
	tween.stop_all()
	tween.remove_all()
	
	tween.interpolate_property(
		instr_node, "rect_global_position",
		pos, target_pos,
		inst_toggle_time * ptt,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
	)
	
	tween.start()
