extends Control

@onready var text_label = $RichTextLabel
@onready var timer = $Timer
@onready var audio_player = $AudioStreamPlayer

var lines = []  # заполним из JSON
var index = 0
var is_heartbeat = false

func _ready():
	# Загружаем пролог из DialogueManager (JSON уже загружен в менеджере)
	var prologue_lines = DialogueManager.get_dialogue_lines("prologue_text")
	for line in prologue_lines:
		lines.append(line.text)
	# Добавляем реплики сердцебиения
	lines.append("")  # маркер паузы для сердца
	var heartbeat_lines = DialogueManager.get_dialogue_lines("prologue_heartbeat")
	for line in heartbeat_lines:
		lines.append(line.text)
	
	show()
	text_label.visible_characters = 0
	_next_line()

func _next_line():
	if index >= lines.size():
		_finish_prologue()
		return
	var line = lines[index]
	if line == "":
		# Пауза с сердцебиением
		audio_player.play()
		timer.start(2.0)  # длительность звука + пауза
		index += 1
		return
	text_label.text = line
	text_label.visible_characters = 0
	# Печатаем по буквам
	while text_label.visible_characters < text_label.text.length():
		text_label.visible_characters += 1
		await get_tree().create_timer(0.05).timeout
	index += 1
	timer.start(2.5)  # показать строку 2.5 сек

func _on_timer_timeout():
	_next_line()

func _finish_prologue():
	# Переход на водный уровень
	get_tree().change_scene_to_file("res://scenes/levels/water_level_1.tscn")
