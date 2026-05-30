extends StaticBody2D
class_name Gate

signal opened

@export var required_torches: int = 3
var lit_torches: int = 0

@onready var closed_sprite = $ClosedSprite
@onready var open_sprite = $OpenSprite
@onready var anim_player = $AnimationPlayer

func register_lit_torch():
	lit_torches += 1
	print("Gate: torch placed, ", lit_torches, "/", required_torches)
	if lit_torches >= required_torches:
		open()

func open():
	print("Gate opening!")
	if closed_sprite:
		closed_sprite.visible = false
	if open_sprite:
		open_sprite.visible = true
	if anim_player and anim_player.has_animation("open"):
		anim_player.play("open")
	$CollisionShape2D.disabled = true
	opened.emit()
