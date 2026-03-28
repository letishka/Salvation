extends Control

@onready var health_bar = $HealthBar
@onready var ability_cooldown = $AbilityCooldown
@onready var dialogue_box = $DialogueBox
@onready var memory_label = $MemoryLabel

func _ready():
	GameManager.health_changed.connect(_update_health)
	GameManager.ability_cooldown_started.connect(_start_ability_cooldown)
	GameManager.show_dialogue.connect(_show_dialogue)
	GameManager.hide_dialogue.connect(_hide_dialogue)
	GameManager.show_memory.connect(_show_memory)
	ability_cooldown.hide()
	dialogue_box.hide()
	memory_label.hide()

func _update_health(health, max_health):
	health_bar.value = health
	health_bar.max_value = max_health

func _start_ability_cooldown(ability_id, remaining):
	ability_cooldown.show()
	# Здесь можно анимировать уменьшение
	# Используйте Tween для плавности
	var tween = create_tween()
	tween.tween_property(ability_cooldown, "value", 0, remaining)

func _show_dialogue(speaker, text):
	$DialogueBox/SpeakerLabel.text = speaker
	$DialogueBox/TextLabel.text = text
	dialogue_box.show()
	get_tree().paused = true

func _hide_dialogue():
	dialogue_box.hide()
	get_tree().paused = false

func _show_memory(text, image):
	memory_label.text = text
	memory_label.show()
	await get_tree().create_timer(3.0).timeout
	memory_label.hide()
