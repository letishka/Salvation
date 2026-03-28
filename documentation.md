# Документация по коду проекта «Salvation» (текущая реализация) НАПИСАНО ДИПСИКОМ

## Обзор

Проект «Salvation» — action-adventure с видом сверху, реализованный на Godot 4.6.1. Игровой процесс построен на компонентной архитектуре, конечном автомате для управления состояниями игрока, глобальных менеджерах и ресурсах способностей. В данной документации описан существующий код и его организация, чтобы новые разработчики могли быстро понять структуру проекта.

---

## 1. Организация файлов

```
res://
├── addons/                      # Плагины
├── assets/                      # Все медиа-ресурсы
│   ├── graphics/                # Изображения
│   │   ├── characters/          # Спрайты игрока, врагов
│   │   ├── objects/             # Спрайты объектов (рычаги, факелы)
│   │   ├── ui/                  # Иконки для интерфейса
│   │   └── tilesets/            # Тайлы уровней
│   └── audio/                   # Звуки и музыка
│       ├── music/
│       └── sounds/
├── autoload/                    # Автозагрузки (ссылки на менеджеры)
│   ├── GameManager.gd
│   ├── LevelManager.gd
│   ├── SaveManager.gd
│   └── DialogueManager.gd
├── data/                        # Данные игры
│   ├── abilities/               # Ресурсы способностей (.tres)
│   │   ├── ability_resource.gd  # Базовый класс ресурса
│   │   └── water_ability.tres   # Конкретная способность
│   └── dialogues/               # JSON-файлы диалогов
│       └── bridge_soldier.json
├── scenes/                      # Сцены
│   ├── characters/
│   │   ├── player/              # Сцена игрока
│   │   └── enemies/             # Сцены врагов
│   ├── levels/                  # Уровни
│   ├── objects/                 # Объекты окружения (рычаги, плиты и т.д.)
│   └── ui/                      # Интерфейс (главное меню, HUD)
├── scripts/                     # Все скрипты
│   ├── components/              # Переиспользуемые компоненты
│   ├── managers/                # Глобальные менеджеры
│   ├── states/                  # Конечный автомат
│   │   └── player_states/       # Состояния игрока
│   ├── objects/                 # Скрипты интерактивных объектов
│   └── utils/                   # Вспомогательные утилиты
└── project.godot
```

---

## 2. Глобальные менеджеры (автозагрузки)

Все менеджеры расположены в `scripts/managers/` и загружаются как синглтоны через файлы-ссылки в `autoload/`. Они доступны из любого скрипта по имени.

### 2.1. GameManager (`scripts/managers/game_manager.gd`)

**Роль:** центральный узел связи между игроком, UI и другими системами.

**Сигналы:**
- `health_changed(health, max_health)` — уведомляет UI об изменении здоровья.
- `ability_cooldown_started(ability_id, remaining)` — оповещает о начале перезарядки способности.
- `show_dialogue(speaker, text)` — отобразить диалог.
- `hide_dialogue` — скрыть диалоговое окно.
- `show_memory(text, image)` — показать сообщение памяти.

**Переменные:**
- `player: Node` — ссылка на игрока (устанавливается игроком при старте).

**Методы:**
- `update_health(health, max_health)` — испускает `health_changed`.
- `start_ability_cooldown(ability_id, remaining)` — испускает `ability_cooldown_started`.
- `display_dialogue(speaker, text)` — испускает `show_dialogue`.
- `close_dialogue()` — испускает `hide_dialogue`.
- `display_memory(text, image)` — испускает `show_memory`.

### 2.2. LevelManager (`scripts/managers/level_manager.gd`)

**Роль:** управление чекпоинтами и перезагрузкой игрока.

**Переменные:**
- `current_level: Node` — текущая сцена уровня.
- `player: Node` — ссылка на игрока.
- `checkpoint: Vector2` — позиция последнего чекпоинта.

