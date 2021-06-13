extends Node2D

signal group_finished

var enemies_in_group = 0
var enemies_dead = 0


func _ready():
	for node in get_children():
		if node is Path2D:
			for subnode in node.get_children():
				enemies_in_group += 1
				subnode.connect("died", self, "_on_enemy_dead")
		else:
			enemies_in_group += 1
			node.connect("died", self, "_on_enemy_dead")


func _process(_delta):
	if get_children().size() == 0:
		queue_free()

func _on_enemy_dead():
	enemies_dead += 1
	if enemies_dead == enemies_in_group:
		emit_signal("group_finished")
