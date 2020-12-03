extends KinematicBody2D

const PIXELS_PER_UNIT = 16
const UNITS_PER_SECOND = 50


enum ACTION {DOWN=0, UP=1, LEFT=2, RIGHT=3}


export var up_texture : Resource = null
export var down_texture : Resource = null
export var right_texture : Resource = null
export(ACTION) var facing = ACTION.DOWN setget _set_facing


var velocity = Vector2.ZERO
var action_state = [false, false, false, false]
var ready = false

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
	ready = true
	_set_facing(facing, true)

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