**Методы:**
- `register_level(level)` — вызывается уровнем для регистрации.
- `register_player(p)` — вызывается игроком для установки ссылки.
- `set_checkpoint(pos)` — сохраняет чекпоинт.
- `respawn()` — перемещает игрока в чекпоинт, сбрасывает здоровье, возобновляет обработку ввода и переводит в состояние `Idle`.

### 2.3. SaveManager (`scripts/managers/save_manager.gd`)

**Роль:** заготовка для системы сохранений. Реализует базовую запись/чтение JSON.

**Константы:**
- `SAVE_PATH = "user://savegame.save"`

**Методы:**
- `save_game(data)` — сохраняет словарь в файл.
- `load_game()` — загружает словарь из файла (или пустой словарь).

### 2.4. DialogueManager (`scripts/managers/dialogue_manager.gd`)

**Роль:** загрузка и управление диалогами из JSON.

**Переменные:**
- `_dialogues: Dictionary` — все загруженные диалоги (ключ → массив реплик).
- `_current_key`, `_current_line`, `_is_active` — состояние текущего диалога.

**Методы:**
- `load_all_dialogues()` — сканирует папку `data/dialogues/` и загружает все JSON.
- `start_dialogue(key)` — начинает диалог по ключу.
- `show_current_line()` — отображает текущую реплику через `GameManager.display_dialogue`.
- `next_line()` — переходит к следующей реплике или закрывает диалог.
- `close_dialogue()` — завершает диалог.

---

## 3. Компоненты

Компоненты — дочерние узлы, реализующие отдельные аспекты поведения. Используются в сценах игрока, врагов и боссов.

### 3.1. HealthComponent (`scripts/components/health_component.gd`)

**Роль:** управление здоровьем, неуязвимостью, сигналами.

**Экспортируемые параметры:**
- `max_health: int`
- `invincible_duration: float`

**Переменные:**
- `current_health: int`
- `is_invincible: bool`

**Сигналы:**
- `health_changed(current, max)`
- `died`

**Методы:**
- `take_damage(amount)` — наносит урон, если не в режиме неуязвимости; после урона включает неуязвимость на `invincible_duration` секунд.
- `heal(amount)` — восстанавливает здоровье.
- `reset()` — сбрасывает здоровье до `max_health` и снимает неуязвимость.

### 3.2. AttackComponent (`scripts/components/attack_component.gd`)

**Роль:** зона атаки, временно активная.

**Экспортируемые параметры:**
- `damage: int`
- `active_time: float`

**Переменные:**
- `_is_active: bool`

**Методы:**
- `activate()` — включает мониторинг на `active_time` секунд, затем выключает. При входе тела вызывает `body.take_damage(damage)`, если у тела есть такой метод.

### 3.3. AbilityUser (`scripts/components/ability_user.gd`)

**Роль:** управление способностями игрока (ресурсы, перезарядка).

**Экспортируемые параметры:**
- `abilities: Array[AbilityResource]` — список ресурсов способностей.

**Переменные:**
- `_cooldowns: Dictionary` — ability_id → оставшееся время.

**Сигналы:**
- `ability_used(ability_id)`
- `cooldown_started(ability_id, remaining)`

**Методы:**
- `can_use(ability_id)` — проверяет, не на перезарядке ли способность.
- `use(ability_id)` — если доступна, устанавливает перезарядку и испускает сигнал.
- `update(delta)` — обновляет таймеры перезарядки (вызывается в `_process` владельца).

---

## 4. Конечный автомат (State Machine)

### 4.1. State (`scripts/states/state.gd`)

Базовый класс для всех состояний. Хранит ссылки на `actor` (владельца) и `state_machine`.

**Методы для переопределения:**
- `enter()`, `exit()`, `update(delta)`, `physics_update(delta)`, `handle_input(event)`

### 4.2. StateMachine (`scripts/states/state_machine.gd`)

**Экспортируемые параметры:**
- `initial_state: State`

**Переменные:**
- `current_state: State`

