extends StaticBody2D
class_name Lever

signal interacted

@export var target_node_path: NodePath
@export var active: bool = false

@onready var lever_sound = $LeverSound 

func interact():
	print("Lever interact called")
	if lever_sound:
		lever_sound.play()
	active = !active
	$AnimatedSprite2D.frame = 1 if active else 0
	var target = get_node(target_node_path)
	if target and target.has_method("activate"):
		target.activate(active)
	interacted.emit()
