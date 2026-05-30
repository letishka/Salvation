extends Area2D

var speed: float = 0.0
var direction: Vector2 = Vector2.RIGHT
var damage: float = 10.0

func _ready():
	if has_meta("speed"): speed = get_meta("speed")
	if has_meta("damage"): damage = get_meta("damage")
	if has_meta("direction"): direction = get_meta("direction").normalized()
	if has_node("Sprite2D"):
		$Sprite2D.rotation = direction.angle()
	
	_update_z_index()

func init(dir: Vector2, spd: float, dmg: float):
	direction = dir.normalized()
	speed = spd
	damage = dmg
	if has_node("Sprite2D"):
		$Sprite2D.rotation = direction.angle()
	_update_z_index()

func _update_z_index():
	var angle_deg = rad_to_deg(direction.angle())
	var abs_angle = abs(angle_deg)
	if abs_angle > 30 and abs_angle < 150:
		z_index = 1
	else:
		z_index = 0

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		elif body.has_node("HealthComponent"):
			var hc = body.get_node("HealthComponent")
			if hc.has_method("take_damage"):
				hc.take_damage(damage)
	queue_free()
