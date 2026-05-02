# ДОКУМЕНТАЦИЯ ПРОЕКТА «SALVATION»

## 1. ОБЩАЯ АРХИТЕКТУРА И ФИЛОСОФИЯ

Проект построен на трёх китах:

- **Компонентный подход** – функциональность (здоровье, атака, способности) вынесена в отдельные узлы-компоненты, которые можно прикрепить к любому персонажу.
- **Конечный автомат (State Machine)** – все действия игрока (бег, атака, уклонение, получение урона, смерть) реализованы как отдельные состояния. Это исключает спагетти-код с кучей флагов.
- **Глобальные менеджеры (автозагрузки)** – синглтоны, через которые происходит обмен сигналами (здоровье → UI, диалоги и т.д.). Они доступны из любого скрипта.

**Важное замечание:** код старались писать максимально модульно и масштабируемо, чтобы в будущем легко добавлять новых врагов, боссов, способности и целые уровни.

---

## 2. СТРУКТУРА ПАПОК

```
res://
├── addons/               (пусто, для будущих плагинов)
├── assets/               (вся графика, звуки, музыка)
│   ├── graphics/
│   └── audio/
├── autoload/             (файлы-однострочники, ссылающиеся на менеджеров)
├── data/
│   ├── abilities/        (ресурсы способностей .tres)
│   └── dialogues/        (JSON диалоги)
├── scenes/
│   ├── characters/
│   │   ├── player/       (player.tscn)
│   │   └── enemies/      (shadow_soldier.tscn)
│   ├── levels/           (water_level_1.tscn, test.tscn)
│   ├── objects/          (lever, bridge, pressure_plate и т.д.)
│   └── ui/               (ui.tscn, MainMenu.tscn, OptionsMenu.tscn, EndScreen.tscn)
└── scripts/
	├── components/       (health_component.gd, attack_component.gd, ability_user.gd)
	├── managers/         (game_manager.gd, level_manager.gd и т.д.)
	├── states/           (state.gd, state_machine.gd, player_states/*.gd)
	├── objects/          (скрипты для интерактивных объектов)
	└── (другие скрипты)
```

---

## 3. ГЛОБАЛЬНЫЕ МЕНЕДЖЕРЫ (АВТОЗАГРУЗКИ)

### 3.1 GameManager
**Файл:** `autoload/GameManager.gd` → `scripts/managers/game_manager.gd`

**Назначение:** связь между игроком и UI (здоровье, диалоги, память). Испускает сигналы, на которые подписан `ui.gd`.

**Сигналы:**
- `health_changed(health, max_health)`
- `ability_cooldown_started(ability_id, remaining)`
- `show_dialogue(speaker, text)`
- `hide_dialogue`
- `show_memory(text, image)`

**Методы:**
- `func update_health(health, max_health)` → эмитит `health_changed`
- `func display_dialogue(speaker, text)` → эмитит `show_dialogue`
- `func close_dialogue()` → эмитит `hide_dialogue`
- `func display_memory(text, image)` → эмитит `show_memory`

> **Что делает:** любой объект может вызвать `GameManager.display_dialogue(...)`, и UI покажет окно.

### 3.2 LevelManager
**Файл:** `autoload/LevelManager.gd` → `scripts/managers/level_manager.gd`

**Назначение:** чекпоинты и респавн игрока.

**Методы:**
- `register_level(level)` – вызывается уровнем в `_ready()`
- `register_player(player)` – вызывается игроком в `_ready()`
- `set_checkpoint(pos)` – сохраняет позицию чекпоинта
- `respawn()` – телепортирует игрока в чекпоинт, сбрасывает здоровье, включает управление, переводит в `Idle`

### 3.3 DialogueManager
**Файл:** `autoload/DialogueManager.gd` → `scripts/managers/dialogue_manager.gd`

**Назначение:** загружает диалоги из JSON и управляет их показом.

