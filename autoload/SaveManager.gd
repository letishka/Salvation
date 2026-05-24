extends Node

const SAVE_PATH = "user://checkpoint.tscn"

func _ready() -> void:
	get_tree().scene_changed.connect(_on_scene_changed)

func _on_scene_changed(scene: Node = null) -> void:
	if not scene:
		scene = get_tree().current_scene
	if not scene:
		return

	var path = scene.scene_file_path
	if path.begins_with("res://scenes/ui/"):
		return

	save_checkpoint()

func save_checkpoint():
	var packed = PackedScene.new()
	var result = packed.pack(get_tree().current_scene)
	if result == OK:
		ResourceSaver.save(packed, SAVE_PATH)

func load_checkpoint():
	if FileAccess.file_exists(SAVE_PATH):
		get_tree().paused = false
		get_tree().change_scene_to_file(SAVE_PATH)
