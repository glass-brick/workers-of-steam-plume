extends KinematicBody2D


export (int) var speed = 400
export (int) var health = 100
export (int) var iframes_time = 2
export (float) var blinking_speed = 0.05
export (int) var dig_length = 100

var velocity = Vector2(0,0)
var iframes_active = false
var iframes_counter = 0

var projectile_speed = 400
var projectile_damage = 10

var projectileBase = preload("res://Common/Projectile.tscn")

export (float) var shoot_cooldown = 0.2
var shoot_counter = 0

enum PlayerStates { MOVE, DEAD, SHOOT, TRANSFORMED }

export (PlayerStates) var initial_state 

const StateMachine = preload('res://Common/StateMachine.gd')
onready var state_machine = StateMachine.new(PlayerStates, self)

onready var sprite = $Sprite
onready var player_shoot = get_node("/root/World/PlayerShoot")
onready var initial_postition = self.position

func _ready():
	state_machine.set_state(initial_state)

func get_move_input():
	var right = Input.is_action_pressed('ui_right')
	var left = Input.is_action_pressed('ui_left')
	var up = Input.is_action_pressed('ui_up')
	var down = Input.is_action_pressed('ui_down')

	velocity = Vector2(
		0 if not (left or right) else 1 if right else -1,
		0 if not (up or down) else 1 if down else -1
	).normalized() * speed

func get_shoot_input(delta):
	var shoot = Input.is_action_pressed("shoot")

	if shoot_counter >= shoot_cooldown:
		shoot_counter = 0
	elif shoot_counter != 0:
		shoot_counter += delta

	if shoot and shoot_counter == 0:
		var direction = ( get_global_mouse_position() - global_position).normalized()
		
		if state_machine.get_state() == PlayerStates.TRANSFORMED:
			shoot_transformed_to(direction)
		else:
			shoot_to(direction)
		shoot_counter += delta

func shoot_to(direction):
	var projectile = make_projectile_in_direction(direction)
	get_node('/root/World').add_child(projectile)
	projectile.global_position = global_position

func make_projectile_in_direction(direction):
	var projectile = projectileBase.instance()
	projectile.speed = projectile_speed
	projectile.damage = projectile_damage
	projectile.direction = direction
	return projectile


func shoot_transformed_to(direction):
	var projectile = make_projectile_in_direction(direction)
	projectile.collision_mask = 6
	projectile.collision_layer = 0
	get_node('/root/World').add_child(projectile)
	projectile.global_position = global_position

	var projectile2 = make_projectile_in_direction(direction.rotated(PI/6))
	projectile2.collision_mask = 6
	projectile2.collision_layer = 0
	get_node('/root/World').add_child(projectile2)
	projectile2.global_position = global_position

	var projectile3 = make_projectile_in_direction(direction.rotated(-PI/6))
	projectile3.collision_mask = 6
	projectile3.collision_layer = 0
	get_node('/root/World').add_child(projectile3)
	projectile3.global_position = global_position


func get_transform_input():
	if Input.is_action_pressed("transform"):
		if self.state_machine.get_state() == PlayerStates.TRANSFORMED:
			detransform()
		else:
			state_machine.set_state(PlayerStates.TRANSFORMED)

func detransform():
	state_machine.set_state(initial_state)
	self.position = self.initial_postition

func _process_transformed(delta, _meta):
	get_move_input()
	process_iframes(delta)
	velocity = move_and_slide(velocity)
	get_shoot_input(delta)
	get_transform_input()

func process_iframes(delta):
	if iframes_active:
		iframes_counter += delta
		var mat = sprite.get_material()
		mat.set_shader_param("active", true)
		if iframes_counter > self.iframes_time:
			iframes_active = false
	else:
		iframes_counter = 0
		var mat = sprite.get_material()
		mat.set_shader_param("active", false)
	
func _process_move(delta, _meta):
	get_move_input()
	process_iframes(delta)
	velocity = move_and_slide(velocity)
	get_transform_input()

func _process_shoot(delta, _meta):
	get_shoot_input(delta)
	get_transform_input()

func _on_transformed_start(_meta):
	self.position = player_shoot.position
	
func _physics_process(delta):
	state_machine.process_step(delta)

func _on_dead_start(_meta):
	yield(get_tree().create_timer(0.5), "timeout")
	get_node('/root/SceneManager').goto_scene('res://StaticScreens/LoseScreen.tscn')

func _on_hit(damageTaken, _attacker):
	if not state_machine.get_state() == PlayerStates.DEAD and not iframes_active:
		self.health = max(self.health - damageTaken, 0)
		if health <= 0:
			state_machine.set_state(PlayerStates.DEAD)
		else:
			self.iframes_active = true
