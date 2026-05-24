extends CanvasLayer

@onready var label = $Label

func _ready():
	GameManager.show_hint.connect(_on_show_hint)
	label.visible = false

func _on_show_hint(text: String, duration: float):
	label.text = text
	label.visible = true
	await get_tree().create_timer(duration).timeout
	label.visible = false