**Методы:**
- `_ready()` — инициализирует все дочерние состояния, передавая им `actor` и `state_machine`, затем входит в `initial_state`.
- `change_to(state_name)` — выходит из текущего состояния и входит в новое.

### 4.3. Состояния игрока (`scripts/states/player_states/`)

Все состояния наследуют `State` и реализуют специфическое поведение:

- **Idle** (`idle.gd`) — без движения; при появлении ввода переходит в `Move`.
- **Move** (`move.gd`) — движение с учётом бега; при отсутствии ввода возвращается в `Idle`.
- **Attack** (`attack.gd`) — активирует `AttackComponent`, ждёт `attack_duration`, затем переходит в `Idle`.
- **Dodge** (`dodge.gd`) — устанавливает флаг `is_dodging` и `is_invincible`, выполняет рывок, ждёт `dodge_duration`, затем снимает флаги и переходит в `Idle`.
- **Ability** (`ability.gd`) — заглушка; можно использовать для анимации способности.
- **Hit** (`hit.gd`) — короткая задержка при получении урона, затем `Idle`.
- **Dead** (`dead.gd`) — отключает обработку ввода и физику, ждёт 1 секунду, затем вызывает `LevelManager.respawn()`.

---

## 5. Игрок (`scenes/characters/player/player.tscn` и `player.gd`)

### 5.1. Структура сцены

- Корень: `CharacterBody2D`
- Дочерние узлы:
  - `CollisionShape2D` — физическая форма.
  - `Sprite2D` — основной спрайт.
  - `TorchSprite` (Sprite2D) — отображение факела в руках (скрыт по умолчанию).
  - `Camera2D` — камера.
  - `HealthComponent` — компонент здоровья.
  - `AttackComponent` — компонент атаки.
  - `AbilityUser` — компонент способностей.
  - `StateMachine` — автомат с состояниями.
  - `InteractArea` (Area2D) — зона взаимодействия с объектами.

### 5.2. Скрипт `player.gd`

**Экспортируемые параметры:**
- `speed`, `sprint_speed`, `attack_duration`, `dodge_duration`

**Переменные:**
- `current_interactable: Node` — последний обнаруженный интерактивный объект.
- `is_dodging: bool` — флаг уклонения (используется в состояниях).
- `has_torch`, `torch_lit` — состояние факела.

**Ключевые методы:**
- `_ready()` — добавляет игрока в группу `"player"`, регистрируется в `LevelManager`, подключает сигналы компонентов, скрывает `TorchSprite`.
- `_process(delta)` — вызывает `ability_user.update(delta)`.
- `_input(event)` — обрабатывает атаку, уклонение, способность и взаимодействие (E). При взаимодействии вызывает `current_interactable.interact()`.
- `_on_ability_used(ability_id)` — реализует эффекты способностей. Для `"water"` вызывает `freeze_nearby_enemies()` и `try_create_ice_platform()`.
- `freeze_nearby_enemies()` — ищет всех врагов в группе `"enemies"` и вызывает у них `freeze(2.0)`.
- `try_create_ice_platform()` — проверяет тайл под игроком на наличие кастомного свойства `water`; если есть, создаёт ледяную платформу.
- `pickup_torch()`, `light_torch()`, `place_torch()` — управление факелом (изменяют состояние и спрайт).
- `take_damage(amount)` — обёртка для `health_component.take_damage`.
- `_on_interactable_entered(area)` — получает родителя области и, если у него есть метод `interact`, сохраняет его как `current_interactable`. Отсекает случай, когда родитель — сам игрок.
- `_on_interactable_exited(area)` — сбрасывает ссылку, если вышли из той же области.

---

## 6. Враги и боссы - пока что реализации нет, можно на будущее

### 6.1. ShadowSoldier (`scripts/characters/enemies/shadow_soldier.gd`)

Базовый враг. Сцена содержит `CharacterBody2D`, `CollisionShape2D`, `Sprite2D`, `HealthComponent`, `AttackComponent`, `DetectionArea` (Area2D для обнаружения игрока).

