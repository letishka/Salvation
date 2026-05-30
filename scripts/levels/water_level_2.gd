extends Node2D

@onready var campfire = $Campfire
@onready var gate = $Gate
@onready var torch_holders = [$TorchHolder1, $TorchHolder2, $TorchHolder3]
@onready var torch_pickups = [$TorchPickup1, $TorchPickup2, $TorchPickup3]

@onready var enemy_soldier1 = $EnemySoldier1
@onready var enemy_soldier2 = $EnemySoldier2
@onready var start_zone = $StartZone
@onready var exit_zone = $ExitZone
@onready var memory_after_battle = $MemoryAfterBattle
@onready var segment_title = $SegmentTitle
@onready var hint_system = $HintSystem

var dialog_started = false
var first_torch_placed = false
var enemies_defeated = false
var exit_enabled = false

func _ready():
	enemy_soldier1.visible = false
	enemy_soldier1.set_physics_process(false)
	enemy_soldier2.visible = false
	enemy_soldier2.set_physics_process(false)
	
	memory_after_battle.visible = false
	
	gate.required_torches = 3
	gate.opened.connect(_on_gate_opened)
	
	exit_zone.body_entered.connect(_on_exit_zone_entered)
	exit_zone.monitoring = false
	
	for holder in torch_holders:
		holder.torch_placed.connect(_on_torch_placed)
	
	start_zone.body_entered.connect(_on_start_zone_entered)

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
	

	enemy_soldier1.visible = true
	enemy_soldier1.set_physics_process(true)
	enemy_soldier2.visible = true
	enemy_soldier2.set_physics_process(true)
	
	await _wait_for_flashback_enemies()
	
	DialogueManager.start_dialogue("segment2_flashback")
	await DialogueManager.dialogue_finished

	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("heal_player"):
		player.heal_player(30)

	GameManager.show_hint.emit("Рядом с костром лежит факел. Нажмите E, чтобы подобрать", 4.0)

func _wait_for_flashback_enemies():
	while not (enemy_soldier1.health_component.current_health <= 0 and \
			   enemy_soldier2.health_component.current_health <= 0):
		await get_tree().create_timer(0.5).timeout

func _on_torch_placed():
	if not first_torch_placed:
		first_torch_placed = true
		_spawn_second_battle_enemies()
	else:
		if gate.lit_torches >= 3:
			pass

func _spawn_second_battle_enemies():
	enemy_soldier1.visible = true
	enemy_soldier1.set_physics_process(true)
	enemy_soldier2.visible = true
	enemy_soldier2.set_physics_process(true)
	
	GameManager.show_hint.emit("Противники! Защищайтесь!", 3.0)
	
	await _wait_for_second_battle_enemies()
	
	memory_after_battle.visible = true
	GameManager.show_hint.emit("Осколок памяти появился. Подойдите и нажмите E", 3.0)
	
	await memory_after_battle.tree_exited
	

func _wait_for_second_battle_enemies():
	while not (enemy_soldier1.health_component.current_health <= 0 and \
			   enemy_soldier2.health_component.current_health <= 0):
		await get_tree().create_timer(0.5).timeout

func _on_gate_opened():
	exit_zone.monitoring = true

func _on_exit_zone_entered(body):
	if body.is_in_group("player"):
		call_deferred("_change_to_next_level")

func _change_to_next_level():
	get_tree().change_scene_to_file("res://scenes/levels/water_level_3.tscn")
	
func transition_to_scene(target: String):
	var black = ColorRect.new()
	black.color = Color.BLACK
	black.size = get_viewport().get_visible_rect().size
	black.z_index = 100
	add_child(black)
	
	var tween = create_tween()
	tween.tween_property(black, "modulate:a", 1.0, 0.5)
	await tween.finished
	get_tree().change_scene_to_file(target)
