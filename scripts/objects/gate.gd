extends StaticBody2D
class_name Gate

signal opened

@export var required_torches: int = 3   # сколько факелов нужно для открытия
var lit_torches: int = 0               # текущее количество зажжённых факелов

func register_lit_torch():
	lit_torches += 1
	if lit_torches >= required_torches:
		open()

func open():
	# Анимация открытия ворот (если есть)
	if has_node("AnimationPlayer"):
		$AnimationPlayer.play("open")
	
	# Отключаем коллизию, чтобы игрок мог пройти
	$CollisionShape2D.disabled = true
	
	# (Опционально) скрываем визуальную часть ворот
	if has_node("Sprite2D"):
		$Sprite2D.visible = false
	elif has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("open")
	
	opened.emit()
