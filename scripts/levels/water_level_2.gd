extends Node2D

# ----- Узлы уровня -----
@onready var campfire = $Bonfire
@onready var gate = $Gate
@onready var torch_holders = [$TorchHolder1, $TorchHolder2, $TorchHolder3]
@onready var torch_pickups = [$TorchPickup1, $TorchPickup2, $TorchPickup3]

# Враги
@onready var enemy_archer = $EnemyArcher
@onready var enemy_soldier1 = $ShadowSoldier1
@onready var enemy_soldier2 = $ShadowSoldier2

@onready var start_zone = $StartZone
@onready var exit_zone = $ExitZone
@onready var memory_after_battle = $MemoryAfterBattle
@onready var memory_flashback = $MemoryFlashback
@onready var segment_title = $SegmentTitle
@onready var hint_system = $HintSystem

# ----- Переменные -----
var dialog_started = false
var first_torch_placed = false
var battle_started = false
var enemies_defeated = false

# Сохраняем позиции врагов для респавна
var archer_spawn_pos: Vector2
var soldier1_spawn_pos: Vector2
var soldier2_spawn_pos: Vector2

# Сцены врагов
var archer_scene = preload("res://scenes/characters/enemies/archer.tscn")
var soldier_scene = preload("res://scenes/characters/enemies/shadow_soldier.tscn")

# ==================== ГОЛОВНЫЕ ФУНКЦИИ ====================

func _ready():
	# Сохраняем позиции врагов
	archer_spawn_pos = enemy_archer.global_position
	soldier1_spawn_pos = enemy_soldier1.global_position
	soldier2_spawn_pos = enemy_soldier2.global_position
	
	# Зона выхода изначально выключена
	if exit_zone:
		exit_zone.body_entered.connect(_on_exit_zone_entered)
		exit_zone.monitoring = false
	
	# Подключаем сигнал активации портала от ворот
	gate.portal_activated.connect(_on_gate_portal_activated)
	
	# Враги изначально НЕ АКТИВНЫ
	_set_enemies_active(false)
	
	# Осколки памяти
	memory_flashback.visible = true
	memory_after_battle.visible = false
	
	# Настройка ворот
	gate.required_torches = 3
	
	# Подключаем сигналы от подставок для факелов
	for holder in torch_holders:
		holder.torch_placed.connect(_on_torch_placed)
	
	# Стартовая зона
	start_zone.body_entered.connect(_on_start_zone_entered)
	
	# Подставка TorchHolder4 уже горит изначально
	if $TorchHolder4:
		$TorchHolder4.is_lit = true
		$TorchHolder4.holder_empty.visible = false
		$TorchHolder4.holder_lit.visible = true
		$TorchHolder4.holder_light.enabled = true
		$TorchHolder4.torch_placed.emit()

func _set_enemies_active(active: bool):
	# Лучник
	if is_instance_valid(enemy_archer):
		enemy_archer.visible = active
		enemy_archer.set_physics_process(active)
		enemy_archer.set_collision_layer_value(1, active)
		enemy_archer.set_collision_mask_value(1, active)
	
	# Солдаты
	if is_instance_valid(enemy_soldier1):
		enemy_soldier1.visible = active
		enemy_soldier1.set_physics_process(active)
		enemy_soldier1.set_collision_layer_value(1, active)
		enemy_soldier1.set_collision_mask_value(1, active)
	
	if is_instance_valid(enemy_soldier2):
		enemy_soldier2.visible = active
		enemy_soldier2.set_physics_process(active)
		enemy_soldier2.set_collision_layer_value(1, active)
		enemy_soldier2.set_collision_mask_value(1, active)

# ==================== СТАРТ УРОВНЯ ====================

func _on_start_zone_entered(body):
	if not body.is_in_group("player"): return
	SaveManager.save_checkpoint()
	LevelManager.set_checkpoint(global_position)
	
	if dialog_started: return
	dialog_started = true
	start_zone.queue_free()
	
	if segment_title:
		segment_title.show_title("Поляна с факелами")
		await get_tree().create_timer(1.0).timeout
	
	# Ждём, пока игрок подберёт осколок воспоминания
	await memory_flashback.tree_exited
	
	DialogueManager.start_dialogue("segment2_flashback")
	await DialogueManager.dialogue_finished
	
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("heal_player"):
		player.heal_player(30)
	
	GameManager.show_hint.emit("Рядом с костром лежит факел. Нажмите E, чтобы подобрать", 4.0)

