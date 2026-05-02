extends StaticBody2D
class_name TorchHolder

@export var target_node_path: NodePath
var is_lit: bool = false

func interact():
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("place_torch"):
		if player.torch_lit and not is_lit:
			player.place_torch()
			is_lit = true
			$Sprite2D.frame = 1
			var target = get_node(target_node_path)
			if target and target.has_method("activate"):
				target.activate(true)
