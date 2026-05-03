extends MemoryShard
@export var dialogue_key: String = ""

func _on_body_entered(body):
	if body.is_in_group("player") and not _used:
		_used = true
		GameManager.display_memory(memory_text, memory_image)
		body.health_component.heal(20)
		if dialogue_key != "":
			await get_tree().create_timer(0.5).timeout
			DialogueManager.start_dialogue(dialogue_key)
		queue_free()
