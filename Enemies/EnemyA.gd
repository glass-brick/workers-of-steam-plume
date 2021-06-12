extends PathFollow2D

export (int) var speed = 40
export (int) var damage = 40
export (int) var vertical_speed = 15
var accumulated_offset = 0

enum EnemyAStates { MOVING, DEAD }

var current_state
var current_side
var current_metadata
var states
var stateFunctions = {}

func setup(statesEnum):
	states = statesEnum
	for key in statesEnum.keys():
		stateFunctions[statesEnum[key]] = {
			"process": "_process_%s" % key.to_lower(),
			"start": "_on_%s_start" % key.to_lower(),
		}

func _ready():
	setup(EnemyAStates)
	set_monster_state(EnemyAStates.MOVING)
	$Hitbox.connect('hit', self, '_on_hit')

func set_monster_state(new_state):
	current_state = new_state
	current_metadata = null
	trigger_state_change()

func get_monster_state():
	return current_state


func _process_moving(_delta, _meta):
	self.set_offset(self.get_offset() + self.speed * _delta)
	self.accumulated_offset += vertical_speed*_delta
	self.global_translate(Vector2(0,self.accumulated_offset))
	# If we reach the end of the screen, start going back
	if self.global_position.y > 600 or self.global_position.y < 0:
		vertical_speed = -vertical_speed
	
func _physics_process(delta):
	var process_func = stateFunctions[current_state]["process"]
	if not process_func:
		print('UNEXPECTED STATE:', current_state)
	if has_method(process_func):
		call(process_func, delta, current_metadata)
	
func _on_hit(damageTaken, attacker):
	if not (get_monster_state() == EnemyAStates.DEAD):
		current_state = EnemyAStates.DEAD
		trigger_state_change()

func trigger_state_change():
	var change_func = stateFunctions[current_state]["start"]
	if not change_func:
		print('UNEXPECTED STATE:', current_state)
	if has_method(change_func):
		call(change_func, current_metadata)
		
func _on_dead_start(_meta):
	queue_free()
		

# This hits the body that entered this enemy's body
func _on_Hitbox_body_entered(body):
	if not get_monster_state() == EnemyAStates.DEAD and body.has_method('_on_hit'):
		body._on_hit(self.damage, self) # Replace with function body.
