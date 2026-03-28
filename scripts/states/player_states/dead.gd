extends State
class_name PlayerDead

func enter():
	actor.set_physics_process(false)
	actor.set_process_input(false)
	await get_tree().create_timer(1.0).timeout
	LevelManager.respawn()
