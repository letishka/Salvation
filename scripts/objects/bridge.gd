extends Node2D
class_name Bridge

@onready var bridge_tilemap = $Bridge
@onready var road = $BridgeWalkZone/Road
@onready var water = $Water
@onready var bridge_walk_zone = $BridgeWalkZone
@onready var bridge_sound = $BridgeSound

@export var raise_height: float = 64.0
@export var raise_duration: float = 0.8
@export var start_y: float = 0.0

var is_raised = false

func _ready():
	start_y = bridge_tilemap.position.y
	bridge_tilemap.position.y = start_y
	road.position.y = start_y
	if road:
		road.set_physics_process(false)
		if road.has_node("CollisionShape2D"):
			road.get_node("CollisionShape2D").disabled = true
	if bridge_walk_zone:
		if bridge_walk_zone.is_in_group("walk_zone"):
			bridge_walk_zone.remove_from_group("walk_zone")

func activate(state: bool):
	if state and not is_raised:
		is_raised = true
		_raise_bridge()
	elif not state and is_raised:
		is_raised = false
		_lower_bridge()

func _raise_bridge():
	if bridge_sound:
		bridge_sound.play()
	var target_y = start_y - raise_height
	
	var tween = create_tween()
	tween.tween_property(bridge_tilemap, "position:y", target_y, raise_duration)
	tween.parallel().tween_property(road, "position:y", target_y, raise_duration)
	
	if has_node("AudioStreamPlayer2D"):
		$AudioStreamPlayer2D.play()
	
	await tween.finished
	if road:
		road.set_physics_process(true)
		if road.has_node("CollisionShape2D"):
			road.get_node("CollisionShape2D").disabled = false
	
	if bridge_walk_zone:
		bridge_walk_zone.add_to_group("walk_zone")
		print("Мост поднят — зона ходьбы активирована!")

func _lower_bridge():
	var tween = create_tween()
	tween.tween_property(bridge_tilemap, "position:y", start_y, raise_duration)
	tween.parallel().tween_property(road, "position:y", start_y, raise_duration)
	
	await tween.finished
	if road:
		road.set_physics_process(false)
		if road.has_node("CollisionShape2D"):
			road.get_node("CollisionShape2D").disabled = true
	
	if bridge_walk_zone:
		if bridge_walk_zone.is_in_group("walk_zone"):
			bridge_walk_zone.remove_from_group("walk_zone")
			print("Мост опущен — зона ходьбы деактивирована!")
