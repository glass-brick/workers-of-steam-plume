extends Node2D

export (Array, PackedScene) var enemy_groups
export (Array, int) var max_time_intervals

var current_group_index = 0
var time_since_last_group = 0

func _ready():
	start_group()

func start_group():
	var enemy_group_scene = enemy_groups[current_group_index].instance()
	add_child(enemy_group_scene)
	time_since_last_group = 0

func _process(delta):
	time_since_last_group += delta
	if time_since_last_group > max_time_intervals[current_group_index] and enemy_groups.size() > current_group_index + 1:
		current_group_index += 1
		start_group()
