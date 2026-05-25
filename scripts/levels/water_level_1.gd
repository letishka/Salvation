extends Node2D

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

func _ready():
	if bridge.has_method("activate"):
		bridge.activate(false)
	else:
		print("Bridge error")
	
	if enemy:
		enemy.visible = false
		enemy.set_physics_process(false)
	
	if memory:
		memory.visible = false
	
	if exit_zone:
		exit_zone.body_entered.connect(_on_exit_zone_entered)
		exit_zone.monitoring = false
	
	if lever and lever.has_signal("interacted"):
		lever.interacted.connect(_on_lever_pulled)
	else:
		print("Lever error")
	
	if start_zone:
		start_zone.body_entered.connect(_on_start_zone_entered)

func _on_start_zone_entered(body):
	if not body.is_in_group("player"): return
	if dialog_started: return
	dialog_started = true
	start_zone.queue_free()
	
	if segment_title:
		segment_title.show_title("Берег реки")
		await get_tree().create_timer(1.0).timeout
	
	DialogueManager.start_dialogue("segment1_bridge")
	await DialogueManager.dialogue_finished
	GameManager.show_hint.emit("Нажмите E, чтобы взаимодействовать с рычагом", 4.0)

func _on_lever_pulled():
	if lever_used: return
	lever_used = true
	if bridge.has_method("activate"):
		bridge.activate(true)
	if enemy:
		enemy.visible = true
		enemy.set_physics_process(true)
		GameManager.show_hint.emit("ЛКМ – атака", 5.0)
		if enemy.has_node("HealthComponent"):
			enemy.health_component.died.connect(_on_enemy_defeated)

func _on_enemy_defeated():
	print("Enemy defeated, showing memory")
	if memory:
		memory.visible = true
		print("Memory position: ", memory.global_position)
		print("Player position: ", get_tree().get_first_node_in_group("player").global_position)
		print("Memory visible set to true, position: ", memory.global_position, ", visible: ", memory.visible)
		if memory.has_node("CollisionShape2D"):
			var coll = memory.get_node("CollisionShape2D")
			print("CollisionShape2D disabled: ", coll.disabled)
		GameManager.show_hint.emit("Нажмите E, чтобы взять осколок памяти", 3.0)
		memory.tree_exited.connect(_enable_exit)
	else:
		print("Memory is null!")

func _enable_exit():
	if exit_zone:
		exit_zone.monitoring = true

func _on_exit_zone_entered(body):
	if body.is_in_group("player"):
		call_deferred("_change_to_next_level")

func _change_to_next_level():
	get_tree().change_scene_to_file("res://scenes/levels/water_level_2.tscn")
