extends Node2D

# ----- Узлы уровня -----
@onready var pre_battle_soul1 = $WaterSoul1
@onready var pre_battle_soul2 = $WaterSoul2
@onready var boss = $Boss
@onready var portal = $Portal
@onready var memory_father_stone = $MemoryFatherStone
@onready var memory_toy = $MemoryToy
@onready var start_zone = $StartZone
@onready var segment_title = $SegmentTitle
@onready var hint_system = $HintSystem

# ----- Переменные -----
var dialog_started = false
var boss_defeated = false
var boss_spawned = false
var boss_triggered = false
var soul1_died = false
var soul2_died = false
var end_screen_scene = preload("res://scenes/ui/end_screen.tscn")

# Сцены врагов
var water_soul_scene = preload("res://scenes/characters/enemies/water_soul.tscn")
var boss_scene = preload("res://scenes/characters/enemies/first_boss.tscn")

# Сохраняем позиции
var soul1_spawn_pos: Vector2
var soul2_spawn_pos: Vector2
var boss_spawn_pos: Vector2

# ==================== ГОЛОВНЫЕ ФУНКЦИИ ====================

func _ready():
	# Сохраняем позиции
	if pre_battle_soul1:
		soul1_spawn_pos = pre_battle_soul1.global_position
	else:
		soul1_spawn_pos = Vector2(1500, 500)
	
	if pre_battle_soul2:
		soul2_spawn_pos = pre_battle_soul2.global_position
	else:
		soul2_spawn_pos = Vector2(1700, 500)
	
	if boss:
		boss_spawn_pos = boss.global_position
	else:
		boss_spawn_pos = Vector2(1600, 500)
	
	# Удаляем старого босса из сцены (если есть)
	if boss and is_instance_valid(boss):
		boss.queue_free()
	boss = null
	
	# Портал изначально скрыт
	if portal:
		portal.visible = false
		portal.monitoring = false
		portal.body_entered.connect(_on_portal_entered)
	
	# Скрытые воспоминания
	if memory_father_stone:
		memory_father_stone.visible = false
	if memory_toy:
		memory_toy.visible = false
	
	# Стартовая зона
	if start_zone:
		start_zone.body_entered.connect(_on_start_zone_entered)
	
	# Создаём водных духов
	_spawn_pre_battle_enemies()

func _spawn_pre_battle_enemies():
	if is_instance_valid(pre_battle_soul1):
		pre_battle_soul1.queue_free()
	if is_instance_valid(pre_battle_soul2):
		pre_battle_soul2.queue_free()
	
	# Сброс флагов
	soul1_died = false
	soul2_died = false
	boss_spawned = false
	
	var new_soul1 = water_soul_scene.instantiate()
	new_soul1.global_position = soul1_spawn_pos
	new_soul1.visible = true
	new_soul1.set_physics_process(true)
	add_child(new_soul1)
	pre_battle_soul1 = new_soul1
	
	var new_soul2 = water_soul_scene.instantiate()
	new_soul2.global_position = soul2_spawn_pos
	new_soul2.visible = true
	new_soul2.set_physics_process(true)
	add_child(new_soul2)
	pre_battle_soul2 = new_soul2

func _process(delta):
	# Проверяем, не создан ли уже босс
	if boss_spawned:
		return
	
	# Проверяем, существуют ли духи
	if not is_instance_valid(pre_battle_soul1):
		soul1_died = true
	else:
		# Если дух существует, проверяем его здоровье
		if pre_battle_soul1.has_node("HealthComponent"):
			var health = pre_battle_soul1.get_node("HealthComponent")
			if health.current_health <= 0:
				soul1_died = true
	
	if not is_instance_valid(pre_battle_soul2):
		soul2_died = true
	else:
		if pre_battle_soul2.has_node("HealthComponent"):
			var health = pre_battle_soul2.get_node("HealthComponent")
			if health.current_health <= 0:
				soul2_died = true
	
	# Если оба духа мертвы, спавним босса
	if soul1_died and soul2_died and not boss_spawned:
		print("Оба духа убиты! Создаём босса!")
		_spawn_boss()

func _spawn_boss():
	if boss_spawned: return
	boss_spawned = true
	
	print("Создаём босса!")
	
	var new_boss = boss_scene.instantiate()
	new_boss.global_position = boss_spawn_pos
	new_boss.visible = true
	new_boss.set_physics_process(true)
	add_child(new_boss)
	boss = new_boss
	
	# Подключаем сигнал смерти босса
	if boss.has_node("HealthComponent"):
		boss.get_node("HealthComponent").died.connect(_on_boss_defeated)
	
	if boss.has_node("DetectionArea"):
		var detection = boss.get_node("DetectionArea")
		detection.body_entered.connect(_on_boss_detection_entered)

# ==================== СТАРТ УРОВНЯ ====================

func _on_start_zone_entered(body):
	if not body.is_in_group("player"): return
	SaveManager.save_checkpoint()
	LevelManager.set_checkpoint(global_position)
	
	if dialog_started: return
	dialog_started = true
	if start_zone:
		start_zone.queue_free()
	
	if segment_title:
		segment_title.show_title("Мост – Память о солдате")
		await get_tree().create_timer(1.0).timeout
	
	# Активируем водных духов
	if pre_battle_soul1 and is_instance_valid(pre_battle_soul1):
		pre_battle_soul1.visible = true
		pre_battle_soul1.set_physics_process(true)
	if pre_battle_soul2 and is_instance_valid(pre_battle_soul2):
		pre_battle_soul2.visible = true
		pre_battle_soul2.set_physics_process(true)

# ==================== ОБНАРУЖЕНИЕ ИГРОКА БОССОМ ====================

func _on_boss_detection_entered(body):
	if not body.is_in_group("player"): return
	if boss_triggered: return
	if boss_defeated: return
	
	boss_triggered = true
	
	DialogueManager.start_dialogue("boss_before")
	await DialogueManager.dialogue_finished

# ==================== БОСС ====================

func _on_boss_defeated():
	if boss_defeated: return
	boss_defeated = true
	
	DialogueManager.start_dialogue("boss_after")
	await DialogueManager.dialogue_finished
	
	if memory_father_stone and is_instance_valid(memory_father_stone):
		memory_father_stone.visible = true
	if memory_toy and is_instance_valid(memory_toy):
		memory_toy.visible = true
	GameManager.show_hint.emit("Обнаружены скрытые воспоминания. Подойдите и нажмите E (необязательно)", 3.0)
	
	_activate_portal()

func _activate_portal():
	if portal:
		portal.visible = true
		portal.monitoring = true
		portal.modulate = Color(1, 1, 1, 0)
		
		var tween = create_tween()
		tween.tween_property(portal, "modulate", Color(1, 1, 1, 1), 1.0)
		
		GameManager.show_hint.emit("Портал открыт! Войди в него.", 3.0)

func _on_portal_entered(body):
	if body.is_in_group("player"):
		if segment_title:
			segment_title.show_title("ПРОДОЛЖЕНИЕ СЛЕДУЕТ...", 4.0)
			await get_tree().create_timer(4.0).timeout
		
		transition_to_scene("res://scenes/ui/MainMenu.tscn")

# ==================== ПЕРЕХОДЫ ====================

func transition_to_scene(target: String):
	var black = ColorRect.new()
	black.color = Color.BLACK
	black.size = get_viewport().get_visible_rect().size
	black.position = Vector2.ZERO
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
