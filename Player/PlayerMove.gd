extends KinematicBody2D


export (int) var speed = 400
export (int) var health = 100
export (int) var iframes_time = 2
export (float) var blinking_speed = 0.05
export (int) var dig_length = 100
export (float) var transform_burnout = 15
export (float) var transformed_points_modifier = 0.2

var velocity = Vector2(0,0)
var iframes_active = false
var iframes_counter = 0

export (int) var projectile_speed = 400
export (int) var projectile_damage = 10

var projectileBase = preload("res://Common/Projectile.tscn")
var transformedSong = preload("res://Music/transformed.wav")

export (float) var shoot_cooldown = 0.3
var shoot_counter = 0
var transform_charge = 0

var transform_click_timer = 0
var transform_click_time = 0.5

enum PlayerStates { MOVE, DEAD, SHOOT, TRANSFORMING, TRANSFORMED, DETRANSFORMING }

export (PlayerStates) var initial_state 

const StateMachine = preload('res://Common/StateMachine.gd')
onready var state_machine = StateMachine.new(PlayerStates, self)

onready var sprite = $Sprite
onready var player_shoot = get_node("/root/World/PlayerShoot")
onready var player_move = get_node("/root/World/PlayerMove")
onready var initial_position = self.position

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
	var mouse_position = get_global_mouse_position()
	$Cannon.look_at(mouse_position)
	$Cannon.rotation += PI/2

	if shoot_counter >= shoot_cooldown:
		shoot_counter = 0
		$Cannon.play("default")
	elif shoot_counter != 0:
		shoot_counter += delta

	if shoot and shoot_counter == 0:
		if $disparo:
			$disparo.play()
		$Cannon.play("shoot")
		var direction = ( mouse_position - global_position).normalized()
		
		if state_machine.get_state() == PlayerStates.TRANSFORMED:
			shoot_transformed_to(direction)
		else:
			shoot_to(direction)
		shoot_counter += delta

func shoot_to(direction):
	var projectile = make_projectile_in_direction(direction)
	get_node('/root/World').add_child(projectile)
	projectile.global_position = global_position + projectile.direction * 20
	projectile.rotation = direction.angle() + PI/2

func make_projectile_in_direction(direction):
	var projectile = projectileBase.instance()
	projectile.speed = projectile_speed
	projectile.damage = projectile_damage
	projectile.direction = direction
	projectile.creator = self
	return projectile


func shoot_transformed_to(direction):
	for dir in [direction, direction.rotated(PI/6), direction.rotated(-PI/6)]:
		var projectile = make_projectile_in_direction(dir)
		projectile.collision_mask = 6
		projectile.collision_layer = 0
		get_node('/root/World').add_child(projectile)
		projectile.global_position = global_position



func get_transform_input(delta):
	transform_click_timer += delta
	if Input.is_action_pressed("transform") and transform_click_timer > transform_click_time :
		transform_click_timer = 0
		if self.state_machine.get_state() == PlayerStates.TRANSFORMED:
			state_machine.set_state(PlayerStates.DETRANSFORMING)
		else:
			state_machine.set_state(PlayerStates.TRANSFORMING)


func _process_transformed(delta, _meta):
	get_move_input()
	process_iframes(delta)
	velocity = move_and_slide(velocity)
	get_shoot_input(delta)
	get_transform_input(delta)
	self.player_move.transform_charge -= delta * self.player_move.transform_burnout
	if self.player_move.transform_charge <= 0:
		self.player_move.transform_charge = 0
		state_machine.set_state(PlayerStates.DETRANSFORMING)

func charge_points(points):
	if self == self.player_move:
		var charge_amount = points
		if state_machine.get_state() == PlayerStates.TRANSFORMED:
			charge_amount *= self.transformed_points_modifier
		self.transform_charge = min(self.transform_charge + charge_amount, 100)
	else:
		self.player_move.charge_points(points)

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
	get_transform_input(delta)

func _process_shoot(delta, _meta):
	get_shoot_input(delta)
	get_transform_input(delta)

func _on_transforming_start(_meta):
	if self == player_move:
		get_node('/root/SceneManager').play_theme(transformedSong)
		pause_mode = PAUSE_MODE_PROCESS

func _process_transforming(delta, _meta):
	if self == player_move:
		get_tree().paused = true
		position = position.move_toward(player_shoot.position, delta * speed)
		if position == player_shoot.position:
			pause_mode = PAUSE_MODE_STOP
			get_tree().paused = false
			state_machine.set_state(PlayerStates.TRANSFORMED)
	else:
		state_machine.set_state(PlayerStates.TRANSFORMED)

		
func _on_detransforming_start(_meta):
	pause_mode = PAUSE_MODE_PROCESS
	if self == player_move:
		$JoinedThing.visible = false
		$Cannon.visible = false
		$Collisionjoined.disabled = true
		get_node('/root/SceneManager').resume_default_theme()
	else:
		$Cannon.visible = true
	$Sprite.visible = true
	$CollisionShape2D.disabled = false
	
func _process_detransforming(delta, _meta):
	get_tree().paused = true
	position = position.move_toward(initial_position, delta * speed)
	if player_move.position == player_move.initial_position and player_shoot.position == player_shoot.initial_position:
		pause_mode = PAUSE_MODE_STOP
		get_tree().paused = false
		state_machine.set_state(initial_state)
		if self == player_move:
			iframes_active = true

func _on_transformed_start(_meta):
	self.position = player_shoot.position
	if self == player_move:
		$JoinedThing.visible = true
		$Cannon.visible = true
		$Collisionjoined.disabled = false
	else:
		$Cannon.visible = false
	$Sprite.visible = false
	$CollisionShape2D.disabled = true

	
func _physics_process(delta):
	state_machine.process_step(delta)

func _on_dead_start(_meta):
	if $muerte:
		$muerte.play()
	yield(get_tree().create_timer(0.5), "timeout")
	get_node('/root/SceneManager').goto_scene('res://StaticScreens/LoseScreen.tscn')

func _on_hit(damageTaken, _attacker):
	if not state_machine.get_state() == PlayerStates.DEAD and not iframes_active:
		self.health = max(self.health - damageTaken, 0)
		if health <= 0:
			state_machine.set_state(PlayerStates.DEAD)
		else:
			self.iframes_active = true