**Методы:**
- `start_dialogue(key)` – начинает диалог
- `next_line()` – следующая реплика
- `close_dialogue()` – закрывает диалог

### 3.4 SaveManager
**Файл:** `autoload/SaveManager.gd` → `scripts/managers/save_manager.gd`

**Назначение:** заготовка для сохранений (пока не используется).

---

## 4. КОМПОНЕНТЫ

### 4.1 HealthComponent (`scripts/components/health_component.gd`)
**Сигналы:** `health_changed(current, max)`, `died`

**Методы:**
- `take_damage(amount)` → уменьшает здоровье, включает неуязвимость, при смерти эмитит `died`
- `heal(amount)` → восстанавливает здоровье
- `reset()` → сбрасывает здоровье и неуязвимость

### 4.2 AttackComponent (`scripts/components/attack_component.gd`)
**Роль:** временная зона атаки (Area2D).

**Методы:**
- `activate()` → включает мониторинг на `active_time` секунд, при входе тела вызывает `body.take_damage(damage)`

### 4.3 AbilityUser (`scripts/components/ability_user.gd`)
**Роль:** управление способностями (ресурсы, перезарядка).

**Методы:**
- `can_use(ability_id)` → проверяет перезарядку
- `use(ability_id)` → активирует способность, запускает перезарядку, эмитит `ability_used`
- `update(delta)` → обновляет таймеры перезарядки (вызывается в `_process` игрока)

---

## 5. КОНЕЧНЫЙ АВТОМАТ (STATE MACHINE)

### 5.1 State (`scripts/states/state.gd`)
Базовый класс. Содержит ссылки `actor` (владелец) и `state_machine`. Методы-заглушки: `enter()`, `exit()`, `update()`, `physics_update()`, `handle_input()`.

### 5.2 StateMachine (`scripts/states/state_machine.gd`)
- `_ready()` – инициализирует все дочерние состояния, передаёт им ссылки на `actor`.
- `change_to(state_name)` – переключает состояние.

### 5.3 Состояния игрока (папка `player_states`)

| Файл | Что делает |
|------|-------------|
| `idle.gd` | стоит на месте; при появлении ввода → `Move` |
| `move.gd` | движение (спринт), при остановке → `Idle` |
| `attack.gd` | активирует `AttackComponent`, через `attack_duration` → `Idle` |
| `dodge.gd` | рывок, неуязвимость, через `dodge_duration` → `Idle` |
| `hit.gd` | пауза 0.3 сек, затем → `Idle` |
| `dead.gd` | отключает физику/ввод, через 1 сек → `LevelManager.respawn()` |
| `ability.gd` | заглушка (анимация способности) |

---

## 6. ИГРОК (`player.tscn` + `player.gd`)

### Основные узлы в сцене:
- `CharacterBody2D` (коллизия)
- `HealthComponent`
- `AttackComponent`
- `AbilityUser`
- `StateMachine` (с дочерними состояниями)
- `InteractArea` (Area2D для взаимодействия с объектами)
- `TorchSprite` (спрайт факела в руке, скрыт)

### Ключевые методы `player.gd`:

- `_ready()` – добавляет в группу `player`, регистрируется в `LevelManager`, подключает сигналы, скрывает `TorchSprite`.
- `_physics_process(delta)` – движение (кроме состояния `Dodge`).
- `_input(event)` – обрабатывает атаку (ЛКМ), уклонение (Пробел), взаимодействие (E).
- `take_damage(amount)` – обёртка для `health_component.take_damage`.
- `_on_interactable_entered(area)` – запоминает объект с методом `interact()`.
- `pickup_torch()`, `light_torch()`, `place_torch()` – управление факелом.
- `_on_death()` – убирает игрока из группы, отключает физику/ввод, переключает в `Dead`.

---

## 7. ВРАГ – ТЕНЕВОЙ СОЛДАТ (`shadow_soldier.tscn` + `.gd`)

