extends CanvasLayer

# Ссылки на элементы интерфейса (пути должны соответствовать вашей сцене)
@onready var health_bar = $HealthBar
@onready var ability_cooldown = $AbilityCooldown
@onready var dialogue_box = $DialogueBox
@onready var memory_label = $MemoryLabel

func _ready():
	# Подключаемся к сигналам GameManager
	GameManager.health_changed.connect(_update_health)
	GameManager.ability_cooldown_started.connect(_start_ability_cooldown)
	GameManager.show_dialogue.connect(_show_dialogue)
	GameManager.hide_dialogue.connect(_hide_dialogue)
	GameManager.show_memory.connect(_show_memory)
	
	# Скрываем элементы, которые не должны отображаться при старте
	ability_cooldown.hide()
	dialogue_box.hide()
	memory_label.hide()
	
	# Если игрок уже существует, устанавливаем начальное значение здоровья
	if GameManager.player and GameManager.player.has_node("HealthComponent"):
		var health = GameManager.player.health_component.current_health
		var max_health = GameManager.player.health_component.max_health
		_update_health(health, max_health)
	else:
		# Если игрок ещё не загружен, пробуем ещё раз через короткое время
		await get_tree().create_timer(0.1).timeout
		if GameManager.player and GameManager.player.has_node("HealthComponent"):
			var health = GameManager.player.health_component.current_health
			var max_health = GameManager.player.health_component.max_health
			_update_health(health, max_health)

# Обновление полоски здоровья
func _update_health(health: float, max_health: float):
	if health_bar:
		health_bar.value = health
		health_bar.max_value = max_health
	else:
		print("HealthBar not found in UI scene!")

# Запуск анимации перезарядки способности
func _start_ability_cooldown(ability_id: String, remaining: float):
	if ability_cooldown:
		ability_cooldown.show()
		var tween = create_tween()
		tween.tween_property(ability_cooldown, "value", 0, remaining)
		# После окончания анимации скрываем индикатор (опционально)
		tween.finished.connect(func(): ability_cooldown.hide())

# Отображение диалога
func _show_dialogue(speaker: String, text: String):
	# Обновляем текст в диалоговом окне
	$DialogueBox/SpeakerLabel.text = speaker
	$DialogueBox/TextLabel.text = text
	dialogue_box.show()
	get_tree().paused = true   # Ставим игру на паузу во время диалога

# Скрытие диалога
func _hide_dialogue():
	dialogue_box.hide()
	get_tree().paused = false  # Снимаем паузу

# Отображение временного сообщения (осколок памяти)
func _show_memory(text: String, image: Texture = null):
	memory_label.text = text
	memory_label.show()
	await get_tree().create_timer(3.0).timeout
	memory_label.hide()
