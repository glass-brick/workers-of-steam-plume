extends KinematicBody2D

enum EnterOptions { TOP, BOTTOM }

export (int) var speed = 20
export (int) var shoot_time = 1
export (int) var move_time = 2
export (EnterOptions) var enter_direction = EnterOptions.TOP

var projectileBase = preload("res://Common/EnemyProjectile.tscn")
var explosion = preload("res://Common/Explosion.tscn")
export (int) var projectile_speed = 400
export (int) var projectile_damage = 10
export (int) var damage = 10
export (int) var reward_points = 5
export (int) var health = 20

export (float) var damage_show_time = 5
var damage_show_timer = 0
var show_damage = false

var shoot_timer = 0
var move_timer = 0

onready var velocity_dir = Vector2(0,1).rotated(self.rotation)

enum BikerStates { ENTER_STAGE, MOVING, SHOOTING, DEAD }
const StateMachine = preload('res://Common/StateMachine.gd')

onready var state_machine = StateMachine.new(BikerStates, self)
enum Sides { FORWARDS, BACKWARDS }
export (Sides) var initial_direction = Sides.FORWARDS

func _ready():
	state_machine.set_state(BikerStates.MOVING)
	state_machine.set_side(initial_direction)

func _process_moving(delta, _meta):
	$Sprite.set_frame(0)
	move_timer += delta
	if move_timer > move_time:
		state_machine.set_state(BikerStates.SHOOTING)
		return
	var velocity = velocity_dir * speed * delta
	var collision = move_and_collide(velocity)
	if collision:
		velocity_dir = velocity.bounce(collision.normal).normalized()
		self.rotation = velocity_dir.angle() + PI/2

func _on_moving_start(_meta):
	move_timer = 0

func _on_shooting_start(_meta):
	var player = get_node('/root/World/PlayerMove')
	var direction = ( player.global_position - global_position)
	direction.y = 0
	direction = direction.normalized()
	var projectile = projectileBase.instance()
	projectile.speed = projectile_speed
	projectile.damage = projectile_damage
	projectile.direction = direction
	get_node('/root/World').add_child(projectile)
	projectile.global_position = global_position
	shoot_timer = 0

func _process_enter_stage(delta, _meta):
	state_machine.set_state(BikerStates.MOVING)

func _process_shooting(delta, _meta):
	$Sprite.set_frame(1)
	shoot_timer += delta
	if(shoot_timer >= shoot_time):
		state_machine.set_state(BikerStates.MOVING)

func _on_dead_start(_meta):
	collision_layer = 0
	for child in get_children():
		if child is CPUParticles2D:
			child.emitting = false
		elif child is Area2D:
			child.queue_free()
		else:
			child.visible = false
	var explosion_instance = explosion.instance()
	add_child(explosion_instance)
	explosion_instance.play('explosion')
	yield(get_tree().create_timer(4), "timeout")
	queue_free()
		
func _physics_process(delta):
	state_machine.process_step(delta)
	process_show_damage(delta)

func _on_hit(_damageTaken, _attacker):
	if not (state_machine.get_state() == BikerStates.DEAD):
		self.health -= _damageTaken
		self.show_damage = true
		if self.health <= 0:
			if _attacker.has_method('charge_points'):
				_attacker.charge_points(self.reward_points)
			state_machine.set_state(BikerStates.DEAD)

func process_show_damage(delta):
	var possible_sprites = self.get_children()
	possible_sprites.append(self)
	for child in self.get_children():
		var mat = child.get_material()
		if mat and mat.get_shader_param("time_scale") != null:
			if self.show_damage:
				mat.set_shader_param("active", true)
				self.damage_show_timer += delta
				if self.damage_show_time < self.damage_show_timer:
					self.show_damage = false
			else:
				mat.set_shader_param("active", false)
				self.damage_show_timer = 0
			

func _on_HitboxOut_body_entered(body):
	if not state_machine.get_state() == BikerStates.DEAD and body.has_method('_on_hit'):
		body._on_hit(damage, self) 
