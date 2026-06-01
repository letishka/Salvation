extends Node

var music_player: AudioStreamPlayer
var current_volume: float = -15.0
var current_music: String = ""  # "menu", "game", или "" (тишина)

func _ready():
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = current_volume
	add_child(music_player)
	process_mode = Node.PROCESS_MODE_ALWAYS

# Включить музыку меню
func play_menu_music(fade_in: float = 1.0):
	if current_music == "menu" and music_player.playing:
		return
	
	# Останавливаем текущую музыку
	if music_player.playing:
		await _fade_out(0.3)
		music_player.stop()
	
	current_music = "menu"
	music_player.stream = preload("res://assets/audio/music/Josh Cohen - Daydreaming ( Radiohead cover)_(x-minusovka.com).mp3")
	
	music_player.play()
	
	if fade_in > 0:
		music_player.volume_db = -80
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", current_volume, fade_in)

# Включить игровую музыку (уровни)
func play_game_music(fade_in: float = 1.0):
	if current_music == "game" and music_player.playing:
		return
	
	if music_player.playing:
		await _fade_out(0.3)
		music_player.stop()
	
	current_music = "game"
	music_player.stream = preload("res://assets/audio/music/Radiohead_-_Treefingers_47843709.mp3")
	music_player.play()
	
	if fade_in > 0:
		music_player.volume_db = -80
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", current_volume, fade_in)

# Выключить музыку (тишина в прологе)
func stop_music(fade_out: float = 0.5):
	if music_player.playing:
		await _fade_out(fade_out)
		music_player.stop()
	current_music = ""

func _fade_out(duration: float):
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", -80, duration)
	await tween.finished

# Изменить громкость
func set_volume(volume: float):
	current_volume = volume
	if music_player.playing:
		music_player.volume_db = volume

func get_volume_linear() -> float:
	return db_to_linear(current_volume)
