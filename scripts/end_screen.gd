extends CanvasLayer
class_name EndScreen

func _ready() -> void:
	get_tree().paused = true


func _process(delta: float) -> void:
	pass


func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/levels/test.tscn")

func _on_main_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()
