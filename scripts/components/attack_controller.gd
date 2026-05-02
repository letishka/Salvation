extends Node

@export var attack_ability: PackedScene

@onready var timer = $Timer

var sword_damage = 50
#var default_attack_speed


#func _ready():
	#Global.ability_upgrade_added.connect(on_upgrade_added)
	#default_attack_speed = timer.wait_time

func _on_timer_timeout():
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
		
	var attack_instance = attack_ability.instantiate() as Node2D
	player.get_parent().add_child(attack_instance)
	attack_instance.global_position = player.global_position

#func on_upgrade_added(upgrade:AbilityUpgrade,current_upgrades:Dictionary):
	#if upgrade.id != "sword_rate":
		#return
		
	#var upgrade_percent = current_upgrades["sword_rate"]["quantity"] * .1
	#timer.wait_time = max(0.1, default_attack_speed * (1 - upgrade_percent))
	#timer.start()
	
