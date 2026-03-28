extends StaticBody2D
class_name Lever

@export var target_node_path: NodePath
@export var active: bool = false

func interact():
	active = !active
	$Sprite2D.frame = 1 if active else 0
	var target = get_node(target_node_path)
	if target and target.has_method("activate"):
		target.activate(active)
