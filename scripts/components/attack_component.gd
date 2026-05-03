extends Area2D
class_name AttackComponent

@export var damage: float = 10.0
@export var active_time: float = 0.3
var _is_active: bool = false

func _ready():
	monitoring = false
	body_entered.connect(_on_body_entered)

func activate():
	print(name, ".activate вызван, _is_active = ", _is_active)
	if _is_active:
		return
	_is_active = true
	monitoring = true
	print(name, ": monitoring включён, текущее состояние = ", monitoring)
	await get_tree().create_timer(active_time).timeout
	monitoring = false
	_is_active = false
	print(name, ": monitoring выключен")

func _on_body_entered(body: Node):
	print("AttackComponent обнаружил: ", body.name, " (класс: ", body.get_class(), ")")
	if body.has_method("take_damage"):
		body.take_damage(damage)
		print("Урон нанесён ", damage)
