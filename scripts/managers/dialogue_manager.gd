extends Node

signal dialogue_finished

var _dialogues: Dictionary = {}

var _current_key: String = ""
var _current_line_index: int = 0
var _is_active: bool = false

func _ready():
	_load_all_dialogues()

func _load_all_dialogues():
	var dir_path = "res://data/dialogues/"
	if not DirAccess.dir_exists_absolute(dir_path):
		print("DialogueManager: Папка диалогов не найдена: ", dir_path)
		return
	
	var files = DirAccess.get_files_at(dir_path)
	for file in files:
		if file.ends_with(".json"):
			var file_path = dir_path + file
			var content = FileAccess.get_file_as_string(file_path)
			if content.is_empty():
				print("DialogueManager: Пустой файл: ", file_path)
				continue
			var json = JSON.parse_string(content)
			if json == null:
				print("DialogueManager: Ошибка парсинга JSON в файле: ", file_path)
				continue
			for key in json:
				if _dialogues.has(key):
					print("DialogueManager: Предупреждение – дублирующийся ключ диалога: ", key)
				_dialogues[key] = json[key]

func get_dialogue_lines(key: String) -> Array:
	if _dialogues.has(key):
		return _dialogues[key]
	return []

func start_dialogue(key: String):
	if _is_active:
		print("DialogueManager: Диалог уже активен, сначала закройте его.")
		return
	if not _dialogues.has(key):
		print("DialogueManager: Диалог с ключом '", key, "' не найден.")
		return
	
	_current_key = key
	_current_line_index = 0
	_is_active = true
	_show_current_line()

func _show_current_line():
	var lines = _dialogues[_current_key]
	if _current_line_index < lines.size():
		var line = lines[_current_line_index]
		var speaker = line.get("speaker", "")
		var text = line.get("text", "")
		GameManager.show_dialogue.emit(speaker, text)
	else:
		close_dialogue()

func next_line():
	if not _is_active:
		return
	_current_line_index += 1
	_show_current_line()

func close_dialogue():
	if not _is_active:
		return
	_is_active = false
	_current_key = ""
	_current_line_index = 0
	GameManager.hide_dialogue.emit()
	dialogue_finished.emit()

func is_active() -> bool:
	return _is_active
