extends KinematicBody2D


export (int) var speed = 400
export (int) var health = 100
export (int) var iframes_time = 2
export (float) var blinking_speed = 0.05
export (int) var dig_length = 100

var velocity = Vector2(0,0)
var iframes_active = false
var iframes_counter = 0

enum PlayerStates { UNLOCKED, DEAD }

const StateMachine = preload('res://Common/StateMachine.gd')
onready var state_machine = StateMachine.new(PlayerStates, self)

onready var sprite = $Sprite

func _ready():
	state_machine.set_state(PlayerStates.UNLOCKED)

func get_input():
	var right = Input.is_action_pressed('ui_right')
	var left = Input.is_action_pressed('ui_left')
	var up = Input.is_action_pressed('ui_up')
	var down = Input.is_action_pressed('ui_down')

	velocity = Vector2(
		0 if not (left or right) else 1 if right else -1,
		0 if not (up or down) else 1 if down else -1
	).normalized() * speed

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
	
func _process_unlocked(delta, _meta):
	get_input()
	process_iframes(delta)
	velocity = move_and_slide(velocity)

func _physics_process(delta):
	state_machine.process_step(delta)

func _on_hit(damageTaken, _attacker):
	if not state_machine.get_state() == PlayerStates.DEAD and not iframes_active:
		self.health = max(self.health - damageTaken, 0)
		if health <= 0:
			state_machine.set_state(PlayerStates.DEAD)
		else:
			self.iframes_active = true
