extends Area2D
class_name TorchPickup

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.pickup_torch()
		GameManager.show_hint.emit("Факел подобран. Подойди к костру, чтобы зажечь.", 3.0)
		queue_free()
