extends KinematicBody2D

export (int) var speed = 400
export (int) var health = 100
export (int) var iframe_time = 2
export (float) var blinking_speed = 0.05

var projectile_speed = 100
var projectile_damage = 10

var velocity = Vector2(0,0)
var iframe_active = false
var iframe_counter = 0

var projectileBase = preload("res://Common/Projectile.tscn")
enum PlayerStates { UNLOCKED, DEAD }
var current_state = PlayerStates.UNLOCKED

onready var sprite = $Sprite

func get_input():
	var shoot = Input.is_action_just_pressed("shoot")

	if shoot:
		var direction = ( get_global_mouse_position() - global_position).normalized()

		var projectile = projectileBase.instance()
		projectile.speed = projectile_speed
		projectile.damage = projectile_damage
		projectile.direction = direction
		get_tree().get_root().add_child(projectile)
		projectile.global_position = global_position
	
	
func _physics_process(_delta):
	if current_state == PlayerStates.UNLOCKED:
		get_input()

func _on_hit(damageTaken, _attacker):
	if not current_state == PlayerStates.DEAD:
		self.health = max(self.health - damageTaken, 0)
		if health <= 0:
			current_state = PlayerStates.DEAD
		else:
			self.iframe_active = true
