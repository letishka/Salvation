extends CanvasLayer

@onready var slot = $Panel/Slot
@onready var without_fire = $Panel/Slot/WithoutFire
@onready var with_fire = $Panel/Slot/WithFire
@onready var torch_light = $Panel/Slot/TorchLight  # PointLight2D

func _ready():
	slot.visible = false
	without_fire.visible = false
	with_fire.visible = false
	if torch_light:
		torch_light.enabled = false
	GameManager.inventory_changed.connect(_on_inventory_changed)

func _on_inventory_changed(has_torch: bool, torch_lit: bool):
	slot.visible = has_torch
	
	if has_torch:
		if torch_lit:
			# Факел зажжён — показываем with_fire, свет включён
			without_fire.visible = false
			with_fire.visible = true
			if torch_light:
				torch_light.enabled = true
			print("Inventory: torch lit, showing with_fire, light ON")
		else:
			# Факел не зажжён — показываем without_fire, свет выключен
			without_fire.visible = true
			with_fire.visible = false
			if torch_light:
				torch_light.enabled = false
			print("Inventory: torch not lit, showing without_fire, light OFF")
	else:
		# Нет факела — всё скрыто
		without_fire.visible = false
		with_fire.visible = false
		if torch_light:
			torch_light.enabled = false
