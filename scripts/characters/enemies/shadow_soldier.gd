extends CharacterBody2D

enum State { IDLE, WALK, ATTACK, HIT, DEATH }

@export var max_health: float = 30.0
@export var max_speed: float = 80.0
@export var attack_damage: float = 13.0
@export var attack_duration: float = 0.1     # длительность активной зоны
@export var attack_cooldown: float = 0.6
@export var flip_offset_x: float = -32.0
@export var collision_offset_x: float = -32.0
@export var hit_delay: float = 0.3           # задержка до удара внутри анимации

# ==== ЗВУКИ ====
@export var attack_swoosh_sound: AudioStream                # звук взмаха меча
@export var footstep_sounds: Dictionary[String, AudioStream] = {}   # ключ: группа поверхности, значение: AudioStream
@export var footstep_interval: float = 0.4                  # интервал между звуками шагов
# ===============

@onready var health_component: HealthComponent = $HealthComponent
@onready var detection_area: Area2D = $DetectionArea
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: HitBoxComponent = $EnemyHitBox
@onready var attack_collision: CollisionShape2D = $EnemyHitBox/CollisionShape2D
@onready var attack_cooldown_timer: Timer = $AttackCooldown

# Звуковые узлы
@onready var footstep_player: AudioStreamPlayer2D = $FootstepPlayer
@onready var attack_sound_player: AudioStreamPlayer2D = $AttackSoundPlayer
@onready var ground_check_ray: RayCast2D = $GroundCheckRay  # луч вниз для определения поверхности

var player_detected: bool = false
var current_state: State = State.IDLE
var can_attack: bool = true
var player_in_attack_zone: bool = false

var _attack_collision_base_pos: Vector2
var _footstep_timer: float = 0.0   # таймер для отсчёта интервала шагов

func _ready():
	health_component.died.connect(_on_died)
	health_component.health_changed.connect(_on_health_changed)
	
	_update_health_bar()

	# Зона всегда включена, но безобидна (слой 0)
	attack_area.monitoring = true
	attack_area.collision_layer = 0
	attack_area.damage = 0

	attack_cooldown_timer.wait_time = attack_cooldown
	attack_cooldown_timer.one_shot = true

	if attack_collision:
		_attack_collision_base_pos = attack_collision.position

	# Если аудио-узлы не назначены в сцене, создаём их программно
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

func _apply_flip(is_left: bool):
	animated_sprite.flip_h = is_left
	animated_sprite.offset.x = flip_offset_x if is_left else -flip_offset_x
	if attack_collision:
		if is_left:
			attack_collision.position.x = _attack_collision_base_pos.x + collision_offset_x
		else:
			attack_collision.position.x = _attack_collision_base_pos.x

func _physics_process(delta):
	# Обновление таймера шагов и воспроизведение при WALK
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

func _handle_movement():
	if not player_detected:
		_set_state(State.IDLE)
		return
	var player = _get_player()
	if not player:
		return
	var distance = global_position.distance_to(player.global_position)
	if player_in_attack_zone and can_attack:
		_start_attack()
	else:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * max_speed
		_set_state(State.WALK)
		_apply_flip(direction.x < 0)
	move_and_slide()

func _start_attack():
	_set_state(State.ATTACK)
	can_attack = false
	var player = _get_player()
	
	if player:
		_apply_flip((player.global_position.x - global_position.x) < 0)
	
	# Проигрываем звук взмаха
	if attack_swoosh_sound and attack_sound_player:
		attack_sound_player.stream = attack_swoosh_sound
		attack_sound_player.play()
	
	animated_sprite.play("attack")
	
	await get_tree().create_timer(hit_delay).timeout
	
	attack_area.monitoring = false
	attack_area.damage = attack_damage
	attack_area.collision_layer = 8
	attack_area.monitoring = true
	await get_tree().create_timer(attack_duration).timeout
	
	attack_area.monitoring = false
	attack_area.collision_layer = 0
	attack_area.damage = 0
	attack_area.monitoring = true
	
	attack_cooldown_timer.start()
	await attack_cooldown_timer.timeout
	can_attack = true
	
	if player_detected: _set_state(State.WALK)
	else: _set_state(State.IDLE)

func _on_health_changed():
	_update_health_bar()
	if current_state == State.DEATH:
		return
	_set_state(State.HIT)
	var player = _get_player()
	if player:
		_apply_flip((player.global_position.x - global_position.x) < 0)
	animated_sprite.play("hit")
	var hit_length = 2.0 / 5.0
	await get_tree().create_timer(hit_length).timeout
	if current_state == State.DEATH:
		return
	if player_detected:
		_set_state(State.WALK)
	else:
		_set_state(State.IDLE)

func _on_died():
	_set_state(State.DEATH)
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	progress_bar.visible = false
	animated_sprite.play("death")
	$HurtBoxComponent.monitoring = false
	var death_length = animated_sprite.sprite_frames.get_frame_count("death") / animated_sprite.sprite_frames.get_animation_speed("death")
	await get_tree().create_timer(death_length).timeout

func _get_player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D

func _set_state(new_state: State):
	if current_state == State.DEATH:
		return
	current_state = new_state
	match new_state:
		State.IDLE: animated_sprite.play("idle")
		State.WALK: animated_sprite.play("walk")

func _update_health_bar():
	progress_bar.value = health_component.get_health_value()

func _play_footstep_sound():
	if footstep_sounds.is_empty() or not footstep_player:
		return
	var surface_group = "default"
	if ground_check_ray and ground_check_ray.is_colliding():
		var collider = ground_check_ray.get_collider()
		for group in footstep_sounds.keys():
			if collider.is_in_group(group):
				surface_group = group
				break
	var sound = footstep_sounds.get(surface_group, null)
	if not sound:
		sound = footstep_sounds.get("default", null)
	if sound is AudioStream:
		footstep_player.stream = sound
		footstep_player.play()

func _on_detection_area_body_entered(body: Node2D):
	if body.is_in_group("player"):
		player_detected = true

func _on_detection_area_body_exited(body: Node2D):
	if body.is_in_group("player"):
		player_detected = false
		if current_state not in [State.DEATH, State.ATTACK, State.HIT]:
			_set_state(State.IDLE)

func _on_attack_trigger_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_attack_zone = true

func _on_attack_trigger_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_attack_zone = false
