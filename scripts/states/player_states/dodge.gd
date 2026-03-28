extends State
class_name PlayerDodge

func enter():
	actor.is_dodging = true
	actor.health_component.is_invincible = true
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()
	actor.velocity = direction * actor.sprint_speed * 2
	await get_tree().create_timer(actor.dodge_duration).timeout
	actor.is_dodging = false
	actor.health_component.is_invincible = false
	state_machine.change_to("Idle")
