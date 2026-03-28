extends Node

const SAVE_PATH = "user://savegame.save"

func save_game(data: Dictionary):
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))

func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json = JSON.parse_string(file.get_as_text())
	return json if json else {}
