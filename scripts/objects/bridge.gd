extends StaticBody2D
class_name Bridge

@export var up_position: Vector2
@export var down_position: Vector2

func activate(state: bool):
	position = down_position if state else up_position
	$CollisionShape2D.disabled = not state
