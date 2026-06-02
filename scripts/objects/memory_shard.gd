extends Area2D
class_name MemoryShard

@export var memory_text: String = ""
@export var memory_image: Texture = null
@export var dialogue_key: String = ""

@onready var pickup_sound = $PickupSound

var _used: bool = false

func _ready():
	add_to_group("interactable")
	print("MemoryShard _ready called, added to group interactable")

func interact():
	if pickup_sound:
		pickup_sound.play()
	print("MemoryShard interact called!")
	if _used: return
	_used = true
	
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_node("HealthComponent"):
		player.health_component.heal(20)
		print("Player healed +20 HP")
	
	var memory_ui = preload("res://scenes/ui/MemoryUI.tscn").instantiate()
	get_tree().current_scene.add_child(memory_ui)

	memory_ui.show_memory(memory_text, memory_image, _on_memory_closed)

func _on_memory_closed():
	print("Memory closed, starting dialogue: ", dialogue_key)
	if dialogue_key != "":
		DialogueManager.start_dialogue(dialogue_key)
	
	queue_free()
