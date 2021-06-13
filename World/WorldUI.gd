extends CanvasLayer

var player

func _process(_delta):
	player = get_parent().get_node('PlayerMove')
	if player:
		$HealthBar.value = player.health
		$PowerBar.value = player.transform_charge