### Основные узлы:
- `CharacterBody2D`
- `HealthComponent`
- `AttackComponent`
- `DetectionArea` (Area2D для обнаружения игрока)

### Программно создаётся полоска здоровья (ProgressBar) как дочерний узел.

**Методы:**
- `_ready()` – добавляет в группу `enemies`, находит игрока, создаёт HP-бар.
- `_physics_process(delta)` – движется к игроку, атакует при дистанции <30.
- `attack()` – активирует `AttackComponent`, ждёт `attack_cooldown`.
- `take_damage(amount)` – передаёт урон в `HealthComponent`.
- `freeze(duration)` – временно замораживает врага (для способности воды).
- `_on_health_changed(current, max)` – обновляет полоску здоровья.

---

## 8. ИНТЕРАКТИВНЫЕ ОБЪЕКТЫ (`scripts/objects/`)

Все объекты имеют метод `interact()` и находятся на слое `interactable` (2). Игрок их обнаруживает через свою `InteractArea`.

| Файл | Назначение |
|------|-------------|
| `lever.gd` | рычаг – переключает состояние, вызывает `activate()` у цели |
| `bridge.gd` | мост – перемещается вверх/вниз, управляет коллизией |
| `pressure_plate.gd` | плита – активируется игроком или ящиком |
| `memory_shard.gd` | осколок – лечит, показывает текст |
| `torch_pickup.gd` | факел на земле – даёт игроку факел |
| `bonfire.gd` | костёр – зажигает факел игрока |
| `torch_holder.gd` | подставка – забирает горящий факел, активирует цель |
| `movable_box.gd` | ящик – толкается (RigidBody2D) |
| `checkpoint.gd` | чекпоинт – сохраняет позицию |
| `ice_platform.gd` | ледяная платформа – исчезает через 5 сек |
| `water_controller.gd` | управление водой – заглушка |

---

## 9. UI, МЕНЮ, ЭКРАН СМЕРТИ

### 9.1 `ui.tscn` + `ui.gd` (HUD)
- `HealthBar` – полоска здоровья.
- `DialogueBox` – панель диалогов.
- `MemoryLabel` – временные сообщения.
- `AbilityCooldown` – (скрыт, не используется).

**Методы `ui.gd`:**
- `_update_health(health, max_health)` – обновляет `HealthBar`.
- `_show_dialogue(speaker, text)` – показывает диалог, пауза.
- `_hide_dialogue()` – скрывает диалог, снимает паузу.
- `_show_memory(text, image)` – временное сообщение.

### 9.2 `EndScreen.tscn` + `EndScreen.gd`
- Кнопки Restart, Menu, Quit.
- В `_ready()` ставит игру на паузу, подключает сигналы.
- При рестарте снимает паузу и перезагружает `test.tscn`.

### 9.3 `MainMenu.tscn` + `main_menu.gd`
- Кнопки Play (загружает `water_level_1.tscn`), Options (открывает настройки), Quit.

### 9.4 `OptionsMenu.tscn` + `options_menu.gd`
- Регулировка громкости музыки (bus 1) и звуков (bus 2), переключение полноэкранного режима.

---

## 10. УРОВНИ (на примере `water_level_1.tscn`)

Сцена содержит:
- `Player`
- `UI`
- `TileMap` (2 слоя: ground, water)
- объекты (рычаги, плиты, факелы, чекпоинты, порталы)

**Скрипт `water_land.gd`:**
```gdscript
func _ready():
	LevelManager.register_level(self)
	LevelManager.set_checkpoint($Player.global_position)
	$Player.health_component.died.connect(_on_player_died, CONNECT_ONESHOT)

func _on_player_died():
	var end_screen = end_screen_scene.instantiate()
	add_child(end_screen)
```

---

## 11. НАСТРОЙКА КОЛЛИЗИЙ (СЛОИ И МАСКИ)

