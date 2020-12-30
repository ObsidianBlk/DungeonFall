tool
extends KinematicBody2D


signal dead
signal request_game_pause

const PIXELS_PER_UNIT = 16


enum ACTION {DOWN=0, UP=1, LEFT=2, RIGHT=3}


export var up_texture : Resource = null
export var down_texture : Resource = null
export var right_texture : Resource = null
export var map_node_path : NodePath = "" setget _set_map_node_path
export(int, 1, 1000) var units_per_second = 4
export(float, 0.0, 200.0) var max_hp = 100.0
export(int, 0, 16) var footprint = 2 # In pixels
export(float, 0.1) var jump_height_time = 0.5 # in seconds
export(float, 0.0) var jump_coyote_time = 0.25 # in seconds
export(float, 0.1) var jump_scale_delta = 0.1 # The change in scale from baseline to max jump height.
export(float, 0.0) var jump_position_delta = 6.0 # The change in position in pixels from baseline to max jump height.
export(ACTION) var facing = ACTION.DOWN setget _set_facing


var alive = false
var hp = 0
var map_node = null
var velocity = Vector2.ZERO
var jump_time = 0.0
var coyote_time = 0.0
var inair = false
var action_state = [false, false, false, false]
var ready = false


func _set_map_node_path(mnp : NodePath, force : bool = false):
	if mnp != map_node_path or force:
		if ready and mnp != "":
			var mn = get_node(mnp)
			if mn != null:
				map_node = mn
				map_node_path = mnp
		else:
			map_node_path = mnp
			map_node = null


func _set_facing(f : int, force : bool = false):
	if f != facing or force:
		facing = f
		if ready:
			match(facing):
				ACTION.DOWN:
					if down_texture != null:
						$Body.texture = down_texture
						$Body.flip_h = false
				ACTION.UP:
					if up_texture != null:
						$Body.texture = up_texture
						$Body.flip_h = false
				ACTION.LEFT:
					if right_texture != null:
						$Body.texture = right_texture
						$Body.flip_h = true
				ACTION.RIGHT:
					if right_texture != null:
						$Body.texture = right_texture
						$Body.flip_h = false


func _ready():
	$AnimationTree.active = true # This is just in case I accidently disable it.
	ready = true
	if map_node_path != "":
		_set_map_node_path(map_node_path, true)
	_set_facing(facing, true)
	revive()

func die():
	alive = false
	emit_signal("dead")

func revive():
	alive = true
	hp = max_hp
	action_state = [false, false, false, false]

func jump():
	if not inair:
		coyote_time = 0.0
		jump_time = jump_height_time
		inair = true

func update_inair(delta : float):
	if inair:
		jump_time -= delta
		if jump_time <= -jump_height_time:
			inair = false
			jump_time = 0.0
			set_sprite_jump_scale(0.0)
	elif is_over_pit():
		if coyote_time < jump_coyote_time:
			coyote_time += delta

func can_jump():
	return not inair and (not is_over_pit() or coyote_time < jump_coyote_time)

# delta_height - 0 to 1 of the scale factor
# delta_pos - Vector2 change in position from baseline
# delta_scale - The change in scale from baseline
func set_sprite_jump_scale(delta_height : float):
	var scale = 1.0 + (jump_scale_delta * delta_height)
	$Body.scale = Vector2(scale, scale)
	$Body.position = Vector2(0.0, -jump_position_delta) * delta_height

func set_anim_param(param, val):
	if ready:
		$AnimationTree.set(param, val)

func get_anim_param(param):
	if ready:
		return $AnimationTree.get(param)
	return null

func set_action(id : int, e : bool):
	if id >= 0 and id < action_state.size():
		action_state[id] = e

func is_action(id : int):
	if id >= 0 and id < action_state.size():
		return action_state[id]
	return false

func is_moving_v():
	return action_state[ACTION.UP] != action_state[ACTION.DOWN]

func is_moving_h():
	return action_state[ACTION.LEFT] != action_state[ACTION.RIGHT]


func is_over_pit():
	if map_node != null and map_node.has_method("is_over_pit"):
		return map_node.is_over_pit(global_position, footprint)
	return false

func move(delta, dx, dy):
	if dx == 0:
		velocity.x = 0.0
	else:
		if dx < 0:
			dx = -1
		else:
			dx = 1
		velocity.x = dx
	
	if dy == 0:
		velocity.y = 0.0
	else:
		if dy < 0:
			dy = -1
		else:
			dy = 1
		velocity.y = dy
	
	velocity = velocity.normalized() * (PIXELS_PER_UNIT * units_per_second * delta)
	#print("Velocity: ", velocity)
	update_facing() # Not sure if I'll keep this here


func update_facing():
	if velocity.length() > 0:
		if abs(velocity.x) > abs(velocity.y):
			if velocity.x > 0.0:
				_set_facing(ACTION.RIGHT)
			else:
				_set_facing(ACTION.LEFT)
		else:
			if velocity.y > 0.0:
				_set_facing(ACTION.DOWN)
			else:
				_set_facing(ACTION.UP)


func request_game_pause():
	emit_signal("request_game_pause")



