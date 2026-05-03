extends CharacterBody2D

@onready var health_component = $HealthComponent
@onready var detection_area = $DetectionArea
@onready var progress_bar: ProgressBar = $ProgressBar
var player_detected: bool = false
var max_speed = 80

func _ready():
	health_component.died.connect(on_died)
	health_component.health_changed.connect(on_health_changed)
	health_update()

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

func health_update():
	progress_bar.value = health_component.get_health_value()

func on_health_changed():
	health_update()

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_detected = true

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_detected = false
