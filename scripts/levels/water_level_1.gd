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

@onready var spawn_sound = $SpawnSound  

var lever_used = false
var dialog_started = false
var end_screen_scene = preload("res://scenes/ui/end_screen.tscn")

func _ready():
	MusicManager.play_game_music(1.0)
	
	if spawn_sound:
		spawn_sound.play()
		
	if bridge.has_method("activate"):
		bridge.activate(false)
	
	if enemy:
		enemy.visible = false
		enemy.set_physics_process(false)
	
	if memory:
		memory.visible = false
		if memory.has_node("CollisionShape2D"):
			memory.get_node("CollisionShape2D").disabled = false
		memory.monitoring = true
		memory.monitorable = true
	
	if exit_zone:
		exit_zone.body_entered.connect(_on_exit_zone_entered)
		exit_zone.monitoring = false
	
	if lever and lever.has_signal("interacted"):
		lever.interacted.connect(_on_lever_pulled)
	
	if start_zone:
		start_zone.body_entered.connect(_on_start_zone_entered)
	
	if player and player.has_node("HealthComponent"):
		player.health_component.died.connect(_on_player_died)
	
func _on_start_zone_entered(body):
	if not body.is_in_group("player"): return
	
	SaveManager.save_checkpoint()
	LevelManager.set_checkpoint(global_position)
	
	if dialog_started: return
	dialog_started = true
	start_zone.queue_free()
	
	if segment_title:
		segment_title.show_title("Берег реки")
		await get_tree().create_timer(1.0).timeout
	
	DialogueManager.start_dialogue("segment1_bridge")
	await DialogueManager.dialogue_finished
	
	GameManager.show_hint.emit("Нажмите E, чтобы взаимодействовать с объектами", 4.0)

func _on_lever_pulled():
	if lever_used: return
	lever_used = true
	
	if bridge.has_method("activate"):
		bridge.activate(true)
	
	if enemy:
		enemy.visible = true
		enemy.set_physics_process(true)
		GameManager.show_hint.emit("ЛКМ – атака мечом", 5.0)
		if enemy.has_node("HealthComponent"):
			if not enemy.health_component.died.is_connected(_on_enemy_defeated):
				enemy.health_component.died.connect(_on_enemy_defeated)

func _on_enemy_defeated():
	if memory:
		var player_node = get_tree().get_first_node_in_group("player")
		if player_node:
			memory.global_position = player_node.global_position + Vector2(0, -50)
		
		memory.visible = true
		memory.monitoring = true
		memory.monitorable = true
		
		if memory.has_node("CollisionShape2D"):
			memory.get_node("CollisionShape2D").disabled = false
		
		GameManager.show_hint.emit("Нажмите E, чтобы взять осколок памяти", 3.0)
		_enable_exit()
	else:
		_enable_exit()

func _enable_exit():
	if exit_zone:
		exit_zone.monitoring = true

func _on_exit_zone_entered(body):
	if body.is_in_group("player"):
		get_tree().change_scene_to_file("res://scenes/levels/water_level_2.tscn")

func _on_player_died():
	add_child(end_screen_scene.instantiate())

var pause_menu_scene = preload("res://scenes/ui/PauseMenu.tscn")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not get_tree().paused and not DialogueManager.is_active():
		add_child(pause_menu_scene.instantiate())
		get_tree().paused = true
