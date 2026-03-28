extends State
class_name PlayerHit

func enter():
	await get_tree().create_timer(0.3).timeout
	state_machine.change_to("Idle")

func physics_update(delta):
	actor.velocity = Vector2.ZERO
