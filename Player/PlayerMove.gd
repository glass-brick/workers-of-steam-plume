extends KinematicBody2D


export (int) var speed = 400
export (int) var health = 100
export (int) var iframe_time = 2
export (float) var blinking_speed = 0.05
export (int) var dig_length = 100

var velocity = Vector2(0,0)
var iframe_active = false
var iframe_counter = 0

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
	if iframe_active:
		iframe_counter += delta
		var mat = sprite.get_material()
		mat.set_shader_param("active", true)
		if iframe_counter > self.iframe_time:
			iframe_active = false
	else:
		iframe_counter = 0
		var mat = sprite.get_material()
		mat.set_shader_param("active", false)
	
func _physics_process(delta):
	if current_state == PlayerStates.UNLOCKED:
		get_input()
		process_iframes(delta)
		velocity = move_and_slide(velocity)

func _on_hit(damageTaken, _attacker):
	if not current_state == PlayerStates.DEAD:
		self.health = max(self.health - damageTaken, 0)
		if health <= 0:
			current_state = PlayerStates.DEAD
		else:
			self.iframe_active = true
