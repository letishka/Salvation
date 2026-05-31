extends Node2D

@onready var pre_battle_soldier1 = $PreBattleSoldier1
@onready var pre_battle_soldier2 = $PreBattleSoldier2
@onready var boss = $Boss
@onready var memory_father_stone = $MemoryFatherStone
@onready var memory_toy = $MemoryToy
@onready var start_zone = $StartZone
@onready var segment_title = $SegmentTitle
@onready var hint_system = $HintSystem

var dialog_started = false
var boss_defeated = false
var end_screen_scene = preload("res://scenes/ui/end_screen.tscn")

func _ready():
	# Проверяем, что все узлы найдены
	if not pre_battle_soldier1:
		print("Ошибка: PreBattleSoldier1 не найден в сцене!")
		return
	if not pre_battle_soldier2:
		print("Ошибка: PreBattleSoldier2 не найден в сцене!")
		return
	if not boss:
		print("Ошибка: Boss не найден в сцене!")
		return
	if not memory_father_stone:
		print("Ошибка: MemoryFatherStone не найден в сцене!")
		return
	if not memory_toy:
		print("Ошибка: MemoryToy не найден в сцене!")
		return
	
	# Настройка врагов перед боссом
	pre_battle_soldier1.visible = true
	pre_battle_soldier1.set_physics_process(true)
	pre_battle_soldier2.visible = true
	pre_battle_soldier2.set_physics_process(true)
	
	# Босс изначально не виден
	boss.visible = false
	boss.set_physics_process(false)
	
	# Скрытые воспоминания
	memory_father_stone.visible = false
	memory_toy.visible = false
	
	# Стартовая зона
	if start_zone:
		start_zone.body_entered.connect(_on_start_zone_entered)
	
	# Смерть игрока
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_node("HealthComponent"):
		player.health_component.died.connect(_on_player_died)

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
	
	# Ждём окончания стычки с двумя солдатами
	await _wait_for_pre_battle_enemies()
	
	# Диалог перед боссом
	DialogueManager.start_dialogue("boss_before")
	await DialogueManager.dialogue_finished
	
	# Появление босса
	if boss:
		boss.visible = true
		boss.set_physics_process(true)
		boss.health_component.died.connect(_on_boss_defeated)

func _wait_for_pre_battle_enemies():
	while pre_battle_soldier1 and pre_battle_soldier2 and \
		  is_instance_valid(pre_battle_soldier1) and is_instance_valid(pre_battle_soldier2) and \
		  (pre_battle_soldier1.health_component.current_health > 0 or \
		   pre_battle_soldier2.health_component.current_health > 0):
		await get_tree().create_timer(0.5).timeout
	
	print("Стычка перед боссом завершена")

func _on_boss_defeated():
	if boss_defeated: return
	boss_defeated = true
	
	DialogueManager.start_dialogue("boss_after")
	await DialogueManager.dialogue_finished
	
	DialogueManager.start_dialogue("ability_water")
	await DialogueManager.dialogue_finished
	
	if memory_father_stone and is_instance_valid(memory_father_stone):
		memory_father_stone.visible = true
	if memory_toy and is_instance_valid(memory_toy):
		memory_toy.visible = true
	GameManager.show_hint.emit("Обнаружены скрытые воспоминания. Подойдите и нажмите E", 3.0)
	
	await _wait_for_memories_collected()
	
	if segment_title:
		segment_title.show_title("ПРОДОЛЖЕНИЕ СЛЕДУЕТ...", 4.0)
		await get_tree().create_timer(4.0).timeout
	
	transition_to_scene("res://scenes/ui/MainMenu.tscn")

func _wait_for_memories_collected():
	# Ждём, пока оба осколка не будут удалены (подобраны)
	while (memory_father_stone and is_instance_valid(memory_father_stone) and not memory_father_stone.is_queued_for_deletion()) or \
		  (memory_toy and is_instance_valid(memory_toy) and not memory_toy.is_queued_for_deletion()):
		await get_tree().create_timer(0.5).timeout
	print("Все скрытые воспоминания собраны")

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
