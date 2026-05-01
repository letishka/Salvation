extends CharacterBody2D
class_name ShadowSoldier

@export var speed: float = 80.0
@export var attack_cooldown: float = 1.0
@export var damage: int = 10

@onready var health_component = $HealthComponent
@onready var attack_component = $AttackComponent
@onready var detection_area = $DetectionArea

var player: Node = null
var can_attack: bool = true
var health_bar: ProgressBar = null
var is_frozen: bool = false

func _ready():
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")
	health_component.died.connect(queue_free)
	detection_area.body_entered.connect(_on_player_detected)
	
	health_bar = ProgressBar.new()
	health_bar.max_value = health_component.max_health
	health_bar.value = health_component.current_health
	health_bar.custom_minimum_size = Vector2(50, 10)
	add_child(health_bar)
	health_bar.position = Vector2(-25, -40)   # смещение относительно врага
	health_component.health_changed.connect(_on_health_changed)

func _physics_process(delta):
	if not player:
		return
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()
	if can_attack and global_position.distance_to(player.global_position) < 30:
		attack()

func attack():
	can_attack = false
	attack_component.activate()
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func _on_player_detected(body):
	if body == player:
		pass

func take_damage(amount: int):
	health_component.take_damage(amount)

func freeze(duration: float):
	if is_frozen: return
	is_frozen = true
	set_physics_process(false)
	await get_tree().create_timer(duration).timeout
	set_physics_process(true)
	is_frozen = false

func _on_health_changed(current: float, max: float):
	if health_bar:
		health_bar.value = current
		health_bar.max_value = max
