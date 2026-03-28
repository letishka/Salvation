extends State
class_name PlayerMove

func physics_update(delta):
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction = input_dir.normalized()
	var speed = actor.speed
	if Input.is_action_pressed("sprint"):
		speed = actor.sprint_speed
	actor.velocity = direction * speed
	actor.move_and_slide()
	if direction == Vector2.ZERO:
		state_machine.change_to("Idle")
