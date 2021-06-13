extends Node2D

var following_scene = null
var current_scene = null
var audio_player = null
var current_scene_default_stream = null

onready var animation_player = $AnimationPlayer

func _ready():
	var root = get_tree().get_root()
	current_scene = root.get_child(root.get_child_count() - 1)
	get_music_player()
	animation_player.play("Fade")

func goto_scene(path):
	following_scene = path
	animation_player.playback_speed = 2
	animation_player.play_backwards()

func get_music_player():
	for node in current_scene.get_children():
		if node is AudioStreamPlayer:
			audio_player = node
			current_scene_default_stream = audio_player.stream
			return

func play_theme(stream):
	if not audio_player: 
		return
	audio_player.stream = stream
	audio_player.play()

func resume_default_theme():
	play_theme(current_scene_default_stream)

func _deferred_goto_scene(path):
	# It is now safe to remove the current scene
	current_scene.free()

	# Load the new scene.
	var s = ResourceLoader.load(path)

	# Instance the new scene.
	current_scene = s.instance()
	get_music_player()

	# Add it to the active scene, as child of root.
	get_tree().get_root().add_child(current_scene)

	# Optionally, to make it compatible with the SceneTree.change_scene() API.
	get_tree().set_current_scene(current_scene)
	
	animation_player.play()


func _on_AnimationPlayer_animation_finished(_anim_name):
	if following_scene != "":
		call_deferred("_deferred_goto_scene", following_scene)
	following_scene = ""