extends CanvasLayer

var options_menu_scene = preload("res://scenes/ui/OptionsMenu.tscn")


func _ready() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	$BackgroundMusic.play()

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/test.tscn")

func _on_options_button_pressed() -> void:
	var options_instance = options_menu_scene.instantiate()
	add_child(options_instance)

func _on_quit_button_pressed() -> void:
	get_tree().quit()
