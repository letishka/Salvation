extends CharacterBody2D

@onready var health_component = $HealthComponent
@onready var detection_area = $DetectionArea
var player_detected: bool = false
const SPEED = 300.0
var max_speed = 80
const JUMP_VELOCITY = -400.0

func _ready():
	print("ShadowSoldier ready, detection_area = ", detection_area)
	health_component.died.connect(on_died)

func _process(delta):
	if not player_detected: return
	var direction = get_direction_to_player()
	velocity = max_speed * direction
	move_and_slide()

func get_direction_to_player():
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player != null:
		return (player.global_position - self.global_position).normalized()
	return Vector2.ZERO

func on_died():
	queue_free()

func _on_detection_area_body_entered(body: Node2D) -> void:
	print("body_entered: ", body.name)
	if body.is_in_group("player"):
		player_detected = true

func _on_detection_area_body_exited(body: Node2D) -> void:
	print("body_exited: ", body.name)
	if body.is_in_group("player"):
		player_detected = false
