extends CharacterBody2D

@onready var health_component = $HealthComponent
@onready var grace_period = $GracePeriod
@onready var health_bar = $Ui/HeatlhBar
@onready var attack_controller = $Player/AttackController
@onready var animated_sprite: AnimatedSprite2D = $Player
@onready var torch_light = $TorchLight
@onready var torch_pickup_sound = $TorchPickupSound
@onready var torch_ignite_sound = $TorchIgniteSound
@onready var torch_ambient_sound = $TorchAmbientSound
@onready var torch_ambient_sound2 = $TorchAmbientSound2
@onready var footstep_player = $FootstepPlayer

@export var speed: float = 200.0
@export var sprint_speed: float = 350.0
var current_speed: float
var acceleration = 0.15

var enemies_colliding = 0

var hp: int = 100
var max_hp: int = 100

var current_interactable = null

var is_attacking: bool = false
var last_direction: Vector2 = Vector2.DOWN

var has_torch: bool = false
var torch_lit: bool = false

var is_on_walk_zone: bool = true
var footstep_timer: float = 0.0
var footstep_interval: float = 0.4

func _ready():
	if health_component.current_health <= 0:
		health_component.current_health = GameManager.initial_player_health
	health_component.died.connect(on_died)
	health_component.health_changed.connect(on_health_changed)
	health_update()
	current_speed = speed
	add_to_group("player")
	
	if torch_light:
		torch_light.enabled = false

func _physics_process(delta):
	if get_tree().paused:
		velocity = Vector2.ZERO
		return
	if is_attacking:
		return

	is_on_walk_zone = _is_on_walk_zone()
	
	if not is_on_walk_zone:
		var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		var direction = input_dir.normalized()

		if not _is_moving_towards_zone(direction):
			velocity = Vector2.ZERO
			move_and_slide()
			footstep_timer = 0.0
			return

	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction = input_dir.normalized()
	if direction != Vector2.ZERO:
		last_direction = direction

	var target_velocity = direction * current_speed
	velocity = velocity.lerp(target_velocity, acceleration)
	move_and_slide()
	update_animation(direction)
	
	is_on_walk_zone = _is_on_walk_zone()
	
	var is_moving = velocity.length() > 30
	if is_moving and not is_attacking and is_on_walk_zone:
		footstep_timer += delta
		if footstep_timer >= footstep_interval:
			footstep_timer = 0.0
			_play_footstep_sound()
	else:
		footstep_timer = 0.0

# --------- ЗОНА ХОДЬБЫ ----------
func _is_on_walk_zone() -> bool:
	var bodies = $InteractArea.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("walk_zone"):
			return true
	
	var areas = $InteractArea.get_overlapping_areas()
	for area in areas:
		if area.is_in_group("walk_zone"):
			return true
	
	return false

func _is_moving_towards_zone(direction: Vector2) -> bool:
	var player_pos = global_position
	var walk_zones = get_tree().get_nodes_in_group("walk_zone")
	
	for zone in walk_zones:
		var zone_rect = _get_zone_bounds(zone)
		if zone_rect == Rect2():
			continue
		
		var closest_x = clamp(player_pos.x, zone_rect.position.x, zone_rect.end.x)
		var closest_y = clamp(player_pos.y, zone_rect.position.y, zone_rect.end.y)
		var closest_point = Vector2(closest_x, closest_y)
		
		var to_zone = closest_point - player_pos
		if to_zone.length() < 150 and to_zone.normalized().dot(direction) > 0:
			return true
	
	return false

func _get_zone_bounds(zone: Node) -> Rect2:
	for child in zone.get_children():
		if child is CollisionShape2D and child.shape is RectangleShape2D:
			var shape = child.shape
			var pos = child.global_position
			var half_size = shape.size / 2
			return Rect2(pos - half_size, shape.size)
	
	if zone is StaticBody2D:
		for child in zone.get_children():
			if child is CollisionShape2D and child.shape is RectangleShape2D:
				var shape = child.shape
				var pos = child.global_position
				var half_size = shape.size / 2
				return Rect2(pos - half_size, shape.size)
	
	for child in zone.get_children():
		if child is CollisionShape2D and child.shape is RectangleShape2D:
			var shape = child.shape
			var pos = child.global_position
			var half_size = shape.size / 2
			return Rect2(pos - half_size, shape.size)
	
	return Rect2()

func _play_footstep_sound():
	if footstep_player and footstep_player.stream:
		footstep_player.play()

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
	if has_torch:
		GameManager.show_hint.emit("У тебя уже есть факел!", 2.0)
		return
	
	has_torch = true
	torch_lit = false
	if torch_light:
		torch_light.enabled = false
	
	if torch_pickup_sound:
		torch_pickup_sound.play()
	
	GameManager.update_inventory(has_torch, torch_lit)
	GameManager.show_hint.emit("Факел подобран. Подойди к костру, чтобы зажечь.", 3.0)

func light_torch():
	if not has_torch:
		GameManager.show_hint.emit("У тебя нет факела!", 2.0)
		return
	if torch_lit:
		GameManager.show_hint.emit("Факел уже зажжён!", 2.0)
		return
	
	torch_lit = true
	if torch_light:
		torch_light.enabled = true
	
	if torch_ignite_sound:
		torch_ignite_sound.play()
	
	if torch_ambient_sound:
		torch_ambient_sound.play()
	
	GameManager.update_inventory(has_torch, torch_lit)
	GameManager.show_hint.emit("Факел зажжён! Неси к пустой подставке.", 2.0)

func place_torch() -> bool:
	if not has_torch:
		GameManager.show_hint.emit("У тебя нет факела!", 2.0)
		return false
	if not torch_lit:
		GameManager.show_hint.emit("Факел не зажжён! Подойди к костру.", 2.0)
		return false
	
	if torch_ambient_sound:
		torch_ambient_sound.stop()
	
	has_torch = false
	torch_lit = false
	if torch_light:
		torch_light.enabled = false
	
	GameManager.update_inventory(has_torch, torch_lit)
	GameManager.show_hint.emit("Факел установлен в подставку!", 2.0)
	return true
