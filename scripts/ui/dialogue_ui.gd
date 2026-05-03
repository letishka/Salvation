extends CanvasLayer

@onready var panel = $Panel
@onready var portrait = $Panel/MarginContainer/HBoxContainer/TextureRect
@onready var name_label = $Panel/MarginContainer/HBoxContainer/VBoxContainer/Label
@onready var text_label = $Panel/MarginContainer/HBoxContainer/VBoxContainer/RichTextLabel
@onready var next_button = $Panel/MarginContainer/HBoxContainer/VBoxContainer/Button

var is_typing = false
var typing_timer: Timer

func _ready():
	print("GameManager = ", GameManager)
	print("DialogueManager = ", DialogueManager)
	panel.hide()
	GameManager.show_dialogue.connect(_on_show_dialogue)
	GameManager.hide_dialogue.connect(_on_hide_dialogue)
	next_button.pressed.connect(_on_next_pressed)
	

func _on_show_dialogue(speaker: String, text: String):
	panel.show()
	name_label.text = speaker if speaker != "" else "---"
	text_label.text = text
	text_label.visible_characters = 0
	_update_portrait(speaker)
	_start_typing()

func _on_hide_dialogue():
	_stop_typing()
	panel.hide()

func _start_typing():
	if is_typing:
		_stop_typing()
	is_typing = true
	next_button.disabled = true
	typing_timer = Timer.new()
	add_child(typing_timer)
	typing_timer.wait_time = 0.03
	typing_timer.one_shot = false
	typing_timer.timeout.connect(_on_typing_timer)
	typing_timer.start()

func _on_typing_timer():
	if text_label.visible_characters < text_label.text.length():
		text_label.visible_characters += 1
	else:
		_stop_typing()
		next_button.disabled = false

func _stop_typing():
	if typing_timer:
		typing_timer.stop()
		typing_timer.queue_free()
		typing_timer = null
	is_typing = false

func _on_next_pressed():
	if is_typing:
		_stop_typing()
		text_label.visible_characters = -1
		next_button.disabled = false
	else:
		DialogueManager.next_line()

func _update_portrait(speaker: String):
	var portrait_path = "res://assets/portraits/" + speaker.to_lower() + ".png"
	if ResourceLoader.exists(portrait_path):
		var texture = load(portrait_path)
		portrait.texture = texture
	else:
		portrait.texture = null
