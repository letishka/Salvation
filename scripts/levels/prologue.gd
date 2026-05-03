extends Node2D

@onready var player = $Player
@onready var portal = $Portal
@onready var dialogue_ui = $DialogueUI  # если отдельный узел

var prologue_ended = false

func _ready():
	player.set_process_input(false)
	player.set_physics_process(false)
	
	await show_dialogue_sequence()
	
	player.set_process_input(true)
	player.set_physics_process(true)
	prologue_ended = true
	
	show_hint("Иди к свету")

func show_dialogue_sequence():

	DialogueManager.start_dialogue("prologue_text")
	await DialogueManager.dialogue_finished

	$HeartbeatSound.play()
	await get_tree().create_timer(2).timeout
	
	DialogueManager.start_dialogue("prologue_heartbeat")
	await DialogueManager.dialogue_finished
	
	DialogueManager.start_dialogue("prologue_wakeup")
	await DialogueManager.dialogue_finished

func show_hint(text: String):
	var hint = $CanvasLayer/HintLabel
	hint.text = text
	hint.visible = true
	await get_tree().create_timer(3.0).timeout
	hint.visible = false
