extends "res://Enemies/EnemyA.gd"


func all_state_process(_delta, _meta):
	var player = get_node('/root/World/PlayerMove')
	$SpriteGuy1.look_at(player.global_position)
	$SpriteGuy2.look_at(player.global_position)

func _on_shooting_start(_meta):
	if $disparo:
		$disparo.play()
	for guy in [$SpriteGuy1, $SpriteGuy2]:
		var direction = get_target_shoot_direction_from(guy.global_position)
		var projectile = projectileBase.instance()
		projectile.speed = projectile_speed
		projectile.damage = projectile_damage
		projectile.direction = direction
		get_node('/root/World').add_child(projectile)
		projectile.global_position = guy.global_position
	shoot_timer = 0
