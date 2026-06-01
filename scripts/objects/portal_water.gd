extends Area2D

@export var target_scene: String = "res://scenes/levels/water_level_1.tscn"
@export var portal_music: AudioStream

@onready var animated_sprite = $AnimatedSprite2D
@onready var music_player = $MusicPlayer

var music_started = false

func _ready():
	if animated_sprite:
		animated_sprite.play("default")
	body_entered.connect(_on_body_entered)
	if music_player and portal_music:
		music_player.stream = portal_music

func _on_body_entered(body):
	if body.is_in_group("player"):
		call_deferred("_change_scene")

func _change_scene():
	get_tree().change_scene_to_file(target_scene)

func start_portal_music():
	if not music_started and music_player and portal_music:
		music_started = true
		music_player.play()
		music_player.finished.connect(_on_music_finished)

func _on_music_finished():
	if music_player and music_started:
		music_player.play()
