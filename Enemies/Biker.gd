extends KinematicBody2D

enum EnterOptions { TOP, BOTTOM }

export (int) var speed = 20
export (int) var shoot_time = 1
export (int) var move_time = 2
export (EnterOptions) var enter_direction = EnterOptions.TOP

var projectileBase = preload("res://Common/EnemyProjectile.tscn")
export (int) var projectile_speed = 400
export (int) var projectile_damage = 10

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
	shoot_timer += delta
	if(shoot_timer >= shoot_time):
		state_machine.set_state(BikerStates.MOVING)

func _on_dead_start(_meta):
	queue_free()
		
func _physics_process(delta):
	state_machine.process_step(delta)

func _on_hit(_damageTaken, _attacker):
	if not (state_machine.get_state() == BikerStates.DEAD):
		state_machine.set_state(BikerStates.DEAD)
	
