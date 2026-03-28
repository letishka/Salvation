extends Node

var _dialogues: Dictionary = {}
var _current_key: String = ""
var _current_line: int = 0
var _is_active: bool = false

func _ready():
	load_all_dialogues()

func load_all_dialogues():
	var dir = "res://data/dialogues/"
	if not DirAccess.dir_exists_absolute(dir):
		return
	var files = DirAccess.get_files_at(dir)
	for file in files:
		if file.ends_with(".json"):
			var content = FileAccess.get_file_as_string(dir + file)
			var json = JSON.parse_string(content)
			for key in json:
				_dialogues[key] = json[key]

func start_dialogue(key: String):
	if _dialogues.has(key):
		_current_key = key
		_current_line = 0
		_is_active = true
		show_current_line()

func show_current_line():
	var lines = _dialogues[_current_key]
	if _current_line < lines.size():
		var line = lines[_current_line]
		GameManager.display_dialogue(line.speaker, line.text)
	else:
		close_dialogue()

func next_line():
	if not _is_active:
		return
	_current_line += 1
	show_current_line()

func close_dialogue():
	_is_active = false
	GameManager.close_dialogue()
