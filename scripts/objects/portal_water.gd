extends Area2D

@export var target_scene: String = "res://scenes/levels/water_level_1.tscn"
@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	animated_sprite.play("default")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	print("!!!!")
	if body.is_in_group("player"):
		get_tree().change_scene_to_file(target_scene)
