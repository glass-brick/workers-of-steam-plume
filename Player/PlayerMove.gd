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
var current_state = PlayerStates.UNLOCKED

onready var sprite = $Sprite

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
	
func _physics_process(delta):
	if current_state == PlayerStates.UNLOCKED:
		get_input()
		process_iframes(delta)
		velocity = move_and_slide(velocity)

func _on_hit(damageTaken, _attacker):
	if not current_state == PlayerStates.DEAD and not iframes_active:
		self.health = max(self.health - damageTaken, 0)
		if health <= 0:
			current_state = PlayerStates.DEAD
		else:
			self.iframes_active = true
