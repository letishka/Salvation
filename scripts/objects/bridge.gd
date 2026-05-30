extends Node2D
class_name Bridge

@onready var bridge_tilemap = $Bridge
@onready var road = $Road
@onready var water = $Water

# Настройки подъёма
@export var raise_height: float = 64.0      # на сколько поднять мост
@export var raise_duration: float = 0.8     # длительность анимации
@export var start_y: float = 0.0            # начальная позиция по Y

var is_raised = false

func _ready():
	start_y = bridge_tilemap.position.y
	# Изначально мост внизу (под водой)
	bridge_tilemap.position.y = start_y
	road.position.y = start_y
	
	# Дорога изначально не активна (коллизия выключена)
	if road:
		road.set_physics_process(false)
		if road.has_node("CollisionShape2D"):
			road.get_node("CollisionShape2D").disabled = true

func activate(state: bool):
	# state = true - поднимаем мост
	# state = false - опускаем мост (если нужно)
	
	if state and not is_raised:
		is_raised = true
		_raise_bridge()
	elif not state and is_raised:
		is_raised = false
		_lower_bridge()

func _raise_bridge():
	# Поднимаем мост и дорогу
	var target_y = start_y - raise_height
	
	var tween = create_tween()
	tween.tween_property(bridge_tilemap, "position:y", target_y, raise_duration)
	tween.parallel().tween_property(road, "position:y", target_y, raise_duration)
	
	# Звук
	if has_node("AudioStreamPlayer2D"):
		$AudioStreamPlayer2D.play()
	
	# Включаем коллизию дороги после подъёма
	await tween.finished
	if road:
		road.set_physics_process(true)
		if road.has_node("CollisionShape2D"):
			road.get_node("CollisionShape2D").disabled = false

func _lower_bridge():
	# Опускаем мост обратно (если нужно)
	var tween = create_tween()
	tween.tween_property(bridge_tilemap, "position:y", start_y, raise_duration)
	tween.parallel().tween_property(road, "position:y", start_y, raise_duration)
	
	await tween.finished
	if road:
		road.set_physics_process(false)
		if road.has_node("CollisionShape2D"):
			road.get_node("CollisionShape2D").disabled = true
