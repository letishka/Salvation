extends Node2D

@onready var player = $Player
@onready var lever = $Lever
@onready var bridge = $Bridge
@onready var enemy = $ShadowSoldier
@onready var memory = $MemoryShard
@onready var start_zone = $StartZone
@onready var exit_zone = $ExitZone
@onready var segment_title = $SegmentTitle
@onready var hint_system = $HintSystem

var lever_used = false
var dialog_started = false
var end_screen_scene = preload("res://scenes/ui/end_screen.tscn")

func _ready():
	# Настройка моста
	if bridge.has_method("activate"):
		bridge.activate(false)
	else:
		print("Bridge error")
	
	# Настройка врага
	if enemy:
		enemy.visible = false
		enemy.set_physics_process(false)
	
	# Настройка осколка памяти
	if memory:
		memory.visible = false
		# Убеждаемся, что коллизия включена
		if memory.has_node("CollisionShape2D"):
			memory.get_node("CollisionShape2D").disabled = false
		memory.monitoring = true
		memory.monitorable = true
	
	# Зона выхода
	if exit_zone:
		exit_zone.body_entered.connect(_on_exit_zone_entered)
		exit_zone.monitoring = false
	
	# Рычаг
	if lever and lever.has_signal("interacted"):
		lever.interacted.connect(_on_lever_pulled)
	else:
		print("Lever error")
	
	# Стартовая зона
	if start_zone:
		start_zone.body_entered.connect(_on_start_zone_entered)
	
	# Смерть игрока
	if player and player.has_node("HealthComponent"):
		player.health_component.died.connect(_on_player_died)

func _on_start_zone_entered(body):
	if not body.is_in_group("player"): return
	
	# Сохранение и чекпоинт
	SaveManager.save_checkpoint()
	LevelManager.set_checkpoint(global_position)
	
	if dialog_started: return
	dialog_started = true
	start_zone.queue_free()
	
	# Заставка
	if segment_title:
		segment_title.show_title("Берег реки")
		await get_tree().create_timer(1.0).timeout
	
	# Диалог
	DialogueManager.start_dialogue("segment1_bridge")
	await DialogueManager.dialogue_finished
	
	# Подсказка
	GameManager.show_hint.emit("Нажмите E, чтобы взаимодействовать с рычагом", 4.0)

func _on_lever_pulled():
	if lever_used: return
	lever_used = true
	
	# Опускаем мост
	if bridge.has_method("activate"):
		bridge.activate(true)
	
	# Активируем врага
	if enemy:
		enemy.visible = true
		enemy.set_physics_process(true)
		GameManager.show_hint.emit("ЛКМ – атака, Пробел – уклонение", 5.0)
		if enemy.has_node("HealthComponent"):
			# Проверяем, что сигнал ещё не подключён
			if not enemy.health_component.died.is_connected(_on_enemy_defeated):
				enemy.health_component.died.connect(_on_enemy_defeated)

func _on_enemy_defeated():
	print("Enemy defeated, showing memory")
	
	if memory:
		# Перемещаем осколок к игроку
		var player_node = get_tree().get_first_node_in_group("player")
		if player_node:
			memory.global_position = player_node.global_position + Vector2(0, -50)
			print("Memory moved to: ", memory.global_position)
		
		memory.visible = true
		memory.monitoring = true
		memory.monitorable = true
		
		# Включаем коллизию
		if memory.has_node("CollisionShape2D"):
			var coll = memory.get_node("CollisionShape2D")
			coll.disabled = false
			print("CollisionShape2D disabled: ", coll.disabled)
		
		GameManager.show_hint.emit("Нажмите E, чтобы взять осколок памяти", 3.0)
		# Выход активируем сразу (осколок не обязателен)
		_enable_exit()
	else:
		print("Memory is null!")
		_enable_exit()

func _enable_exit():
	if exit_zone:
		exit_zone.monitoring = true
		print("Exit zone activated")

func _on_exit_zone_entered(body):
	if body.is_in_group("player"):
		transition_to_scene("res://scenes/levels/water_level_2.tscn")

func transition_to_scene(target: String):
	var black = ColorRect.new()
	black.color = Color.BLACK
	black.size = get_viewport().get_visible_rect().size
	black.position = Vector2.ZERO  # ← важно!
	black.z_index = 100
	add_child(black)
	
	var tween = create_tween()
	tween.tween_property(black, "modulate:a", 1.0, 0.5)
	await tween.finished
	get_tree().change_scene_to_file(target)

func _on_player_died():
	var end_screen = end_screen_scene.instantiate()
	add_child(end_screen)

# ==================== ПАУЗА ====================

var pause_menu_scene = preload("res://scenes/ui/PauseMenu.tscn")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not get_tree().paused:
		var menu = pause_menu_scene.instantiate()
		add_child(menu)
		get_tree().paused = true
