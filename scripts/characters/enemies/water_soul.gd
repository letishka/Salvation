extends CharacterBody2D

enum State { IDLE, WALK, ATTACK, HIT, DEATH }

@export var max_health: float = 0.0
@export var max_speed: float = 80.0
@export var attack_cooldown: float = 1

@export var vertical_threshold: float = 40.0

@export var projectile_scene: PackedScene
@export var arrow_damage: float = 13.0
@export var arrow_speed: float = 500.0
@export var hit_delay: float = 0.1
@export var arrow_spawn_offset: Vector2 = Vector2(70, -20)

@export var retreat_radius: float = 200.0
var _facing_sign: int = 1

@export var attack_sound: AudioStream
@export var footstep_sounds: Dictionary[String, AudioStream] = {}
@export var footstep_interval: float = 0.4

@onready var health_component: HealthComponent = $HealthComponent
@onready var detection_area: Area2D = $DetectionArea
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_cooldown_timer: Timer = $AttackCooldown
@onready var arrow_spawn: Marker2D = $ArrowSpawn if has_node("ArrowSpawn") else null

@onready var footstep_player: AudioStreamPlayer2D = $FootstepPlayer
@onready var attack_sound_player: AudioStreamPlayer2D = $AttackSoundPlayer
@onready var ground_check_ray: RayCast2D = $GroundCheckRay

var player_detected: bool = false
var current_state: State = State.IDLE
var can_attack: bool = true
var player_in_attack_zone: bool = false

var _footstep_timer: float = 0.0
var _vertical_orientation: String = "down"
@export var arrow_flight_animation: String = "flight"

func _ready():
	health_component.died.connect(_on_died)
	health_component.health_changed.connect(_on_health_changed)
	_update_health_bar()

	attack_cooldown_timer.wait_time = attack_cooldown
	attack_cooldown_timer.one_shot = true

	if not footstep_player:
		footstep_player = AudioStreamPlayer2D.new()
		add_child(footstep_player)
	if not attack_sound_player:
		attack_sound_player = AudioStreamPlayer2D.new()
		add_child(attack_sound_player)
	if not ground_check_ray:
		ground_check_ray = RayCast2D.new()
		ground_check_ray.target_position = Vector2(0, 10)
		ground_check_ray.enabled = true
		add_child(ground_check_ray)

func _physics_process(delta):
	if current_state == State.WALK:
		_footstep_timer += delta
		if _footstep_timer >= footstep_interval:
			_footstep_timer = 0.0
			_play_footstep_sound()
	else:
		_footstep_timer = 0.0

	match current_state:
		State.IDLE, State.WALK:
			_handle_movement()
		State.ATTACK, State.HIT, State.DEATH:
			velocity = Vector2.ZERO
			move_and_slide()

func _apply_flip(is_left: bool):
	animated_sprite.flip_h = is_left
	_facing_sign = -1 if is_left else 1

func _handle_movement():
	if not player_detected:
		_set_state(State.IDLE)
		return
	var player = _get_player()
	if not player:
		return

	var to_player = player.global_position - global_position
	var distance = to_player.length()

	if distance < retreat_radius:
		var away_dir = -to_player.normalized()
		velocity = away_dir * max_speed
		_apply_flip(away_dir.x < 0)
		_set_state(State.WALK)

	elif player_in_attack_zone and can_attack:
		_start_attack()

	else:
		var direction = to_player.normalized()
		velocity = direction * max_speed
		_apply_flip(to_player.x < 0)
		_set_state(State.WALK)

	if velocity != Vector2.ZERO:
		_vertical_orientation = "up" if velocity.y < -vertical_threshold else "down"

	move_and_slide()

func _on_health_changed():
	_update_health_bar()
	if current_state == State.DEATH: return

	_apply_flip(_facing_sign < 0)

	_set_state(State.HIT)
	animated_sprite.play("hit")
	await get_tree().create_timer(0.4).timeout
	if current_state == State.DEATH: return
	_set_state(State.WALK if player_detected else State.IDLE)

