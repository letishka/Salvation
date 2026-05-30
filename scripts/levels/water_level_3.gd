extends Node2D

@onready var pre_battle_soldier1 = $PreBattleSoldier1
@onready var pre_battle_soldier2 = $PreBattleSoldier2
@onready var boss = $Boss
@onready var memory_father_stone = $MemoryFatherStone
@onready var memory_toy = $MemoryToy
@onready var start_zone = $StartZone
@onready var segment_title = $SegmentTitle

var dialog_started = false
var boss_defeated = false

func _ready():
	pre_battle_soldier1.visible = true
	pre_battle_soldier1.set_physics_process(true)
	pre_battle_soldier2.visible = true
	pre_battle_soldier2.set_physics_process(true)
	
	boss.visible = false
	boss.set_physics_process(false)
	
	memory_father_stone.visible = false
	memory_toy.visible = false

	start_zone.body_entered.connect(_on_start_zone_entered)

func _on_start_zone_entered(body):
	if not body.is_in_group("player"): return
	SaveManager.save_checkpoint()
	LevelManager.set_checkpoint(global_position)
	
	if dialog_started: return
	dialog_started = true
	start_zone.queue_free()
	
	if segment_title:
		segment_title.show_title("Мост – Память о солдате")
		await get_tree().create_timer(1.0).timeout

	await _wait_for_pre_battle_enemies()
	
	DialogueManager.start_dialogue("boss_before")
	await DialogueManager.dialogue_finished
	
	boss.visible = true
	boss.set_physics_process(true)
	boss.health_component.died.connect(_on_boss_defeated)

func _wait_for_pre_battle_enemies():
	while not (pre_battle_soldier1.health_component.current_health <= 0 and \
			   pre_battle_soldier2.health_component.current_health <= 0):
		await get_tree().create_timer(0.5).timeout

func _on_boss_defeated():
	if boss_defeated: return
	boss_defeated = true
	
	DialogueManager.start_dialogue("boss_after")
	await DialogueManager.dialogue_finished
	
	DialogueManager.start_dialogue("ability_water")
	await DialogueManager.dialogue_finished
	
	memory_father_stone.visible = true
	memory_toy.visible = true
	GameManager.show_hint.emit("Обнаружены скрытые воспоминания. Подойдите и нажмите E", 3.0)
	
	await _wait_for_memories_collected()
	
	if segment_title:
		segment_title.show_title("ПРОДОЛЖЕНИЕ СЛЕДУЕТ...", 4.0)
		await get_tree().create_timer(4.0).timeout
	
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func _wait_for_memories_collected():
	while not (memory_father_stone.is_queued_for_deletion() and memory_toy.is_queued_for_deletion()):
		await get_tree().create_timer(0.5).timeout
		
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
