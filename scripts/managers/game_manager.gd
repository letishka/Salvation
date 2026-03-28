extends Node

signal health_changed(health: int, max_health: int)
signal ability_cooldown_started(ability_id: String, remaining: float)
signal show_dialogue(speaker: String, text: String)
signal hide_dialogue
signal show_memory(text: String, image: Texture)

var player: Node = null

func _ready():
	player = get_tree().get_first_node_in_group("player")
	process_mode = PROCESS_MODE_ALWAYS

func update_health(health: int, max_health: int):
	health_changed.emit(health, max_health)

func start_ability_cooldown(ability_id: String, remaining: float):
	ability_cooldown_started.emit(ability_id, remaining)

func display_dialogue(speaker: String, text: String):
	show_dialogue.emit(speaker, text)

func close_dialogue():
	hide_dialogue.emit()

func display_memory(text: String, image: Texture = null):
	show_memory.emit(text, image)
