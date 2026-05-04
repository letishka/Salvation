extends CharacterBody2D

enum State { IDLE, WALK, ATTACK, HIT, DEATH }

@export var max_health: float = 30.0
@export var max_speed: float = 80.0
@export var attack_damage: float = 13.0
@export var attack_duration: float = 0.1     # длительность активной зоны
@export var attack_cooldown: float = 0.6
@export var attack_range: float = 120.0
@export var flip_offset_x: float = -32.0
@export var collision_offset_x: float = -32.0
@export var hit_delay: float = 0.3           # задержка до удара внутри анимации

@onready var health_component: HealthComponent = $HealthComponent
@onready var detection_area: Area2D = $DetectionArea
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: HitBoxComponent = $EnemyHitBox
@onready var attack_collision: CollisionShape2D = $EnemyHitBox/CollisionShape2D
@onready var attack_cooldown_timer: Timer = $AttackCooldown

var player_detected: bool = false
var current_state: State = State.IDLE
var can_attack: bool = true

var _attack_collision_base_pos: Vector2

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

func _apply_flip(is_left: bool):
	animated_sprite.flip_h = is_left
	animated_sprite.offset.x = flip_offset_x if is_left else -flip_offset_x
	if attack_collision:
		if is_left:
			attack_collision.position.x = _attack_collision_base_pos.x + collision_offset_x
		else:
			attack_collision.position.x = _attack_collision_base_pos.x

func _physics_process(_delta):
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
	if distance <= attack_range and can_attack:
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
	animated_sprite.play("death")
	var death_length = animated_sprite.sprite_frames.get_frame_count("death") / animated_sprite.sprite_frames.get_animation_speed("death")
	await get_tree().create_timer(death_length).timeout
	queue_free()

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

func _on_detection_area_body_entered(body: Node2D):
	if body.is_in_group("player"):
		player_detected = true

func _on_detection_area_body_exited(body: Node2D):
	if body.is_in_group("player"):
		player_detected = false
		if current_state not in [State.DEATH, State.ATTACK, State.HIT]:
			_set_state(State.IDLE)
