extends StaticBody2D
class_name Bridge

@export var up_position: Vector2
@export var down_position: Vector2
@export var up_collision_disabled: bool = true

func activate(state: bool):
	print("Bridge activate: ", state)
	position = up_position if state else down_position
	$CollisionShape2D.disabled = state if up_collision_disabled else !state
