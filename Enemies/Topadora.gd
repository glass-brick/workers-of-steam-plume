extends "res://Enemies/EnemyA.gd"


func all_state_process(_delta, _meta):
	var player = get_node('/root/World/PlayerMove')
	$Sprite.look_at(player.global_position)
	$Sprite.rotation -= PI/2
