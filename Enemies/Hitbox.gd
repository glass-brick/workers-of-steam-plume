extends Area2D

signal hit

func _on_hit(damage, source):
	emit_signal("hit", damage, source)