# ==================== ФАКЕЛЫ ====================

func _on_torch_placed():
	if not first_torch_placed:
		first_torch_placed = true
		_start_battle()

func _start_battle():
	if battle_started: return
	battle_started = true
	
	print("Первый факел установлен — начинаем бой!")
	
	# Удаляем старых врагов (если есть)
	if is_instance_valid(enemy_archer):
		enemy_archer.queue_free()
	if is_instance_valid(enemy_soldier1):
		enemy_soldier1.queue_free()
	if is_instance_valid(enemy_soldier2):
		enemy_soldier2.queue_free()
	
	# СОЗДАЁМ НОВЫХ ВРАГОВ
	# Лучник
	var new_archer = archer_scene.instantiate()
	new_archer.global_position = archer_spawn_pos
	new_archer.visible = true
	new_archer.set_physics_process(true)
	add_child(new_archer)
	enemy_archer = new_archer
	
	# Солдат 1
	var new_soldier1 = soldier_scene.instantiate()
	new_soldier1.global_position = soldier1_spawn_pos
	new_soldier1.visible = true
	new_soldier1.set_physics_process(true)
	add_child(new_soldier1)
	enemy_soldier1 = new_soldier1
	
	# Солдат 2
	var new_soldier2 = soldier_scene.instantiate()
	new_soldier2.global_position = soldier2_spawn_pos
	new_soldier2.visible = true
	new_soldier2.set_physics_process(true)
	add_child(new_soldier2)
	enemy_soldier2 = new_soldier2
	
	GameManager.show_hint.emit("ЛКМ – атака, Пробел – уклонение", 5.0)
	
	# Подключаем сигналы смерти
	if not enemy_archer.health_component.died.is_connected(_on_enemy_defeated):
		enemy_archer.health_component.died.connect(_on_enemy_defeated)
	if not enemy_soldier1.health_component.died.is_connected(_on_enemy_defeated):
		enemy_soldier1.health_component.died.connect(_on_enemy_defeated)
	if not enemy_soldier2.health_component.died.is_connected(_on_enemy_defeated):
		enemy_soldier2.health_component.died.connect(_on_enemy_defeated)

func _on_enemy_defeated():
	# Проверяем, что все три врага мертвы
	var archer_dead = not is_instance_valid(enemy_archer) or enemy_archer.health_component.current_health <= 0
	var soldier1_dead = not is_instance_valid(enemy_soldier1) or enemy_soldier1.health_component.current_health <= 0
	var soldier2_dead = not is_instance_valid(enemy_soldier2) or enemy_soldier2.health_component.current_health <= 0
	
	if archer_dead and soldier1_dead and soldier2_dead and not enemies_defeated:
		enemies_defeated = true
		_after_battle()

func _after_battle():
	print("Враги побеждены!")
	
	# Очищаем ссылки
	enemy_archer = null
	enemy_soldier1 = null
	enemy_soldier2 = null
	
	# Появляется осколок памяти
	memory_after_battle.visible = true
	GameManager.show_hint.emit("Осколок памяти появился. Подойдите и нажмите E", 3.0)
	
	await memory_after_battle.tree_exited
	print("Осколок подобран, уровень продолжается")

# ==================== ВОРОТА И ПОРТАЛ ====================

func _on_gate_portal_activated():
	if exit_zone:
		exit_zone.monitoring = true
		GameManager.show_hint.emit("Портал открыт! Войди в ворота.", 3.0)

# ==================== ПЕРЕХОДЫ ====================

func _on_exit_zone_entered(body):
	if body.is_in_group("player"):
		transition_to_scene("res://scenes/levels/water_level_3.tscn")

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

# ==================== ПАУЗА ====================

var pause_menu_scene = preload("res://scenes/ui/PauseMenu.tscn")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not get_tree().paused:
		var menu = pause_menu_scene.instantiate()
		add_child(menu)
		get_tree().paused = true
