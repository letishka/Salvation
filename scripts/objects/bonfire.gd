extends Area2D
class_name Bonfire

@onready var animated_sprite = $Bonfire
@onready var fire_sound = $FireSound

func _ready():
	body_entered.connect(_on_body_entered)
	if animated_sprite:
		animated_sprite.play("default")
	if fire_sound:
		fire_sound.play()

func _on_body_entered(body):
	if body.is_in_group("player"):
		var player = body
		print("Bonfire: player entered")
		
		if player.has_torch and not player.torch_lit:
			print("Bonfire: lighting torch")
			player.light_torch()
			GameManager.show_hint.emit("Факел зажжён! Неси к пустой подставке.", 2.0)
		else:
			print("Bonfire: can't light torch - has_torch=", player.has_torch, " torch_lit=", player.torch_lit)
