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

		var projectile = projectileBase.instance()
		projectile.speed = projectile_speed
		projectile.damage = projectile_damage
		projectile.direction = direction
		get_node('/root/World').add_child(projectile)
		projectile.global_position = global_position
		shoot_counter += delta


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

func _process_shoot(delta, _meta):
	get_shoot_input(delta)
	
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
