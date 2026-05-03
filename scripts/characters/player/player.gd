extends CharacterBody2D

@onready var health_component = $HealthComponent
@onready var grace_period = $GracePeriod
@onready var health_bar = $Ui/HeatlhBar   # предполагаем, что у вас есть такой путь

@onready var attack_controller = $Player/AttackController
@onready var animated_sprite: AnimatedSprite2D = $Player

# Зона взаимодействия – ДОБАВЛЯЕМ
@onready var interact_area = $InteractArea

@export var speed: float = 200.0
@export var sprint_speed: float = 350.0
var current_speed: float
var acceleration = 0.15

var enemies_colliding = 0

# Переменные анимации и атаки
var is_attacking: bool = false
var last_direction: Vector2 = Vector2.DOWN

# Переменные факела – ДОБАВЛЯЕМ
var has_torch: bool = false
var torch_lit: bool = false

# Взаимодействие – ДОБАВЛЯЕМ
var current_interactable = null

func _ready():
	health_component.died.connect(on_died)
	health_component.health_changed.connect(on_health_changed)
	health_update()
	current_speed = speed
	add_to_group("player")
	
	# Подключаем зону взаимодействия – ДОБАВЛЯЕМ
	if interact_area:
		interact_area.area_entered.connect(_on_interactable_area_entered)
		interact_area.area_exited.connect(_on_interactable_area_exited)
	
	# Скрываем спрайт факела (если есть узел TorchSprite)
	if has_node("TorchSprite"):
		$TorchSprite.hide()

func _physics_process(delta):
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

func _input(event):
	# Атака по ЛКМ
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if attack_controller and not is_attacking:
			start_attack()
	# Взаимодействие по E – ДОБАВЛЯЕМ
	elif event.is_action_pressed("interact") and current_interactable:
		if current_interactable.has_method("interact"):
			current_interactable.interact()

# --------- АНИМАЦИИ (как у коллеги) ----------
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
func start_attack():
	is_attacking = true

	var mouse_dir = (get_global_mouse_position() - global_position).normalized()
	var dir_name = get_direction_name(mouse_dir)

	if animated_sprite and animated_sprite.sprite_frames.has_animation("attack_" + dir_name):
		animated_sprite.play("attack_" + dir_name)

	attack_controller.perform_attack(dir_name)

	var duration = 0.4
	if animated_sprite and animated_sprite.sprite_frames.has_animation("attack_" + dir_name):
		var anim_name = "attack_" + dir_name
		var fps = animated_sprite.sprite_frames.get_animation_speed(anim_name)
		var frames = animated_sprite.sprite_frames.get_frame_count(anim_name)
		duration = frames / max(fps, 0.01)

	await get_tree().create_timer(duration).timeout
	is_attacking = false

	var move_input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	update_animation(move_input)

# --------- ВЗАИМОДЕЙСТВИЕ (НОВЫЙ БЛОК) ----------
func _on_interactable_area_entered(area):
	var parent = area.get_parent()
	if parent == self:
		return
	if parent.has_method("interact"):
		current_interactable = parent

func _on_interactable_area_exited(area):
	if current_interactable == area.get_parent():
		current_interactable = null

# --------- ПОЛУЧЕНИЕ УРОНА ----------
func check_if_damaged():
	if enemies_colliding == 0 or not grace_period.is_stopped():
		return
	else:
		health_component.take_damage(10)
	grace_period.start()

func _on_player_hurt_box_area_entered(area: Area2D) -> void:
	enemies_colliding += 1
	check_if_damaged()

func _on_player_hurt_box_area_exited(area: Area2D) -> void:
	enemies_colliding -= 1

func on_died():
	queue_free()

func health_update():
	health_bar.value = health_component.get_health_value()

func on_health_changed():
	health_update()

func _on_grace_period_timeout() -> void:
	check_if_damaged()

# --------- ФАКЕЛЫ (НОВЫЙ БЛОК) ----------
func pickup_torch():
	has_torch = true
	torch_lit = false
	if has_node("TorchSprite"):
		$TorchSprite.show()

func light_torch():
	if has_torch and not torch_lit:
		torch_lit = true
		# Если у вас есть текстура горящего факела, раскомментируйте:
		# if has_node("TorchSprite"):
		#     $TorchSprite.texture = preload("res://assets/graphics/objects/lit_torch.png")

func place_torch():
	if has_torch and torch_lit:
		has_torch = false
		torch_lit = false
		if has_node("TorchSprite"):
			$TorchSprite.hide()
