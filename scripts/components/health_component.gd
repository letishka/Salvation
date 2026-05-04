extends Node
class_name HealthComponent

signal died
signal health_changed

@export var max_health: float
var current_health: float

func _ready():
	current_health = max_health
	
func take_damage (damage):
	current_health = max(current_health - damage, 0)
	if damage>0: print(get_parent().name, " health: ", current_health)
	health_changed.emit()
	Callable(check_death).call_deferred()

func get_health_value():
	return current_health/max_health

func check_death ():
	if current_health == 0:
		died.emit()
