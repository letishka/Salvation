extends StaticBody2D
class_name TorchHolder

signal torch_placed

@export var target_node_path: NodePath
var is_lit: bool = false

@onready var holder_empty = $Sprite2D
@onready var holder_lit = $Sprite2D2
@onready var holder_light = $PointLight2D
@onready var interact_area = $Area2D

func _ready():
	# Изначально подставка пустая
	if holder_empty:
		holder_empty.visible = true
	if holder_lit:
		holder_lit.visible = false
	if holder_light:
		holder_light.enabled = false

func interact():
	print("TorchHolder.interact() called")
	
	if is_lit:
		GameManager.show_hint.emit("Здесь уже есть факел!", 2.0)
		return
	
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		print("Player not found")
		return
	
	if not player.has_method("place_torch"):
		print("Player has no place_torch method")
		return
	
	if not player.has_torch:
		GameManager.show_hint.emit("У тебя нет факела!", 2.0)
		return
	
	if not player.torch_lit:
		GameManager.show_hint.emit("Факел не зажжён! Подойди к костру.", 2.0)
		return
	
	# Устанавливаем факел
	print("Placing torch...")
	if player.place_torch():
		is_lit = true
		
		# Меняем визуал подставки
		if holder_empty:
			holder_empty.visible = false
		if holder_lit:
			holder_lit.visible = true
		if holder_light:
			holder_light.enabled = true
		
		# Отправляем сигнал на уровень
		torch_placed.emit()
		
		# Уведомляем цель (ворота)
		var target = get_node(target_node_path) if target_node_path else null
		if target and target.has_method("register_lit_torch"):
			target.register_lit_torch()
		elif target and target.has_method("activate"):
			target.activate(true)
		
		print("Torch placed successfully!")
	else:
		print("place_torch returned false")
