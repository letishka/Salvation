extends State
class_name PlayerIdle

func enter():
	actor.velocity = Vector2.ZERO

func physics_update(delta):
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir != Vector2.ZERO:
		state_machine.change_to("Move")
