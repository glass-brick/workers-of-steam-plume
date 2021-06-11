extends Area2D

export (int) var damage = 10
export (int) var speed = 40
export (int) var projectile_range = 1500

var direction
var distance_made = 0

func _physics_process(delta):
	position += direction * speed * delta
	distance_made += (direction * speed * delta).length()
	if distance_made > projectile_range:
		explode()


func explode():
	queue_free()

func _on_Area2D_body_entered(body):
	if body.has_method('_on_hit'):
		body._on_hit(damage, self)
		explode()
	if body.name == 'TileMap':
		explode()