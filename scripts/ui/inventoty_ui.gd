extends CanvasLayer

@onready var slot = $Panel/Slot
@onready var item_icon = $Panel/Slot/ItemIcon

func _ready():
	slot.visible = false
	GameManager.inventory_changed.connect(_on_inventory_changed)

func _on_inventory_changed(has_torch: bool, torch_lit: bool):
	slot.visible = has_torch
	if has_torch:
		if torch_lit:
			item_icon.modulate = Color(1, 0.8, 0.3)  # светлый (зажжён)
		else:
			item_icon.modulate = Color(0.5, 0.3, 0)  # тёмный (не зажжён)
