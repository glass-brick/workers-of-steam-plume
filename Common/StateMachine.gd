class_name StateMachine

enum Sides { FORWARDS, BACKWARDS }

var current_state
var current_side = Sides.FORWARDS
var current_metadata
var states
var stateFunctions = {}
var entity

func _init(statesEnum, _entity):
	entity = _entity
	states = statesEnum
	for key in statesEnum.keys():
		stateFunctions[statesEnum[key]] = {
			"process": "_process_%s" % key.to_lower(),
			"start": "_on_%s_start" % key.to_lower(),
		}

func set_state(new_state):
	current_state = new_state
	current_metadata = null
	trigger_state_change()

func trigger_state_change():
	var change_func = stateFunctions[current_state]["start"]
	if not change_func:
		print('UNEXPECTED STATE:', current_state)
	if entity.has_method(change_func):
		entity.call(change_func, current_metadata)

func get_state():
	return current_state

func process_step(delta):
	var process_func = stateFunctions[current_state]["process"]
	if not process_func:
		print('UNEXPECTED STATE:', current_state)
	if entity.has_method(process_func):
		entity.call(process_func, delta, current_metadata)
	if entity.has_method("all_state_process"):
		entity.call("all_state_process", delta, current_metadata)


func set_side(side):
	current_side = side
	if entity.has_method('_on_side_change'):
		entity.call('_on_side_change', current_side)


func get_current_side():
	return current_side

func flip_side():
	set_side(Sides.BACKWARDS if current_side == Sides.FORWARDS else Sides.FORWARDS)
