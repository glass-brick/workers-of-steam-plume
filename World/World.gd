extends Node2D

export (Array, PackedScene) var enemy_groups
export (Array, int) var max_time_intervals
export (int) var time_to_first = 1

var initialized = false
var current_group_index = 0
var time_since_last_group = 0
var instanced_groups = {}
var groups_between_saves = 3

var groups_defeated = 0

onready var sceneManager = get_node('/root/SceneManager')

func _ready():
	var state = sceneManager.load()
	if state.has("current_group_index"):
		current_group_index = state["current_group_index"]
		groups_defeated = state["current_group_index"]

func start_group():
	var enemy_group_scene = enemy_groups[current_group_index].instance()
	add_child(enemy_group_scene)
	enemy_group_scene.connect('group_finished', self, '_on_group_finish', [current_group_index])
	instanced_groups[current_group_index] = enemy_group_scene
	time_since_last_group = 0

func _on_group_finish(index):
	groups_defeated += 1

	var is_old_group = current_group_index > index
	if is_old_group:
		return
	var has_next_group = enemy_groups.size() > current_group_index + 1
	print(groups_defeated, current_group_index)
	if groups_defeated == current_group_index + 1 and has_next_group:
		current_group_index += 1
		call_deferred("start_group")
		sceneManager.save({ "current_group_index": current_group_index - current_group_index % groups_between_saves })
	
	if groups_defeated == enemy_groups.size():
		yield(get_tree().create_timer(0.5), "timeout")
		sceneManager.goto_scene('res://StaticScreens/WinScreen.tscn')

func process_initial_cooldown(delta):
	if time_to_first > 0:
		time_to_first -= delta
		return
	elif not initialized:
		call_deferred("start_group")
		initialized = true

func _process(delta):
	process_initial_cooldown(delta)

	if max_time_intervals.size() <= current_group_index:
		return

	time_since_last_group += delta
	
	var timeouted = time_since_last_group > max_time_intervals[current_group_index]
	var has_next_group = enemy_groups.size() > current_group_index + 1

	if timeouted and has_next_group:
		current_group_index += 1
		start_group()


