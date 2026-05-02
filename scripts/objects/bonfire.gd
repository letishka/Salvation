extends StaticBody2D
class_name Bonfire

func interact():
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("light_torch"):
		if player.has_torch and not player.torch_lit:
			player.light_torch()
