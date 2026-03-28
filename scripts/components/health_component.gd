extends Node
class_name HealthComponent

signal health_changed(current: int, max: int)
signal died

@export var max_health: int = 100
var current_health: int

@export var invincible_duration: float = 1.0
var is_invincible: bool = false

func _ready():
	current_health = max_health

# Нанесение урона
func take_damage(amount: int):
	if is_invincible:
		return
	current_health -= amount
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		died.emit()
	else:
		is_invincible = true
		await get_tree().create_timer(invincible_duration).timeout
		is_invincible = false

# Лечение
func heal(amount: int):
	current_health += amount
	if current_health > max_health:
		current_health = max_health
	health_changed.emit(current_health, max_health)

# Сброс при респауне
func reset():
	current_health = max_health
	is_invincible = false
	health_changed.emit(current_health, max_health)
