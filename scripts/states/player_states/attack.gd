extends State
class_name PlayerAttack

func enter():
	actor.attack_component.activate()
	await get_tree().create_timer(actor.attack_duration).timeout
	state_machine.change_to("Idle")

func physics_update(delta):
	actor.velocity = Vector2.ZERO
