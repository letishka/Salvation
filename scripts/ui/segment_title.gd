extends CanvasLayer

@onready var label = $Label

func show_title(text: String, duration: float = 2.0):
	label.text = text
	label.visible = true
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.2)
	await get_tree().create_timer(duration).timeout
	tween = create_tween()
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	await tween.finished
	label.visible = false
	label.modulate.a = 1.0
