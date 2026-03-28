extends Area2D
class_name MemoryShard

@export var memory_text: String = ""
@export var memory_image: Texture = null

var _used: bool = false

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player") and not _used:
		_used = true
		GameManager.display_memory(memory_text, memory_image)
		body.health_component.heal(20)
		queue_free()
