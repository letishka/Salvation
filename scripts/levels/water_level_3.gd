extends Node2D

@onready var pre_battle_soul1 = $WaterSoul1
@onready var pre_battle_soul2 = $WaterSoul2
@onready var boss = $Boss
@onready var portal = $Portal
@onready var memory_father_stone = $MemoryFatherStone
@onready var memory_toy = $MemoryToy
@onready var start_zone = $StartZone
@onready var segment_title = $SegmentTitle
@onready var hint_system = $HintSystem
@onready var spawn_sound = $SpawnSound  

var dialog_started = false
var boss_defeated = false
var boss_triggered = false
var souls_killed = 0
var end_screen_scene = preload("res://scenes/ui/end_screen.tscn")
var pause_menu_scene = preload("res://scenes/ui/PauseMenu.tscn")

func _ready():
	MusicManager.play_game_music(1.0)
	
	if spawn_sound:
		spawn_sound.play()
	if portal:
		portal.visible = false
		portal.monitoring = false
		portal.body_entered.connect(_on_portal_entered)
	if memory_father_stone:
		memory_father_stone.visible = false
	if memory_toy:
		memory_toy.visible = false
	if start_zone:
		start_zone.body_entered.connect(_on_start_zone_entered)
	if pre_battle_soul1 and pre_battle_soul1.has_node("HealthComponent"):
		pre_battle_soul1.health_component.died.connect(_on_soul_defeated)
	if pre_battle_soul2 and pre_battle_soul2.has_node("HealthComponent"):
		pre_battle_soul2.health_component.died.connect(_on_soul_defeated)
	if boss:
		boss.visible = true
		boss.set_physics_process(false)
		if boss.has_node("AttackCooldown"):
			boss.get_node("AttackCooldown").stop()
		if boss.has_node("DetectionArea"):
			boss.get_node("DetectionArea").monitoring = false
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_node("HealthComponent"):
		if not player.health_component.died.is_connected(_on_player_died):
			player.health_component.died.connect(_on_player_died)
	
func _on_soul_defeated():
	souls_killed += 1
	if souls_killed >= 2:
		_activate_boss()

func _activate_boss():
	if boss and not boss_defeated:
		boss.set_physics_process(true)
		if boss.has_node("DetectionArea"):
			var detection = boss.get_node("DetectionArea")
			detection.monitoring = true
			detection.body_entered.connect(_on_boss_detection_entered)

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

func _on_boss_detection_entered(body):
	if not body.is_in_group("player"): return
	if boss_triggered: return
	if boss_defeated: return
	
	boss_triggered = true
	
	DialogueManager.start_dialogue("boss_before")
	await DialogueManager.dialogue_finished

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

		if FileAccess.file_exists("user://checkpoint.tscn"):
			DirAccess.remove_absolute("user://checkpoint.tscn")
		
		get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
		
func _on_player_died():
	var end_screen = end_screen_scene.instantiate()
	add_child(end_screen)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not get_tree().paused and not DialogueManager.is_active():
		var menu = pause_menu_scene.instantiate()
		add_child(menu)
		get_tree().paused = true
