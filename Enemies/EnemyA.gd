extends PathFollow2D

enum EnterOptions { TOP, BOTTOM }

export (EnterOptions) var enter_direction = EnterOptions.TOP
export (int) var enter_speed = 40
export (int) var speed = 40
export (int) var damage = 40
export (int) var vertical_speed = 15
export (bool) var bounce_at_path_end = true
var accumulated_offset = 0

enum EnemyAStates { ENTER_STAGE, MOVING, DEAD }
const StateMachine = preload('res://Common/StateMachine.gd')

onready var state_machine = StateMachine.new(EnemyAStates, self)
var target_position
enum Sides { FORWARDS, BACKWARDS }
export (Sides) var initial_direction = Sides.FORWARDS

func _ready():
	state_machine.set_state(EnemyAStates.ENTER_STAGE)
	state_machine.set_side(initial_direction)
	position = get_enter_position()
	$Hitbox.connect('hit', self, '_on_hit')

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


func _process_moving(delta, _meta):
	var side_multiplier = 1 if state_machine.current_side == StateMachine.Sides.FORWARDS else -1
	var new_offset = get_offset() + speed * delta * side_multiplier
	var total_offset = get_parent().curve.get_baked_length()
	if bounce_at_path_end and (total_offset <= new_offset and side_multiplier == 1) or (new_offset <= 0 and side_multiplier == -1):
		state_machine.flip_side()
		return
	
	set_offset(new_offset)
	accumulated_offset += vertical_speed * delta
	global_translate(Vector2(0,accumulated_offset))
	# If we reach the end of the screen, start going back
	if (global_position.y > 600 and vertical_speed > 0) or (global_position.y < 0 and vertical_speed < 0):
		vertical_speed = -vertical_speed
	
func _physics_process(delta):
	state_machine.process_step(delta)
	
func _on_hit(_damageTaken, _attacker):
	if not (state_machine.get_state() == EnemyAStates.DEAD):
		state_machine.set_state(EnemyAStates.DEAD)
		
func _on_dead_start(_meta):
	queue_free()

# This hits the body that entered this enemy's body
func _on_Hitbox_body_entered(body):
	if not state_machine.get_state() == EnemyAStates.DEAD and body.has_method('_on_hit'):
		body._on_hit(damage, self) 

