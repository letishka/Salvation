extends Node

@export var end_screen_scene: PackedScene

@onready var player: CharacterBody2D = %Player
var pause_menu_scene = preload("res://scenes/ui/PauseMenu.tscn")

func _ready():
	GameManager.initial_player_health = player.health_component.current_health
	$BackgroundMusic.play()
	player.health_component.died.connect(on_died)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		GameManager.initial_player_health = player.health_component.current_health
		add_child(pause_menu_scene.instantiate())

func on_died():
	var end_screen_instance = end_screen_scene.instantiate() as EndScreen
	add_child(end_screen_instance)
