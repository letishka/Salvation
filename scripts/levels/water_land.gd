extends Node2D

@export var end_screen_scene: PackedScene

func _ready():
	LevelManager.register_level(self)
	LevelManager.set_checkpoint($Player.global_position)

	if $Player.has_node("HealthComponent"):
		$Player.health_component.died.connect(_on_player_died)
	else:
		print("Ошибка: у Player нет HealthComponent")

func _on_player_died():
	var end_screen = end_screen_scene.instantiate()
	add_child(end_screen)
