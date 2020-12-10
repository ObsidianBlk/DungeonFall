tool
extends KinematicBody2D


signal dead

const PIXELS_PER_UNIT = 16
const UNITS_PER_SECOND = 4


enum ACTION {DOWN=0, UP=1, LEFT=2, RIGHT=3}


export var up_texture : Resource = null
export var down_texture : Resource = null
export var right_texture : Resource = null
export var map_node_path : NodePath = "" setget _set_map_node_path
export(float, 0.0, 200.0) var max_hp = 100.0
export(ACTION) var facing = ACTION.DOWN setget _set_facing


var alive = false
var hp = 0
var map_node = null
var velocity = Vector2.ZERO
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
		return map_node.is_over_pit(global_position)
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
	
	velocity = velocity.normalized() * (PIXELS_PER_UNIT * UNITS_PER_SECOND * delta)
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




