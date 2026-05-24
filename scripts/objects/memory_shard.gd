extends Area2D
class_name MemoryShard

@export var memory_text: String = ""
@export var memory_image: Texture = null
@export var dialogue_key: String = ""

var _used: bool = false

func _ready():
	add_to_group("interactable")
	print("MemoryShard _ready called, added to group interactable")

func interact():
	print("MemoryShard interact called!")
	if _used: return
	_used = true
	
	if memory_text != "" or memory_image != null:
		GameManager.display_memory(memory_text, memory_image)
	
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_node("HealthComponent"):
		player.health_component.heal(20)
	
	if dialogue_key != "":
		await get_tree().create_timer(0.5).timeout
		DialogueManager.start_dialogue(dialogue_key)
	
	queue_free()
