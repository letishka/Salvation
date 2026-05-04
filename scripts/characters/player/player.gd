extends CharacterBody2D

@onready var health_component = $HealthComponent
@onready var grace_period = $GracePeriod
@onready var health_bar = $Ui/HeatlhBar

@onready var attack_controller = $Player/AttackController
@onready var animated_sprite: AnimatedSprite2D = $Player

@export var speed: float = 200.0
@export var sprint_speed: float = 350.0
var current_speed: float
var acceleration = 0.15

var enemies_colliding = 0

var hp: int = 100
var max_hp: int = 100

var current_interactable = null

# Переменные анимации и атаки
var is_attacking: bool = false
var last_direction: Vector2 = Vector2.DOWN   # взгляд по умолчанию вниз

func _ready():
	health_component.died.connect(on_died)
	health_component.health_changed.connect(on_health_changed)
	health_update()
	current_speed = speed
	add_to_group("player")

func _physics_process(delta):
	# Во время атаки не двигаемся
	if is_attacking:
		return

	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction = input_dir.normalized()
	if direction != Vector2.ZERO:
		last_direction = direction

	var target_velocity = direction * current_speed
	velocity = velocity.lerp(target_velocity, acceleration)
	move_and_slide()
	update_animation(direction)

# --------- АНИМАЦИИ ----------
func update_animation(move_input: Vector2):
	if not animated_sprite:
		return
	var dir_name = get_direction_name(move_input if move_input != Vector2.ZERO else last_direction)
	if move_input != Vector2.ZERO:
		animated_sprite.play("run_" + dir_name)
	else:
		animated_sprite.play("idle_" + dir_name)

func get_direction_name(dir: Vector2) -> String:
	if abs(dir.x) > abs(dir.y):
		return "right" if dir.x > 0 else "left"
	else:
		return "down" if dir.y > 0 else "up"

# --------- АТАКА ----------
func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if attack_controller and not is_attacking:
			start_attack()

func start_attack():
	is_attacking = true

	# Направление на курсор
	var mouse_dir = (get_global_mouse_position() - global_position).normalized()
	var dir_name = get_direction_name(mouse_dir)

	# Проигрываем анимацию атаки на теле
	if animated_sprite and animated_sprite.sprite_frames.has_animation("attack_" + dir_name):
		animated_sprite.play("attack_" + dir_name)

	# Запускаем ударную зону
	attack_controller.perform_attack(dir_name)

	# Вычисляем длительность анимации атаки
	var duration = 0.4   # fallback
	if animated_sprite and animated_sprite.sprite_frames.has_animation("attack_" + dir_name):
		var anim_name = "attack_" + dir_name
		var fps = animated_sprite.sprite_frames.get_animation_speed(anim_name)
		var frames = animated_sprite.sprite_frames.get_frame_count(anim_name)
		duration = frames / max(fps, 0.01)

	await get_tree().create_timer(duration).timeout
	is_attacking = false

	# Возвращаемся к idle или run
	var move_input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	update_animation(move_input)

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
	health_bar.value = health_component.get_health_value()

func on_health_changed():
	health_update()

func _on_grace_period_timeout() -> void:
	check_if_damaged()
