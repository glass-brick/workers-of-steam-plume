extends "res://Enemies/EnemyA.gd"

func all_state_process(_delta, _meta):
	var player = get_node('/root/World/PlayerMove')
	$Sprite.look_at(player.global_position)
	$Sprite.rotation -= PI/2

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
