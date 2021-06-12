extends "res://Enemies/EnemyA.gd"


func all_state_process(_delta, _meta):
	var player = get_node('/root/World/PlayerMove')
	$SpriteGuy1.look_at(player.global_position)
	$SpriteGuy2.look_at(player.global_position)
