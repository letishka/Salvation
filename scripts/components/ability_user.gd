extends Node
class_name AbilityUser

signal ability_used(ability_id: String)
signal cooldown_started(ability_id: String, remaining: float)

@export var abilities: Array[AbilityResource] = []
var _cooldowns: Dictionary = {}  # ability_id -> remaining time

func _ready():
	for a in abilities:
		_cooldowns[a.id] = 0.0

# Проверка, доступна ли способность
func can_use(ability_id: String) -> bool:
	return _cooldowns.get(ability_id, 0.0) <= 0.0

# Использовать способность
func use(ability_id: String):
	var ability = _get_ability(ability_id)
	if not ability or not can_use(ability_id):
		return
	_cooldowns[ability_id] = ability.cooldown
	ability_used.emit(ability_id)

func _get_ability(id: String) -> AbilityResource:
	for a in abilities:
		if a.id == id:
			return a
	return null

func update(delta: float):
	for id in _cooldowns.keys():
		if _cooldowns[id] > 0:
			_cooldowns[id] -= delta
			if _cooldowns[id] <= 0:
				cooldown_started.emit(id, 0.0)
