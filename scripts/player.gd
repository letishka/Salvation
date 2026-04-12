extends CharacterBody2D

@onready var health_component = $HealthComponent
@onready var grace_period = $GracePeriod
@onready var progress_bar = $ProgressBar


@export var speed : float = 200.0
@export var sprint_speed : float = 350.0
var current_speed : float
var acceleration = 0.15

var enemies_colliding = 0

var hp : int = 100
var max_hp : int = 100

var current_interactable = null

func _ready():
	health_component.died.connect(on_died)
	health_component.health_changed.connect(on_health_changed)
	health_update()
	
	current_speed = speed
	add_to_group("player")

func _physics_process(_delta):
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction = input_dir.normalized()
	
	var target_velocity = direction * current_speed
	velocity = velocity.lerp(target_velocity, acceleration)
	move_and_slide()

func _on_interactable_area_entered(area):
	current_interactable = area.get_parent()

func _on_interactable_area_exited(area):
	if current_interactable == area.get_parent():
		current_interactable = null

func check_if_damaged():
	if enemies_colliding == 0 || !grace_period.is_stopped(): return
	else: health_component.take_damage(10)
	grace_period.start()

func _on_player_hurt_box_area_entered(area: Area2D) -> void:
	enemies_colliding +=1
	check_if_damaged()

func _on_player_hurt_box_area_exited(area: Area2D) -> void:
	enemies_colliding -=1

func on_died():
	queue_free()

func health_update():
	progress_bar.value = health_component.get_health_value()

func on_health_changed():
	health_update()

func _on_grace_period_timeout() -> void:
	check_if_damaged()
