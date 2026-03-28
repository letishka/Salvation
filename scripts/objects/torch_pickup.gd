extends Area2D
class_name TorchPickup

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.pickup_torch()
		queue_free()
