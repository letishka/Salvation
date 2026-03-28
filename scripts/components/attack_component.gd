extends Area2D
class_name AttackComponent

@export var damage: int = 10
@export var active_time: float = 0.3

var _is_active: bool = false

func _ready():
	monitoring = false
	body_entered.connect(_on_body_entered)

# Активация зоны атаки
func activate():
	if _is_active:
		return
	_is_active = true
	monitoring = true
	await get_tree().create_timer(active_time).timeout
	monitoring = false
	_is_active = false

# При попадании наносим урон
func _on_body_entered(body: Node):
	if body.has_method("take_damage"):
		body.take_damage(damage)
