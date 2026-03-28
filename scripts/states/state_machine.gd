extends Node
class_name StateMachine

@export var initial_state: State
var current_state: State

func _ready():
	# Назначаем actor и state_machine всем дочерним состояниям
	for child in get_children():
		if child is State:
			child.actor = get_parent()
			child.state_machine = self
	current_state = initial_state
	current_state.enter()

func change_to(state_name: String):
	var new_state = get_node(state_name)
	if new_state and new_state != current_state:
		current_state.exit()
		current_state = new_state
		current_state.enter()

func _process(delta):
	current_state.update(delta)

func _physics_process(delta):
	current_state.physics_update(delta)

func _input(event):
	current_state.handle_input(event)
