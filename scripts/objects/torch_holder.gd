extends StaticBody2D
class_name TorchHolder

signal torch_placed

@export var target_node_path: NodePath
var is_lit: bool = false

@onready var holder_empty = $Sprite2D  # пустая подставка
@onready var holder_lit = $HolderLit  # зажжённая подставка
@onready var holder_light = $PointLight2D

func interact():
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("place_torch"):
		if player.torch_lit and not is_lit:
			if player.place_torch():
				is_lit = true
				holder_empty.visible = false
				holder_lit.visible = true
				holder_light.enabled = true
				torch_placed.emit()
				
				var target = get_node(target_node_path)
				if target and target.has_method("register_lit_torch"):
					target.register_lit_torch()
				elif target and target.has_method("activate"):
					target.activate(true)
