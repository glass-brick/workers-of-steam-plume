extends Area2D

export (int) var damage = 10
export (int) var speed = 40
export (int) var projectile_range = 1500

var creator = self
var direction
var distance_made = 0

func _physics_process(delta):
	position += direction * speed * delta
	distance_made += (direction * speed * delta).length()
	self.rotation = direction.angle()  + PI/2
	if distance_made > projectile_range:
		explode()


func explode():
	queue_free()

func _on_Projectile_body_entered(body):
	if body.has_method('_on_hit'):
		body._on_hit(damage, creator)
		explode()
	if body.name == 'TileMap':
		explode()
