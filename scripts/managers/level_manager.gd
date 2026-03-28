extends Node

var current_level: Node
var player: Node
var checkpoint: Vector2

func register_level(level: Node):
	current_level = level

func register_player(p: Node):
	player = p

func set_checkpoint(pos: Vector2):
	checkpoint = pos

func respawn():
	if checkpoint and player:
		player.global_position = checkpoint
		if player.has_method("reset_health"):
			player.reset_health()
		player.set_physics_process(true)
		player.set_process_input(true)
		if player.has_node("StateMachine"):
			player.get_node("StateMachine").change_to("Idle")
