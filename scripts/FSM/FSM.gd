extends Node


export var initial_state : String = ""

var state_map = {}
var cur_state = null
var paused = false
var proc_handlers = true

func process_handlers(e : bool = true):
	proc_handlers = e
	set_process_input(e)
	set_process(e)
	set_physics_process(e)

func processing_handlers():
	return proc_handlers

func pause():
	if not paused:
		paused = true
		if cur_state != null:
			state_map[cur_state].pause()

func resume():
	if paused:
		paused = false
		if cur_state != null:
			state_map[cur_state].resume(get_parent())

func is_paused():
	return paused

func _ready():
	for child in get_children():
		if child is State:
			state_map[child.name] = child
			child.connect("finished", self, "_on_state_finished")
			if cur_state == null and initial_state == "":
				initial_state = child.name

	if initial_state != "":
		if not _change_state(initial_state):
			print("WARNING: FSM Initial state '", initial_state, "' not in state map.")

func _input(event):
	if cur_state != null:
		state_map[cur_state].handle_input(event)

func _process(delta):
	if cur_state != null:
		state_map[cur_state].handle_update(delta)

func _physics_process(delta):
	if cur_state != null:
		state_map[cur_state].handle_physics(delta)


func _change_state(statename : String):
	if not (statename in state_map):
		return false
	
	if statename != cur_state:
		var state = null
		if cur_state != null:
			state = state_map[cur_state]
			state.exit() # exit old state
		
		cur_state = statename
		state = state_map[statename]
		
		# enter new state
		state.enter(get_parent())
		if paused:
			state.pause()
	
	return true


func _on_state_finished(next_state):
	if not _change_state(next_state):
		print("WARNING: State '", cur_state, "' attempted to switch to non-existant state '", next_state, "'. No change made.")


