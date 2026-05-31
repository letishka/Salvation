extends Area2D

@export var flight_animation: String = "flight"
@export var impact_animation: String = "impact"

var speed: float = 0.0
var direction: Vector2 = Vector2.RIGHT
var damage: float = 10.0

var _has_impacted: bool = false

func _ready():
	if has_meta("speed"): speed = get_meta("speed")
	if has_meta("damage"): damage = get_meta("damage")
	if has_meta("direction"): direction = get_meta("direction").normalized()
	
	_setup_arrow()

func init(dir: Vector2, spd: float, dmg: float):
	direction = dir.normalized()
	speed = spd
	damage = dmg
	_setup_arrow()

func _setup_arrow():
	rotation = direction.angle()
	
	if has_node("AnimatedSprite2D"):
		var sprite = $AnimatedSprite2D as AnimatedSprite2D
		if sprite.sprite_frames and sprite.sprite_frames.has_animation(flight_animation):
			sprite.play(flight_animation)
	
	_update_z_index()

func _update_z_index():
	var angle_deg = rad_to_deg(direction.angle())
	var abs_angle = abs(angle_deg)
	z_index = 1 if abs_angle > 0 and abs_angle < 180 else 0

func _physics_process(delta):
	if _has_impacted:
		return
	position += direction * speed * delta

func _on_body_entered(body: Node2D):
	if _has_impacted:
		return
	_has_impacted = true

	# Наносим урон
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		elif body.has_node("HealthComponent"):
			var hc = body.get_node("HealthComponent")
			if hc.has_method("take_damage"):
				hc.take_damage(damage)

	# Отключаем дальнейшие столкновения
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

	# Останавливаем движение
	speed = 0.0

	# Запускаем анимацию врезания
	if has_node("AnimatedSprite2D"):
		var sprite = $AnimatedSprite2D as AnimatedSprite2D
		if sprite.sprite_frames and sprite.sprite_frames.has_animation(impact_animation):
			sprite.play(impact_animation)
			# Ждём завершения анимации и удаляем стрелу
			await sprite.animation_finished
	queue_free()
