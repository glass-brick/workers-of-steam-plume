extends KinematicBody2D

enum EnterOptions { TOP, BOTTOM }

export (int) var speed = 20
export (int) var shoot_time = 1
export (int) var move_time = 2
export (EnterOptions) var enter_direction = EnterOptions.TOP

export (int) var damage = 30
export (int) var reward_points = 5
export (int) var health = 1
export (float) var max_rotation = 0.1

export (float) var damage_show_time = 5
var damage_show_timer = 0
var show_damage = false

var shoot_timer = 0
var move_timer = 0

onready var target = get_node('/root/World/PlayerMove')

onready var velocity_dir = Vector2(0,1).rotated(self.rotation)

enum CanoaStates { ENTER_STAGE, MOVING, DEAD }
const StateMachine = preload('res://Common/StateMachine.gd')

onready var state_machine = StateMachine.new(CanoaStates, self)
enum Sides { FORWARDS, BACKWARDS }
export (Sides) var initial_direction = Sides.FORWARDS

func _ready():
	state_machine.set_state(CanoaStates.MOVING)
	state_machine.set_side(initial_direction)

func _process_moving(delta, _meta):
	move_timer += delta
	var velocity = (target.global_position - self.global_position).normalized() * speed * delta
	self.look_at(target.global_position)
	# La idea es que gire no mucho, sino un angulo cappeado por un cierto valor
	# var real_angle = velocity.angle_to(target.global_position - self.global_position)
	# real_angle = max_rotation if real_angle > 0 else -max_rotation
	# velocity = velocity.rotated(real_angle)
	var collision = move_and_collide(velocity)
	if collision:
		velocity_dir = velocity.bounce(collision.normal).normalized()

func _on_moving_start(_meta):
	move_timer = 0

func _process_enter_stage(delta, _meta):
	state_machine.set_state(CanoaStates.MOVING)


func _on_dead_start(_meta):
	queue_free()
		
func _physics_process(delta):
	state_machine.process_step(delta)
	process_show_damage(delta)

func _on_hit(_damageTaken, _attacker):
	if not (state_machine.get_state() == CanoaStates.DEAD):
		self.health -= _damageTaken
		self.show_damage = true
		if self.health <= 0:
			if _attacker.has_method('charge_points'):
				_attacker.charge_points(self.reward_points)
			state_machine.set_state(CanoaStates.DEAD)

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
	if not state_machine.get_state() == CanoaStates.DEAD and body.has_method('_on_hit'):
		body._on_hit(damage, self) 
		self._on_hit(damage, self)
