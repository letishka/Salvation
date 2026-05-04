extends Node2D

@export var end_screen_scene: PackedScene
@onready var bridge = $Bridge
@onready var enemy = $ShadowSoldier
#@onready var memory_shard = $MemoryShard

var bridge_activated = false
var player = null

func _ready():
	$BackgroundMusic.play()
	$BackgroundMusic2.play()
	# Получаем игрока через группу
	player = get_tree().get_first_node_in_group("player")
	if not player:
		print("Ошибка: игрок не найден в группе 'player'")
		return
	
	# Подключаем сигнал смерти
	if player.has_node("HealthComponent"):
		player.health_component.died.connect(_on_died)
	else:
		print("Ошибка: у игрока нет HealthComponent")
	
	# Настройка врага
	enemy.visible = false
	enemy.set_physics_process(false)
	
	# Настройка моста
	# bridge.position = bridge.up_position
	var collision = bridge.get_node("CollisionShape2D")
	if collision:
		collision.disabled = true

func _process(delta):
	if not bridge_activated:
		bridge_activated = true
		_activate_enemy()

func _activate_enemy():
	enemy.visible = true
	enemy.set_physics_process(true)
	if GameManager.has_signal("show_hint"):
		GameManager.show_hint.emit("ЛКМ – атака, Пробел – уклонение")
	else:
		print("Подсказка: ЛКМ – атака, Пробел – уклонение")

func _on_died():
	if end_screen_scene:
		var end_screen_instance = end_screen_scene.instantiate()
		add_child(end_screen_instance)
