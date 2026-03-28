extends Node2D

func _ready():
	LevelManager.register_level(self)
	# Устанавливаем начальный чекпоинт
	LevelManager.set_checkpoint($Player.global_position)
