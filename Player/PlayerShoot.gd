extends KinematicBody2D

export (int) var speed = 400
export (int) var iframe_time = 2
export (float) var blinking_speed = 0.05

var projectile_speed = 400
var projectile_damage = 10

var velocity = Vector2(0,0)

var projectileBase = preload("res://Common/Projectile.tscn")
enum PlayerStates { UNLOCKED, DEAD }
var current_state = PlayerStates.UNLOCKED

var shoot_cooldown = 0.2
var shoot_counter = 0

onready var sprite = $Sprite

func get_input(delta):
	var shoot = Input.is_action_pressed("shoot")

	if shoot_counter >= shoot_cooldown:
		shoot_counter = 0
	elif shoot_counter != 0:
		shoot_counter += delta

	if shoot and shoot_counter == 0:
		var direction = ( get_global_mouse_position() - global_position).normalized()

		var projectile = projectileBase.instance()
		projectile.speed = projectile_speed
		projectile.damage = projectile_damage
		projectile.direction = direction
		get_node('/root/World').add_child(projectile)
		projectile.global_position = global_position
		shoot_counter += delta
	
	
func _physics_process(delta):
	if current_state == PlayerStates.UNLOCKED:
		get_input(delta)

