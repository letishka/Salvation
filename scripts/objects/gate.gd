extends StaticBody2D
class_name Gate

signal portal_activated

@export var required_torches: int = 3
var lit_torches: int = 0

@onready var closed_sprite = $Sprite2D
@onready var portal_texture = $TextureRect

func register_lit_torch():
	lit_torches += 1
	print("Gate: torch placed, ", lit_torches, "/", required_torches)
	if lit_torches >= required_torches:
		activate_portal()

func activate_portal():
	print("Portal activated on gate!")
	
	if portal_texture:
		portal_texture.visible = true
		
		portal_texture.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(portal_texture, "modulate:a", 1.0, 0.5)

	if has_node("AudioStreamPlayer2D"):
		$AudioStreamPlayer2D.play()
	
	portal_activated.emit()