**Экспортируемые параметры:**
- `speed`, `attack_cooldown`

**Переменные:**
- `player: Node` — ссылка на игрока.
- `can_attack: bool`, `is_frozen: bool`.

**Методы:**
- `_ready()` — добавляет в группу `"enemies"`, находит игрока через группу, подключает сигналы.
- `_physics_process(delta)` — движется к игроку, если не заморожен; при достаточном приближении и возможности атакует.
- `attack()` — активирует `AttackComponent`, ждёт `attack_cooldown`.
- `freeze(duration)` — временно останавливает движение.
- `_on_player_detected(body)` — обновляет ссылку на игрока.

### 6.2. BridgeSoldier (`scripts/characters/enemies/bridge_soldier.gd`)

Босс, наследующий `CharacterBody2D`. Имеет те же компоненты, плюс атаку прыжком.

**Экспортируемые параметры:**
- `speed`, `attack_cooldown`, `jump_cooldown`

**Переменные:**
- `player`, `can_attack`, `can_jump`, `phase` (0,1,2)

**Методы:**
- `jump()` — телепортируется над игроком, создаёт зону поражения, наносит урон, ждёт `jump_cooldown`.
- `_on_health_changed(current, max)` — отслеживает фазы: при 70% и 40% HP вызывает спавн солдат и диалог.
- `spawn_soldiers(count)` — создаёт указанное количество `ShadowSoldier` рядом с боссом.
- `_on_death()` — запускает финальный диалог, выдаёт игроку способность воды, удаляется.

---

## 7. Интерактивные объекты

Все объекты, с которыми можно взаимодействовать, имеют метод `interact()`. Они обнаруживаются через `InteractArea` игрока.

### 7.1. Lever (`scripts/objects/lever.gd`)

`StaticBody2D`. Содержит `Sprite2D` с двумя кадрами.

**Экспортируемые параметры:**
- `target_node_path: NodePath` — объект, который активируется.
- `active: bool` — состояние.

**Метод `interact()`** — переключает `active`, меняет спрайт и вызывает `activate(active)` у цели (если есть).

### 7.2. PressurePlate (`scripts/objects/pressure_plate.gd`)

`Area2D`. Реагирует на тела из групп `player` или `movable`.

**Экспортируемые параметры:**
- `target_node_path`
- `stay_pressed: bool` — остаётся ли активной после ухода тела.

**Переменная:** `_activated: bool`

**Методы:**
- `_on_body_entered(body)` — при входе тела активирует цель, если ещё не активирована.
- `_on_body_exited(body)` — если `stay_pressed == false`, проверяет, есть ли ещё тела на плите; если нет, деактивирует.

### 7.3. Bridge (`scripts/objects/bridge.gd`)

`StaticBody2D`. Представляет подъёмный мост.

**Экспортируемые параметры:**
- `up_position`, `down_position` — позиции в поднятом/опущенном состоянии.
- `up_collision_disabled` — отключать ли коллизию при подъёме.

**Метод `activate(state)`** — перемещает мост и управляет коллизией.

### 7.4. MemoryShard (`scripts/objects/memory_shard.gd`)

`Area2D`. При касании игроком:
- Вызывает `GameManager.display_memory(text, image)`
- Лечит игрока на 20 HP
- Удаляется.

**Экспортируемые параметры:**
- `memory_text`, `memory_image`

### 7.5. TorchPickup (`scripts/objects/torch_pickup.gd`)

`Area2D`. При касании игроком:
- Вызывает `player.pickup_torch()`
- Удаляется.

### 7.6. TorchHolder (`scripts/objects/torch_holder.gd`)

`StaticBody2D`. Подставка для факела.

**Экспортируемые параметры:**
- `target_node_path` — что активируется при установке горящего факела.
- `is_lit` (переменная) — горит ли подставка.

