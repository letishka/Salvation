extends CharacterBody2D

signal health_changed(current_hp, max_hp) # сделать полоску для здоровья
# signal ability_used(ability_name) # добавить иконку использования способности
# signal dodge_performed # эти сигналы нужно подключить из интерфейса

@export var speed : float = 200.0
@export var sprint_speed : float = 350.0
var current_speed : float

var hp : int = 100
var max_hp : int = 100

var invincible := false
var invincible_duration := 1.0

var current_interactable = null

func _ready():
	current_speed = speed
	add_to_group("player")

	if has_node("InteractArea"):
		$InteractArea.area_entered.connect(_on_interactable_area_entered)
		$InteractArea.area_exited.connect(_on_interactable_area_exited)

# var footstep_timer := 0.0 для звука шагов
func _physics_process(_delta):
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction = input_dir.normalized()
	
	if Input.is_action_pressed("sprint"):
		current_speed = sprint_speed
	else:
		current_speed = speed
	
	velocity = direction * current_speed
	
	# if velocity.length() > 10: добавим когда будет анимация и звуки
		# footstep_timer -= delta
		# if footstep_timer <= 0:
			# footstep_timer = 0.3  # интервал шагов
			# $FootstepPlayer.play()

	move_and_slide()

func take_damage(amount: int):
	if invincible:
		return
	hp -= amount
	health_changed.emit(hp, max_hp)
	if hp <= 0:	# смерть если хп меньше 0
		die()
	else: 
		invincible = true	# включаем неуязвимость при получении урона
		# play_animation("hurt") позже 
		# звук урона
		await get_tree().create_timer(invincible_duration).timeout
		invincible = false
		
func heal(amount: int):
	hp += amount
	hp = min(hp, max_hp)

func die():
	set_physics_process(false)
	set_process_input(false)

	await get_tree().create_timer(1.0).timeout
	get_tree().reload_current_scene()

func _on_interactable_area_entered(area):
	current_interactable = area.get_parent()

func _on_interactable_area_exited(area):
	if current_interactable == area.get_parent():
		current_interactable = null

func _input(event):
	if event.is_action_pressed("interact") and current_interactable and hp > 0:
		if current_interactable.has_method("interact"):
			current_interactable.interact()
