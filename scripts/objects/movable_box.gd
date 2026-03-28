extends RigidBody2D
class_name MovableBox

@export var push_force: float = 500.0

func _ready():
	add_to_group("movable")
	# Отключаем гравитацию, если нужно, чтобы ящик не падал
	gravity_scale = 0.0

# Вызывается при столкновении с игроком (можно через Area2D)
func push(direction: Vector2):
	apply_central_impulse(direction * push_force)
