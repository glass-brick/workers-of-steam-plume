extends "res://Enemies/EnemyA.gd"


func all_state_process(delta, meta):
	$SpriteGuy1.rotation = self.get_target_shoot_direction_from($SpriteGuy1.position).angle() + PI
	$SpriteGuy2.rotation = self.get_target_shoot_direction_from($SpriteGuy2.position).angle() + PI
