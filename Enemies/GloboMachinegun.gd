extends "res://Enemies/EnemyA.gd"

func all_state_process(_delta, _meta):
	var player = get_node('/root/World/PlayerMove')
	$ChineGuy.look_at(player.global_position)
	$ChineGuy.rotation -= PI/2
