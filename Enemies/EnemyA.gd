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
export (bool) var shoot_and_move = false
export (Array, int) var shoot_points = []
export (float) var shoot_interval_time = 1.0
export (int) var number_of_bullets = 1
export (float) var time_for_spread = 0.3
export (float) var spread_angle = 0

export (TargetOptions) var target = TargetOptions.MoveCart
export (int) var reward_points = 5
export (int) var health = 1
export (float) var damage_show_time = 5
var damage_show_timer = 0
var show_damage = false
var spread_timer = 0
var spread_shot = 0

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

func move(delta):
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


func _process_moving(delta, _meta):
	move(delta)
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
func shoot():
	var direction = get_target_shoot_direction_from(global_position)
	var projectile = projectileBase.instance()
	projectile.speed = projectile_speed
	projectile.damage = projectile_damage
	projectile.direction = direction.rotated(rand_range(-spread_angle,spread_angle))
	get_node('/root/World').add_child(projectile)
	projectile.global_position = global_position

func _on_shooting_start(_meta):
	shoot()
	shoot_timer = 0
	spread_shot = 1
	spread_timer = 0

func _process_shooting(delta, _meta):
	if self.shoot_and_move:
		move(delta)
	shoot_timer += delta
	if number_of_bullets > 1:
		spread_timer += delta
		if spread_timer > time_for_spread and spread_shot < number_of_bullets:
			shoot()
			spread_shot += 1
			spread_timer = 0

	if(shoot_timer >= shoot_time):
		state_machine.set_state(EnemyAStates.MOVING)
	
func _physics_process(delta):
	vertical_translation_offset = vertical_speed * delta
	path.global_translate(Vector2(0,vertical_translation_offset))
	# If we reach the end of the screen, start going back
	if (path.global_position.y > vertical_offset_limit and vertical_speed > 0) or (path.global_position.y < 0 and vertical_speed < 0):
		vertical_speed = -vertical_speed
	process_show_damage(delta)

	state_machine.process_step(delta)

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
			
func _on_hit(_damageTaken, _attacker):
	if not (state_machine.get_state() == EnemyAStates.DEAD):
		self.health -= _damageTaken
		self.show_damage = true
		if self.health <= 0:
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

