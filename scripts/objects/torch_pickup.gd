extends Area2D
class_name TorchPickup

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		print("TorchPickup: player entered")
		if body.has_torch:
			GameManager.show_hint.emit("У тебя уже есть факел! Сначала используй его.", 2.0)
			return
		body.pickup_torch()
		GameManager.show_hint.emit("Факел подобран. Подойди к костру, чтобы зажечь.", 3.0)
		queue_free()
