extends CharacterBody2D
class_name Player

@export var speed: float = 200.0
@export var sprint_speed: float = 350.0
@export var attack_duration: float = 0.3
@export var dodge_duration: float = 0.5

@onready var health_component = $HealthComponent
@onready var attack_component = $AttackComponent
@onready var ability_user = $AbilityUser
@onready var state_machine = $StateMachine
@onready var interact_area = $InteractArea

var current_interactable: Node = null
var is_dodging: bool = false

var has_torch: bool = false
var torch_lit: bool = false

func _ready():
	add_to_group("player")
	LevelManager.register_player(self)
	health_component.died.connect(_on_death)
	ability_user.ability_used.connect(_on_ability_used)
	interact_area.area_entered.connect(_on_interactable_entered)
	interact_area.area_exited.connect(_on_interactable_exited)
	$TorchSprite.hide()

func _process(delta):
	ability_user.update(delta)

func _input(event):
	if event.is_action_pressed("attack") and state_machine.current_state.name != "Attack":
		state_machine.change_to("Attack")
	elif event.is_action_pressed("dodge") and state_machine.current_state.name != "Dodge":
		state_machine.change_to("Dodge")
	elif event.is_action_pressed("use_ability"):
		# В будущем выбирать активную способность, пока просто вода
		ability_user.use("water")
	elif event.is_action_pressed("interact") and current_interactable:
		current_interactable.interact()

func _on_ability_used(ability_id: String):
	if ability_id == "water":
		freeze_nearby_enemies()
		try_create_ice_platform()
	# Добавить другие способности позже

func freeze_nearby_enemies():
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if global_position.distance_to(enemy.global_position) < 100:
			if enemy.has_method("freeze"):
				enemy.freeze(2.0)

func try_create_ice_platform():
	var tilemap = get_parent().get_node("TileMap")
	if tilemap:
		var cell = tilemap.get_cell_tile_data(0, tilemap.local_to_map(global_position))
		if cell and cell.get_custom_data("water"):
			var ice = preload("res://scenes/objects/ice_platform.tscn").instantiate()
			ice.position = global_position
			get_parent().add_child(ice)

func _on_death():
	set_physics_process(false)
	set_process_input(false)
	state_machine.change_to("Dead")

func _on_interactable_entered(area):
	var parent = area.get_parent()
	if parent == self:
		return
	if parent.has_method("interact"):
		current_interactable = parent

func _on_interactable_exited(area):
	if current_interactable == area.get_parent():
		current_interactable = null

# Обёртка для take_damage, чтобы компоненты могли вызывать
func take_damage(amount: int):
	health_component.take_damage(amount)
	
# Метод для подбора факела
func pickup_torch():
	has_torch = true
	torch_lit = false
	# Показать визуально, что факел в руках
	$TorchSprite.show()  # добавьте Sprite2D для факела

# Метод для зажигания факела
func light_torch():
	if has_torch and not torch_lit:
		torch_lit = true
		# Изменить спрайт факела на горящий
		$TorchSprite.texture = preload("res://assets/graphics/objects/lit_torch.png")
		# Воспроизвести звук

# Метод для установки факела в подставку
func place_torch():
	if has_torch and torch_lit:
		has_torch = false
		torch_lit = false
		$TorchSprite.hide()
		# Вернуть горящий факел в инвентарь? Нет, он вставлен.
	
