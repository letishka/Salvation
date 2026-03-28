extends Node2D
class_name WaterController

@export var tilemap: TileMap           # ссылка на TileMap уровня
@export var water_layer: int = 0       # слой, где вода
@export var water_tile_id: int         # ID тайла воды (в TileSet)
@export var no_water_tile_id: int = -1 # -1 = пустота

var current_water_level: int = 0       # 0 = полностью вода, 1 = понижена и т.д.

func activate(state: bool):
	# state = true  -> вода уходит (опускаем плотину)
	# state = false -> вода возвращается (поднимаем)
	if state:
		set_water_level(1)  # или постепенное понижение
	else:
		set_water_level(0)

func set_water_level(level: int):
	# Здесь логика изменения воды на TileMap
	# Например, для простоты: замена всех тайлов воды на пустоту
	# var rect = tilemap.get_used_rect(water_layer)
	# for cell in rect:
		# if tilemap.get_cell_source_id(water_layer, cell) == 0:
			# tilemap.set_cell(water_layer, cell, -1, Vector2i(-1, -1))
	pass
			
# func set_water_visible(visible: bool):
#    tilemap.set_layer_enabled(water_layer, visible)
