extends Node2D

var followingScene = ""
var currentScene = ""

onready var animation_player = $AnimationPlayer

func _ready():
	var root = get_tree().get_root()
	currentScene = root.get_child(root.get_child_count() - 1)
	animation_player.play("Fade")

func goto_scene(path):
	followingScene = path
	animation_player.playback_speed = 2
	animation_player.play_backwards()

func _deferred_goto_scene(path):
	# It is now safe to remove the current scene
	currentScene.free()

	# Load the new scene.
	var s = ResourceLoader.load(path)

	# Instance the new scene.
	currentScene = s.instance()

	# Add it to the active scene, as child of root.
	get_tree().get_root().add_child(currentScene)

	# Optionally, to make it compatible with the SceneTree.change_scene() API.
	get_tree().set_current_scene(currentScene)
	
	animation_player.play()


func _on_AnimationPlayer_animation_finished(_anim_name):
	if followingScene != "":
		call_deferred("_deferred_goto_scene", followingScene)
	followingScene = ""