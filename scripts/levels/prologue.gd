extends Node2D

@onready var world = $World
@onready var black_rect = $BlackRect
@onready var white_rect = $WhiteRect
@onready var center_text = $CenterText
@onready var heartbeat_player = $HeartbeatSound
@onready var player = $World/Player
@onready var portal = $World/Portal
@onready var hint_label = $CanvasLayer/HintLabel
@onready var player_ui = $World/Player/Ui

func _ready():
	$BackgroundMusic.play()
	$BackgroundMusic2.play()
	player.set_process_input(false)
	player.set_physics_process(false)
	
	white_rect.modulate.a = 0.0
	white_rect.visible = true
	black_rect.visible = true
	center_text.visible = false
	center_text.add_theme_color_override("default_color", Color.WHITE)
	portal.visible = false
	player_ui.visible = false
	
	await _show_history()
	await _heartbeat_and_inner_dialogue()
	await _white_flash()
	await _show_wakeup_dialogue()
	await _show_portal_animation()
	
	player.set_process_input(true)
	player.set_physics_process(true)
	
	if hint_label:
		hint_label.text = "Иди к свету"
		hint_label.visible = true
		await get_tree().create_timer(3.0).timeout
		hint_label.visible = false
	
	# portal.visible = true
	player_ui.visible = true
	
	await get_tree().create_timer(2).timeout
	get_tree().change_scene_to_file("res://scenes/levels/test.tscn")

func _show_history():
	var lines = DialogueManager.get_dialogue_lines("prologue_text")
	if not center_text or lines.is_empty():
		return
	var full_text = ""
	for line in lines:
		full_text += line.text + "\n\n"
	center_text.text = full_text.strip_edges()
	center_text.visible = true
	await get_tree().create_timer(5.0).timeout
	center_text.visible = false

func _heartbeat_and_inner_dialogue():
	if heartbeat_player:
		heartbeat_player.play()
	await get_tree().create_timer(1.5).timeout
	DialogueManager.start_dialogue("prologue_heartbeat")
	await DialogueManager.dialogue_finished

func _white_flash():
	var tween = create_tween()
	tween.tween_property(white_rect, "modulate:a", 1.0, 0.2)
	await tween.finished
	await get_tree().create_timer(0.3).timeout
	tween = create_tween()
	tween.tween_property(white_rect, "modulate:a", 0.0, 0.8)
	await tween.finished
	white_rect.visible = false
	black_rect.visible = false

func _show_wakeup_dialogue():
	DialogueManager.start_dialogue("prologue_wakeup")
	await DialogueManager.dialogue_finished

func _show_portal_animation():
	portal.visible = true
	portal.modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(portal, "modulate", Color(1, 1, 1, 1), 1.0)
	await tween.finished
