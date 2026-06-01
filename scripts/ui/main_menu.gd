extends CanvasLayer

var options_menu_scene = preload("res://scenes/ui/OptionsMenu.tscn")

func _ready() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	MusicManager.play_menu_music(1.0)
	# $BackgroundMusic.play()

func _on_play_button_pressed() -> void:
	# Удаляем старое сохранение, чтобы начать с чистого листа
	if FileAccess.file_exists("user://checkpoint.tscn"):
		DirAccess.remove_absolute("user://checkpoint.tscn")
	get_tree().change_scene_to_file("res://scenes/levels/prologue.tscn")

func _on_options_button_pressed() -> void:
	var options_instance = options_menu_scene.instantiate()
	add_child(options_instance)

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_continue_button_pressed() -> void:
	if FileAccess.file_exists("user://checkpoint.tscn"):
		get_tree().change_scene_to_file("user://checkpoint.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/levels/prologue.tscn")
