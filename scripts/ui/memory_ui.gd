extends CanvasLayer

@onready var black_rect = $BlackRect
@onready var flash_rect = $FlashRect
@onready var content_container = $ContentContainer
@onready var picture_rect = $ContentContainer/PictureRect
@onready var text_label = $ContentContainer/TextLabel
@onready var timer = $Timer

var current_memory_text: String = ""
var current_memory_image: Texture = null
var waiting_for_input: bool = false
var on_close_callback: Callable

func _ready():
	if not black_rect:
		print("MemoryUI ошибка: BlackRect не найден")
		return
	if not flash_rect:
		print("MemoryUI ошибка: FlashRect не найден")
		return
	if not content_container:
		print("MemoryUI ошибка: ContentContainer не найден")
		return
	if not picture_rect:
		print("MemoryUI ошибка: PictureRect не найден")
		return
	if not text_label:
		print("MemoryUI ошибка: TextLabel не найден")
		return
	
	black_rect.visible = false
	black_rect.modulate.a = 0.0
	flash_rect.visible = false
	flash_rect.modulate.a = 0.0
	picture_rect.visible = false
	text_label.visible = false
	content_container.visible = false
	
	process_mode = PROCESS_MODE_ALWAYS

func show_memory(text: String, image: Texture = null, on_closed: Callable = Callable()):
	current_memory_text = text
	current_memory_image = image
	on_close_callback = on_closed

	flash_rect.visible = true
	flash_rect.modulate.a = 1.0
	
	var tween = create_tween()
	tween.tween_property(flash_rect, "modulate:a", 0.0, 0.2)
	await tween.finished
	flash_rect.visible = false

	black_rect.visible = true
	tween = create_tween()
	tween.tween_property(black_rect, "modulate:a", 1.0, 0.1)
	await tween.finished
	
			
	content_container.visible = true
	content_container.modulate.a = 1.0
	
	if current_memory_image:
		picture_rect.texture = current_memory_image
		picture_rect.visible = true
		picture_rect.modulate.a = 1.0
		var pic_tween = create_tween()
		pic_tween.tween_property(picture_rect, "modulate:a", 0.0, 0.3)
		await pic_tween.finished
		picture_rect.visible = false
		picture_rect.modulate.a = 1.0  # сброс для следующего раза

	text_label.text = current_memory_text
	text_label.visible = true
	text_label.visible_ratio = 0.0
	var text_tween = create_tween()
	text_tween.tween_property(text_label, "visible_ratio", 1.0, 1.5)
	
	waiting_for_input = true

func _input(event):
	if not waiting_for_input:
		return
	
	# Нажатие пробела, Enter или ЛКМ
	if event.is_action_pressed("ui_accept") or \
	   (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		waiting_for_input = false
		var tween = create_tween()
		tween.tween_property(black_rect, "modulate:a", 0.0, 0.3)
		tween.parallel().tween_property(content_container, "modulate:a", 0.0, 0.2)
		await tween.finished
		black_rect.visible = false
		content_container.visible = false
		content_container.modulate.a = 1.0

		if on_close_callback != Callable():
			on_close_callback.call()
		
		queue_free()
