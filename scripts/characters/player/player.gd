extends CharacterBody2D

@onready var health_component = $HealthComponent
@onready var grace_period = $GracePeriod
@onready var health_bar = $Ui/HeatlhBar
@onready var attack_controller = $Player/AttackController
@onready var animated_sprite: AnimatedSprite2D = $Player
@onready var torch_light = $TorchLight    # PointLight2D (свет от факела)

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
var last_direction: Vector2 = Vector2.DOWN

# Инвентарь (факел)
var has_torch: bool = false
var torch_lit: bool = false

func _ready():
	if health_component.current_health <= 0:
		health_component.current_health = GameManager.initial_player_health
	health_component.died.connect(on_died)
	health_component.health_changed.connect(on_health_changed)
	health_update()
	current_speed = speed
	add_to_group("player")
	
	# Свет от факела изначально выключен
	if torch_light:
		torch_light.enabled = false

func _physics_process(delta):
	if get_tree().paused:
		velocity = Vector2.ZERO
		return
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
	if get_tree().paused:
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if attack_controller and not is_attacking:
			start_attack()
	if event.is_action_pressed("interact") and current_interactable:
		if current_interactable.has_method("interact"):
			current_interactable.interact()
		else:
			print("Ошибка: у ", current_interactable.name, " нет метода interact")

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

# --------- ВЗАИМОДЕЙСТВИЕ ----------
func _on_interactable_area_entered(area: Area2D):
	print("=== Вход в зону: ", area.name, ", родитель: ", area.get_parent().name, " ===")
	if area.has_method("interact"):
		current_interactable = area
		print("current_interactable установлен на area")
	else:
		var parent = area.get_parent()
		if parent and parent.has_method("interact"):
			current_interactable = parent
			print("current_interactable установлен на родителя: ", parent.name)

func _on_interactable_area_exited(area: Area2D):
	if current_interactable == area or current_interactable == area.get_parent():
		current_interactable = null

# --------- ЗДОРОВЬЕ И УРОН ----------
func check_if_damaged(damage: float = 10):
	if enemies_colliding == 0 or not grace_period.is_stopped(): 
		return
	health_component.take_damage(damage)
	grace_period.start()

func _on_player_hurt_box_area_entered(area: Area2D):
	enemies_colliding += 1
	if area.has_method("get_damage") or "damage" in area:
		check_if_damaged(area.damage)
	else:
		check_if_damaged(10)

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

func reset_health():
	health_component.current_health = health_component.max_health
	health_component.health_changed.emit()

# --------- ФАКЕЛ (ИНВЕНТАРЬ + СВЕТ) ----------
func pickup_torch():
	has_torch = true
	torch_lit = false
	if torch_light:
		torch_light.enabled = false
	GameManager.update_inventory(has_torch, torch_lit)
	GameManager.show_hint.emit("Факел подобран. Подойди к костру, чтобы зажечь.", 3.0)

func light_torch():
	if has_torch and not torch_lit:
		torch_lit = true
		if torch_light:
			torch_light.enabled = true
		GameManager.update_inventory(has_torch, torch_lit)
		GameManager.show_hint.emit("Факел зажжён! Неси к пустой подставке.", 2.0)

func place_torch() -> bool:
	if has_torch and torch_lit:
		has_torch = false
		torch_lit = false
		if torch_light:
			torch_light.enabled = false
		GameManager.update_inventory(has_torch, torch_lit)
		return true
	return false
