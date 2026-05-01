extends Node
class_name HealthComponent

signal health_changed(current: float, max: float)
signal died

@export var max_health: float = 100.0
var current_health: float

@export var invincible_duration: float = 1.0
var is_invincible: bool = false

var is_dead: bool = false

func _ready():
	current_health = max_health

func take_damage(amount: float):
	if is_dead or is_invincible:
		return
	current_health -= amount
	if current_health < 0:
		current_health = 0
	health_changed.emit(current_health, max_health)
	if current_health <= 0 and not is_dead:
		is_dead = true
		died.emit()
	else:
		is_invincible = true
		await get_tree().create_timer(invincible_duration).timeout
		is_invincible = false

func heal(amount: float):
	current_health += amount
	if current_health > max_health:
		current_health = max_health
	health_changed.emit(current_health, max_health)

func reset():
	current_health = max_health
	is_invincible = false
	health_changed.emit(current_health, max_health)
