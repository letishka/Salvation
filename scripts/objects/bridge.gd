extends StaticBody2D
class_name Bridge

@export var up_collision_disabled: bool = true

func activate(state: bool):
	$CollisionShape2D.disabled = state if up_collision_disabled else not state
