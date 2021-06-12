extends Node2D

signal group_finished

func _process(_delta):
	if get_children().size() == 0:
		emit_signal("group_finished")
		queue_free()
