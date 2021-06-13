extends PathFollow2D

enum EnterOptions { TOP, BOTTOM }
enum TargetOptions {MoveCart, ShootCart}

export (EnterOptions) var enter_direction = EnterOptions.TOP
export (int) var enter_speed = 40
export (int) var speed = 40
export (int) var damage = 40
export (int) var vertical_speed = 15
export (int) var vertical_offset_limit = 100
export (bool) var bounce_at_path_end = true
export (bool) var shoot_at_time = true
export (Array, int) var shoot_points = []
export (float) var shoot_interval_time = 1.0
export (TargetOptions) var target = TargetOptions.MoveCart
export (int) var reward_points = 5

var projectileBase = preload("res://Common/EnemyProjectile.tscn")
var vertical_translation_offset = 0
export (int) var projectile_speed = 400
export (int) var projectile_damage = 10

enum EnemyAStates { ENTER_STAGE, MOVING, SHOOTING, DEAD }
const StateMachine = preload('res://Common/StateMachine.gd')

onready var state_machine = StateMachine.new(EnemyAStates, self)
onready var path = get_parent()
var target_position
enum Sides { FORWARDS, BACKWARDS }
export (Sides) var initial_direction = Sides.FORWARDS

func _ready():
	state_machine.set_state(EnemyAStates.ENTER_STAGE)
	state_machine.set_side(initial_direction)
	position = get_enter_position()

func get_enter_position():
	if enter_direction == EnterOptions.TOP:
		return Vector2(target_position.x, 0)
	if enter_direction == EnterOptions.BOTTOM:
		return Vector2(target_position.x, 600)

func _on_enter_stage_start(_meta):
	target_position = position
	position = get_enter_position()

func _process_enter_stage(delta, _meta):
	position = position.move_toward(target_position, delta * enter_speed * target_position.y * 0.1)
	if(position == target_position):
		state_machine.set_state(EnemyAStates.MOVING)

var move_timer = 0

func _on_side_change(new_side):
	scale.x = -1 if new_side == Sides.BACKWARDS else 1

func _process_moving(delta, _meta):
	var side_multiplier = 1 if state_machine.current_side == StateMachine.Sides.FORWARDS else -1
	var old_offset = get_offset()
	var new_offset = old_offset + speed * delta * side_multiplier
	var total_offset = path.curve.get_baked_length()
	if bounce_at_path_end and (total_offset <= new_offset and side_multiplier == 1) or (new_offset <= 0 and side_multiplier == -1):
		state_machine.flip_side()
		if (shoot_points.has(0) and new_offset <= 0) or (shoot_points.has(path.curve.get_point_count() - 1)and new_offset >= total_offset):
			state_machine.set_state(EnemyAStates.SHOOTING)
		return
	
	set_offset(new_offset)
	
	if shoot_at_time:
		move_timer += delta
		if shoot_interval_time < move_timer:
			state_machine.set_state(EnemyAStates.SHOOTING)
			move_timer = 0
		else:
			for id in shoot_points:
				var shoot_point = path.curve.get_point_position(id)
				if (shoot_point - position).length() < delta * speed / 2:
					state_machine.set_state(EnemyAStates.SHOOTING)

var shoot_timer = 0
var shoot_time = 0.5
func _on_shooting_start(_meta):
	var direction = get_target_shoot_direction_from(global_position)
	var projectile = projectileBase.instance()
	projectile.speed = projectile_speed
	projectile.damage = projectile_damage
	projectile.direction = direction
	get_node('/root/World').add_child(projectile)
	projectile.global_position = global_position
	shoot_timer = 0

func _process_shooting(delta, _meta):
	shoot_timer += delta
	if(shoot_timer >= shoot_time):
		state_machine.set_state(EnemyAStates.MOVING)
	
func _physics_process(delta):
	vertical_translation_offset = vertical_speed * delta
	path.global_translate(Vector2(0,vertical_translation_offset))
	# If we reach the end of the screen, start going back
	if (path.global_position.y > vertical_offset_limit and vertical_speed > 0) or (path.global_position.y < 0 and vertical_speed < 0):
		vertical_speed = -vertical_speed

	state_machine.process_step(delta)
	
func _on_hit(_damageTaken, _attacker):
	if not (state_machine.get_state() == EnemyAStates.DEAD):
		if _attacker.has_method('charge_points'):
			_attacker.charge_points(self.reward_points)
		state_machine.set_state(EnemyAStates.DEAD)
		
func _on_dead_start(_meta):
	if path.get_child_count() == 1:
		path.queue_free()
	else:
		queue_free()

func get_target_shoot_direction_from(initial_pos):
	match target:
		TargetOptions.MoveCart:
			var player = get_node('/root/World/PlayerMove')
			return (player.global_position - initial_pos).normalized()
		TargetOptions.ShootCart:
			var player = get_node('/root/World/PlayerShoot')
			return (player.global_position - initial_pos).normalized()
# This hits the body that entered this enemy's body
func _on_Hitbox_body_entered(body):
	if not state_machine.get_state() == EnemyAStates.DEAD and body.has_method('_on_hit'):
		body._on_hit(damage, self) 

