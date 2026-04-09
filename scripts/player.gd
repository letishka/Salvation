extends CharacterBody2D

@onready var health_component = $HealthComponent
@onready var grace_period = $GracePeriod

var enemies_collasing = 0
@export var speed : float = 200.0
@export var sprint_speed : float = 350.0
var current_speed : float
var acceleration = 0.15

var hp : int = 100
var max_hp : int = 100

var current_interactable = null

func _ready():
	current_speed = speed
	add_to_group("player")

func _physics_process(_delta):
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction = input_dir.normalized()
	
	if Input.is_action_pressed("sprint"):
		current_speed = sprint_speed
	else:
		current_speed = speed
	
	var target_velocity = direction * current_speed
	velocity = velocity.lerp(target_velocity, acceleration)
	move_and_slide()

#func take_damage(amount: int):
	#hp -= amount
	#if hp <= 0:
		#die()
	# Обновление полоски здоровья позже

func heal(amount: int):
	hp += amount
	hp = min(hp, max_hp)

func die():
	get_tree().reload_current_scene()

func _on_interactable_area_entered(area):
	current_interactable = area.get_parent()

func _on_interactable_area_exited(area):
	if current_interactable == area.get_parent():
		current_interactable = null

func _input(event):
	if event.is_action_pressed("interact") and current_interactable:
		if current_interactable.has_method("interact"):
			current_interactable.interact()

func check_if_damaged():
	if enemies_collasing == 0 || !grace_period.is_stopped():
		return
	health_component.take_damage(1)
	grace_period.start()
	print(health_component.current_helth)
