extends Area2D
class_name Bonfire

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		var player = body
		if player.has_torch and not player.torch_lit:
			player.light_torch()
			GameManager.show_hint.emit("Факел зажжён! Неси к пустой подставке.", 2.0)