func _start_attack():
	_set_state(State.ATTACK)
	can_attack = false

	var player = _get_player()
	if not player:
		# Если игрока нет – стреляем вправо без смещения (или с вашим смещением)
		_apply_flip(false)
		_shoot_arrow(Vector2.RIGHT, Vector2.ZERO)
		attack_cooldown_timer.start()
		await attack_cooldown_timer.timeout
		can_attack = true
		_set_state(State.WALK if player_detected else State.IDLE)
		return

	var to_player = player.global_position - global_position
	_apply_flip(to_player.x < 0)

	# Всегда одна анимация и одна задержка
	animated_sprite.play("attack")
	if attack_sound and attack_sound_player:
		attack_sound_player.stream = attack_sound
		attack_sound_player.play()

	await get_tree().create_timer(hit_delay).timeout

	# Применяем смещение с учётом поворота
	var spawn_offset = arrow_spawn_offset
	if animated_sprite.flip_h:
		spawn_offset.x *= -1

	var base_pos = arrow_spawn.global_position if arrow_spawn else global_position
	var arrow_dir = (player.global_position - base_pos).normalized()
	_shoot_arrow(arrow_dir, spawn_offset)

	attack_cooldown_timer.start()
	await attack_cooldown_timer.timeout
	can_attack = true

	_set_state(State.WALK if player_detected else State.IDLE)

func _shoot_arrow(direction: Vector2, spawn_offset: Vector2):
	if not projectile_scene:
		return
	var arrow = projectile_scene.instantiate()
	get_parent().add_child(arrow)

	var base_pos = arrow_spawn.global_position if arrow_spawn else global_position
	arrow.global_position = base_pos + spawn_offset

	# Инициализация через метод, если есть
	if arrow.has_method("init"):
		arrow.init(direction, arrow_speed, arrow_damage)
	else:
		arrow.set_meta("direction", direction)
		arrow.set_meta("speed", arrow_speed)
		arrow.set_meta("damage", arrow_damage)

	# Запускаем анимацию полёта, если у стрелы есть AnimatedSprite2D
	if arrow.has_node("AnimatedSprite2D"):
		var arrow_sprite: AnimatedSprite2D = arrow.get_node("AnimatedSprite2D")
		if arrow_sprite.sprite_frames and arrow_sprite.sprite_frames.has_animation(arrow_flight_animation):
			arrow_sprite.play(arrow_flight_animation)

func _on_died():
	_set_state(State.DEATH)
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	progress_bar.visible = false
	animated_sprite.play("death")
	$HurtBoxComponent.monitoring = false
	var death_length = animated_sprite.sprite_frames.get_frame_count("death") / animated_sprite.sprite_frames.get_animation_speed("death")
	await get_tree().create_timer(death_length).timeout
	queue_free()

func _get_player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D

func _set_state(new_state: State):
	if current_state == State.DEATH: return
	current_state = new_state
	match new_state:
		State.IDLE:
			animated_sprite.play("idle_up" if _vertical_orientation == "up" else "idle_down")
		State.WALK:
			animated_sprite.play("walk_up" if _vertical_orientation == "up" else "walk")

func _update_health_bar():
	progress_bar.value = health_component.get_health_value()

func _play_footstep_sound():
	if footstep_sounds.is_empty() or not footstep_player: return
	var surface_group = "default"
	if ground_check_ray and ground_check_ray.is_colliding():
		var collider = ground_check_ray.get_collider()
		for group in footstep_sounds.keys():
			if collider.is_in_group(group):
				surface_group = group
				break
	var sound = footstep_sounds.get(surface_group, null)
	if not sound: sound = footstep_sounds.get("default", null)
	if sound is AudioStream:
		footstep_player.stream = sound
		footstep_player.play()

func _on_detection_area_body_entered(body: Node2D):
	if body.is_in_group("player"): player_detected = true

func _on_detection_area_body_exited(body: Node2D):
	if body.is_in_group("player"):
		player_detected = false
		if current_state not in [State.DEATH, State.ATTACK, State.HIT]:
			_set_state(State.IDLE)

func _on_attack_trigger_body_entered(body: Node2D):
	if body.is_in_group("player"): player_in_attack_zone = true

func _on_attack_trigger_body_exited(body: Node2D):
	if body.is_in_group("player"): player_in_attack_zone = false