**Метод `interact()`** — если у игрока есть зажжённый факел, забирает его, зажигает подставку, активирует цель.

### 7.7. Bonfire (`scripts/objects/bonfire.gd`)

`StaticBody2D`. При взаимодействии:
- Вызывает `player.light_torch()`, если у игрока есть факел и он не зажжён.

### 7.8. MovableBox (`scripts/objects/movable_box.gd`)

`RigidBody2D`. Добавляет себя в группу `movable`. Имеет метод `push(direction)` для приложения импульса.

### 7.9. Checkpoint (`scripts/objects/checkpoint.gd`)

`Area2D`. При входе игрока вызывает `LevelManager.set_checkpoint(global_position)`.

### 7.10. IcePlatform (`scripts/objects/ice_platform.gd`)

`StaticBody2D`. При создании запускает таймер на 5 секунд, после чего удаляется.

---

## 8. Ресурс способности (`data/abilities/ability_resource.gd`)

Базовый класс для ресурсов способностей. Поля:
- `id: String`
- `display_name: String`
- `icon: Texture`
- `cooldown: float`
- `mana_cost: int`
- `effect_scene: PackedScene`

Пример создания конкретной способности — `water_ability.tres` — это экземпляр `AbilityResource` с заполненными полями.

---

## 9. UI - Ксюша Р., нужна редакция

### 9.1. HUD (`scenes/ui/ui.tscn` и `ui.gd`)

Сцена содержит:
- `HealthBar` (TextureProgressBar)
- `AbilityCooldown` (TextureProgressBar)
- `DialogueBox` (Panel) с `SpeakerLabel`, `TextLabel`, `NextButton`
- `MemoryLabel` (Label)

Скрипт `ui.gd` подключается к сигналам `GameManager` и обновляет элементы. При показе диалога игра ставится на паузу (`get_tree().paused = true`). Кнопка `NextButton` вызывает `DialogueManager.next_line()`.

### 9.2. Главное меню (`scenes/ui/MainMenu.tscn` и `main_menu.gd`)

Содержит кнопки: Play, Options, Quit. При нажатии Play загружает тестовый уровень. Options загружает сцену настроек.

### 9.3. Меню настроек (`scenes/ui/OptionsMenu.tscn` и `options_menu.gd`)

Позволяет переключать полноэкранный режим и регулировать громкость музыки (bus 1) и звуков (bus 2).

---

## 10. Уровни

Уровни (например, `water_land.tscn`) имеют корневой узел `Node2D` и включают:
- `TileMap` (с кастомными данными для воды)
- Экземпляр `Player`
- `Camera2D` (часто прикреплена к игроку)
- Различные объекты (рычаги, плиты, осколки, чекпоинты, враги)

Скрипт уровня (например, `water_land.gd`) вызывает `LevelManager.register_level(self)` и устанавливает начальный чекпоинт.

---

## 11. Автозагрузки (`autoload/`)

В папке `autoload/` находятся четыре файла, каждый из которых содержит единственную строку `extends`:

- `GameManager.gd` → `extends "res://scripts/managers/game_manager.gd"`
- `LevelManager.gd` → `extends "res://scripts/managers/level_manager.gd"`
- `SaveManager.gd` → `extends "res://scripts/managers/save_manager.gd"`
- `DialogueManager.gd` → `extends "res://scripts/managers/dialogue_manager.gd"`

Они зарегистрированы в настройках проекта как автозагрузки, что делает менеджеры доступными глобально.

---

## 12. Заключение

Данная архитектура обеспечивает модульность и масштабируемость. Основные элементы:
- **Компоненты** — переиспользуемые блоки поведения.
- **Конечный автомат** — чистое управление состояниями игрока.
- **Менеджеры** — глобальная связь и координация.
- **Интерактивные объекты** — единый интерфейс через метод `interact()`.

Новые разработчики могут легко найти нужный код, следуя структуре папок, и понять взаимодействие компонентов по сигналам и группам.
