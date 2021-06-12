extends CanvasLayer

func goto(path):
	get_node('/root/SceneManager').goto_scene(path)
