extends RigidBody2D
class_name MovableBox

@export var push_force: float = 500.0

func _ready():
	add_to_group("movable")
	gravity_scale = 0.0

func push(direction: Vector2):
	apply_central_impulse(direction * push_force)