**Имена слоёв (Project Settings → Layer Names → 2D Physics):**

| Слой | Имя | Для кого |
|------|-----|----------|
| 1 | `player` | игрок |
| 2 | `interactable` | объекты (рычаги, факелы и т.д.) |
| 3 | `environment` | земля, вода, мосты |
| 4 | `enemies` | враги |
| 8 | `enemy_attack` | зона атаки врага |
| 9 | `player_attack` | зона атаки игрока |

| Узел | Layer | Mask |
|------|-------|------|
| Player (CharacterBody2D) | 1 | 3,4 |
| AttackComponent игрока | 9 | 4 |
| Enemy (CharacterBody2D) | 4 | 1,9 |
| AttackComponent врага | 8 | 1 |
| InteractArea игрока | – | 2 |
| Интерактивные объекты | 2 | – |

---

## 12. ЧТО РАБОТАЕТ, А ЧЕГО ЕЩЁ НЕТ (СТАТУС РЕАЛИЗАЦИИ)

### ✅ РАБОТАЕТ ПОЛНОСТЬЮ
- Движение, спринт, уклонение игрока
- Атака мечом (ЛКМ)
- Враг бегает за игроком и атакует
- Полоска здоровья игрока обновляется при получении урона
- Полоска здоровья врага (над головой) обновляется
- Смерть игрока → экран EndScreen (кнопки работают)
- Взаимодействие с рычагом, мостом, плитой давления, чекпоинтом
- Подбор факела, зажигание от костра, установка в подставку (активация цели)
- Главное меню, настройки звука и полноэкранного режима
- Переход по порталу на другой уровень (при наличии)

### ❌ НЕ ДОДЕЛАНО / ОТЛОЖЕНО
- **Способности** – вызов `ability_user.use(“water”)` закомментирован, ледяные платформы и заморозка врагов не задействованы.
- **Диалоги** – `DialogueManager` готов, но нет вызова `start_dialogue` нигде (нет боссов).
- **Осколки памяти** – объект есть, но не размещён на уровне.
- **Флешбэки** – не реализованы.
- **Понижение воды от плит** – есть `WaterController`, но не привязан и не настроен.
- **Анимации** – у игрока и врага нет спрайтов (нет вызовов `play()` в состояниях).
- **Враги других типов** – только теневой солдат.
- **Боссы** – отсутствуют.
- **Второй уровень** – портал есть, но сцены `next_level.tscn` нет.

---

## 13. ПОЯСНЕНИЯ КО ВСЕМ ФУНКЦИЯМ (КРАТКОЕ ОПИСАНИЕ)

Ниже перечислены ВСЕ функции из скриптов, сгруппированные по файлам, и кратко указано, что они делают. Это поможет быстро ориентироваться.

### GameManager
- `_ready()` – включает `process_mode = PROCESS_MODE_ALWAYS`
- `update_health()` – эмитит сигнал `health_changed`
- `start_ability_cooldown()` – эмитит `ability_cooldown_started`
- `display_dialogue()` – эмитит `show_dialogue`
- `close_dialogue()` – эмитит `hide_dialogue`
- `display_memory()` – эмитит `show_memory`

### LevelManager
- `register_level()` – запоминает текущий уровень
- `register_player()` – запоминает игрока
- `set_checkpoint()` – сохраняет позицию
- `respawn()` – воскрешает игрока на чекпоинте

### DialogueManager
- `load_all_dialogues()` – загружает JSON диалоги из папки
- `start_dialogue()` – начинает диалог по ключу
- `show_current_line()` – показывает текущую реплику
- `next_line()` – следующая реплика
- `close_dialogue()` – закрывает диалог

### SaveManager
- `save_game()` – сохраняет словарь в JSON
- `load_game()` – загружает словарь из JSON

