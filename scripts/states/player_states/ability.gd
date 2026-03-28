extends State
class_name PlayerAbility

func enter():
	# Заблокировать движение на время анимации способности
	await get_tree().create_timer(0.5).timeout
	state_machine.change_to("Idle")

func physics_update(delta):
	actor.velocity = Vector2.ZERO