### HealthComponent
- `take_damage()` – наносит урон, включает неуязвимость, при смерти эмитит `died`
- `heal()` – лечит
- `reset()` – сбрасывает здоровье и неуязвимость

### AttackComponent
- `activate()` – временно включает зону атаки
- `_on_body_entered()` – вызывает `take_damage` у задетого тела

### AbilityUser
- `can_use()` – проверяет перезарядку
- `use()` – активирует способность, запускает перезарядку
- `_get_ability()` – ищет ресурс способности
- `update()` – обновляет таймеры перезарядки

### State
- `enter()`, `exit()`, `update()`, `physics_update()`, `handle_input()` – точки входа для дочерних состояний

### StateMachine
- `_ready()` – инициализирует дочерние состояния
- `change_to()` – переключает состояние
- `_process()`, `_physics_process()`, `_input()` – делегируют текущему состоянию

### Состояния игрока (каждое)
- `enter()` – что делать при входе в состояние
- `physics_update()` – логика в физическом процессе (движение, атака)
- `update()` – обычно не используется

### Player (player.gd)
- `_ready()` – инициализация, регистрация, подключение сигналов
- `_process()` – обновляет способности (ability_user)
- `_physics_process()` – движение
- `_input()` – обработка клавиш атаки, уклонения, взаимодействия
- `_on_ability_used()` – эффекты способностей (закомментирована)
- `freeze_nearby_enemies()` – замораживает врагов вокруг
- `try_create_ice_platform()` – создаёт ледяную платформу на воде
- `_on_death()` – реакция на смерть
- `_on_health_changed()` – обновляет UI
- `_on_interactable_entered()` – запоминает объект для взаимодействия
- `_on_interactable_exited()` – забывает объект
- `take_damage()` – обёртка для компонента здоровья
- `pickup_torch()`, `light_torch()`, `place_torch()` – управление факелом

### ShadowSoldier (враг)
- `_ready()` – инициализация, создание полоски здоровья
- `_physics_process()` – движение к игроку, атака
- `attack()` – активирует зону атаки
- `_on_player_detected()` – не используется
- `take_damage()` – передача урона компоненту
- `freeze()` – временная заморозка
- `_on_health_changed()` – обновляет полоску здоровья

### Объекты (lever, bridge, pressure_plate и т.д.)
- `interact()` – основное действие (переключение, зажигание, активация)
- `activate(state)` – для моста, водного контроллера, подставки (вызывается из рычага или плиты)
- `_on_body_entered()`, `_on_body_exited()` – для плит и триггеров

### UI (ui.gd)
- `_ready()` – подключение к сигналам GameManager
- `_update_health()` – обновление полоски здоровья
- `_start_ability_cooldown()` – (закомментирована)
- `_show_dialogue()` – показ диалога, пауза
- `_hide_dialogue()` – скрытие диалога, снятие паузы
- `_show_memory()` – показ временного сообщения

### EndScreen
- `_ready()` – пауза, подключение кнопок
- `_on_restart_button_pressed()` – перезапуск уровня
- `_on_main_menu_button_pressed()` – главное меню
- `_on_quit_button_pressed()` – выход

### MainMenu
- `_ready()` – оконный режим, музыка
- `_on_play_button_pressed()` – загружает `water_level_1.tscn`
- `_on_options_button_pressed()` – открывает окно настроек
- `_on_quit_button_pressed()` – выход

### OptionsMenu
- `_ready()`, `update_options()` – обновление состояния настроек
- `get_volume_percent()` – конвертация dB в линейное значение
- `_on_window_mode_button_pressed()` – переключение режима экрана
- `_on_sfx_slider_value_changed()`, `_on_music_slider_value_changed()` – регулировка громкости
- `_on_back_button_pressed()` – закрытие окна

### water_land.gd (уровень)
- `_ready()` – регистрация уровня, чекпоинт, подключение сигнала смерти игрока
- `_on_player_died()` – создание экрана смерти
