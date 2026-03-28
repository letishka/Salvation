# Полная документация проекта «Salvation» НАПИСАНО ДИПСИКОМ

## Введение

Эта документация охватывает архитектуру, код и настройку игры «Salvation» — action-adventure с видом сверху, разрабатываемой на Godot 4.6.1. Проект использует компонентный подход, конечный автомат (State Machine) и глобальные менеджеры для масштабируемости. Документ предназначен для разработчиков, которые будут поддерживать и расширять игру.

---

## 1. Структура проекта

```
res://
├── addons/                      # Плагины (пусто)
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

## 2. Система компонентов

Компоненты — это узлы, которые добавляют определённую функциональность игроку или врагам. Они подключаются как дочерние узлы и работают через сигналы.

### 2.1. HealthComponent (`scripts/components/health_component.gd`)

**Назначение:** управление здоровьем, неуязвимостью, сигналами о смерти.

**Свойства:**
- `max_health` (int) – максимальное здоровье.
- `invincible_duration` (float) – время неуязвимости после получения урона.
- `current_health` (int) – текущее здоровье.

**Сигналы:**
- `health_changed(current, max)` – вызывается при изменении здоровья.
- `died` – вызывается при смерти.

**Методы:**
- `take_damage(amount)` – наносит урон, если не в режиме неуязвимости.
- `heal(amount)` – восстанавливает здоровье.
- `reset()` – сбрасывает здоровье до максимума, снимает неуязвимость.

### 2.2. AttackComponent (`scripts/components/attack_component.gd`)

**Назначение:** зона атаки, которая на время становится активной и наносит урон.

**Свойства:**
- `damage` (int) – урон за один удар.
- `active_time` (float) – время активности зоны атаки.

**Методы:**
- `activate()` – делает зону мониторинга активной на `active_time` секунд. При столкновении с любым телом, имеющим метод `take_damage`, наносит урон.

### 2.3. AbilityUser (`scripts/components/ability_user.gd`)

**Назначение:** управление способностями игрока (ресурсы, перезарядка).

**Свойства:**
- `abilities` (Array[AbilityResource]) – список доступных способностей.
- `_cooldowns` (Dictionary) – хранит оставшееся время перезарядки для каждой способности.

**Сигналы:**
- `ability_used(ability_id)` – вызывается при активации способности.
- `cooldown_started(ability_id, remaining)` – вызывается при начале перезарядки (в демке не используется).

**Методы:**
- `can_use(ability_id)` – возвращает true, если способность не на перезарядке.
- `use(ability_id)` – активирует способность, если она доступна; устанавливает перезарядку и испускает сигнал.
- `update(delta)` – обновляет таймеры перезарядки; вызывается в `_process` владельца.

---

## 3. Конечный автомат (State Machine)

Состояния позволяют разделить логику поведения игрока на изолированные классы.

### 3.1. State (`scripts/states/state.gd`)

Базовый класс для всех состояний. Содержит ссылки на `actor` (владельца) и `state_machine`.

Методы для переопределения:
- `enter()` – вызывается при входе в состояние.
- `exit()` – при выходе.
- `update(delta)` – в `_process`.
- `physics_update(delta)` – в `_physics_process`.
- `handle_input(event)` – для обработки ввода.

### 3.2. StateMachine (`scripts/states/state_machine.gd`)

Управляет переключением состояний. Свойство `initial_state` задаёт начальное состояние. В `_ready` автомат инициализирует все дочерние состояния, передавая им ссылки на `actor` и `state_machine`. Метод `change_to(state_name)` переключает состояния.

### 3.3. Состояния игрока (`scripts/states/player_states/`)

Каждое состояние реализовано в отдельном файле:

- **Idle** – ожидание ввода движения.
- **Move** – движение с учётом бега.
- **Attack** – активация `AttackComponent` и задержка.
- **Dodge** – рывок, неуязвимость.
- **Ability** – использование способности (заглушка, можно анимировать).
- **Hit** – получение урона (небольшая задержка).
- **Dead** – отключение ввода, вызов `LevelManager.respawn()`.

---

## 4. Глобальные менеджеры (автозагрузки)

Менеджеры доступны из любого места кода как синглтоны. Они хранятся в `scripts/managers/`, а в `autoload/` лежат файлы-ссылки.

### 4.1. GameManager (`scripts/managers/game_manager.gd`)

Главный менеджер, связывающий игрока, UI и другие системы.

**Сигналы:**
- `health_changed(health, max_health)`
- `ability_cooldown_started(ability_id, remaining)`
- `show_dialogue(speaker, text)`
- `hide_dialogue`
- `show_memory(text, image)`

**Поля:**
- `player` (Node) – ссылка на игрока (устанавливается в `player.gd`).

**Методы-обёртки:**
- `update_health()`, `start_ability_cooldown()`, `display_dialogue()`, `close_dialogue()`, `display_memory()` – просто испускают соответствующие сигналы.

### 4.2. LevelManager (`scripts/managers/level_manager.gd`)

Управляет текущим уровнем, чекпоинтами и респауном.

**Поля:**
- `current_level` (Node) – ссылка на узел уровня.
- `player` (Node) – ссылка на игрока.
- `checkpoint` (Vector2) – позиция последнего чекпоинта.

**Методы:**
- `register_level(level)` – вызывается уровнем в `_ready`.
- `register_player(p)` – вызывается игроком.
- `set_checkpoint(pos)` – устанавливает чекпоинт.
- `respawn()` – возвращает игрока на чекпоинт, восстанавливает здоровье и переводит в состояние Idle.

### 4.3. SaveManager (`scripts/managers/save_manager.gd`)

Заготовка для сохранений (пока реализована базовая запись/чтение JSON).

### 4.4. DialogueManager (`scripts/managers/dialogue_manager.gd`)

Загружает диалоги из JSON и управляет их отображением.

**Методы:**
- `load_all_dialogues()` – читает все JSON из `data/dialogues/`.
- `start_dialogue(key)` – начинает диалог по ключу.
- `next_line()` – показывает следующую реплику.
- `close_dialogue()` – закрывает диалог.

Диалоги должны иметь структуру:
```json
{
	"bridge_soldier_phase1": [
		{"speaker": "Солдат", "text": "ТЫ-Ы-Ы!.."}
	]
}
```

---

## 5. Персонаж игрока

### 5.1. Сцена `player.tscn`

**Корневой узел:** `CharacterBody2D` со скриптом `player.gd`.

**Дочерние узлы:**
- `CollisionShape2D` – коллизия игрока.
- `Sprite2D` – основной спрайт.
- `TorchSprite` (Sprite2D) – спрайт факела в руке (скрыт по умолчанию).
- `Camera2D` – камера с сглаживанием.
- `HealthComponent` – компонент здоровья.
- `AttackComponent` – зона атаки (с `CollisionShape2D`).
- `AbilityUser` – компонент способностей.
- `StateMachine` – автомат с дочерними состояниями (Idle, Move, Attack, Dodge, Ability, Hit, Dead).
- `InteractArea` (Area2D) – зона обнаружения интерактивных объектов (с `CollisionShape2D`).

### 5.2. Скрипт `player.gd`

**Экспортируемые переменные:**
- `speed`, `sprint_speed` – скорость движения.
- `attack_duration`, `dodge_duration` – длительность анимаций.

**Ключевые методы:**
- `_ready()` – регистрирует игрока в `LevelManager`, подключает сигналы, скрывает факел.
- `_process(delta)` – вызывает `ability_user.update(delta)`.
- `_input(event)` – обрабатывает ввод: атаку, уклонение, способность, взаимодействие. При взаимодействии вызывает `current_interactable.interact()`.
- `_on_ability_used(ability_id)` – реализует эффекты способностей (пока только вода).
- `freeze_nearby_enemies()` – замораживает врагов в радиусе.
- `try_create_ice_platform()` – создаёт ледяную платформу, если игрок стоит на тайле с кастомным свойством `water`.
- `pickup_torch()`, `light_torch()`, `place_torch()` – управление факелом (для головоломок).
- `take_damage(amount)` – обёртка для `HealthComponent.take_damage`.
- `_on_interactable_entered(area)` – находит интерактивный объект (родитель области) и сохраняет в `current_interactable`, если у того есть метод `interact`. Отсекает случай, когда родитель – сам игрок.

---

## 6. Враги

### 6.1. ShadowSoldier (`scripts/characters/enemies/shadow_soldier.gd`)

Базовый враг с движением к игроку и атакой.

**Свойства:**
- `speed` – скорость.
- `attack_cooldown` – задержка между атаками.
- `is_frozen` – заморожен ли.

**Методы:**
- `attack()` – активирует `AttackComponent`.
- `freeze(duration)` – замораживает врага на время.
- `_on_player_detected(body)` – сохраняет ссылку на игрока.

### 6.2. BridgeSoldier (`scripts/characters/enemies/bridge_soldier.gd`)

Босс с двумя фазами и дополнительной атакой «прыжок». При смерти выдаёт игроку способность воды.

---

## 7. Интерактивные объекты

Все объекты, с которыми можно взаимодействовать (рычаги, плиты, осколки, подставки), должны иметь метод `interact()` и находиться в группе или иметь слой коллизии, который обнаруживается `InteractArea` игрока.

### 7.1. Lever (`scripts/objects/lever.gd`)

**Свойства:**
- `target_node_path` – путь к объекту, который активируется.
- `active` – текущее состояние.

**Метод `interact()`** – переключает состояние, меняет спрайт и вызывает `activate(new_state)` у цели.

### 7.2. PressurePlate (`scripts/objects/pressure_plate.gd`)

Реагирует на тела в группе `player` или `movable`. При входе активирует цель, при выходе (если `stay_pressed == false`) деактивирует.

### 7.3. Bridge (`scripts/objects/bridge.gd`)

**Свойства:**
- `up_position`, `down_position` – позиции в поднятом/опущенном состоянии.
- `up_collision_disabled` – отключать ли коллизию при подъёме.

**Метод `activate(state)`** – перемещает мост и включает/выключает коллизию.

### 7.4. MemoryShard (`scripts/objects/memory_shard.gd`)

При касании игроком восстанавливает 20 HP и вызывает `GameManager.display_memory()`.

### 7.5. TorchPickup (`scripts/objects/torch_pickup.gd`)

При касании вызывает `player.pickup_torch()` и удаляется.

### 7.6. TorchHolder (`scripts/objects/torch_holder.gd`)

**Свойства:**
- `target_node_path` – что активируется при установке горящего факела.
- `is_lit` – горит ли факел на подставке.

**Метод `interact()`** – если у игрока есть зажжённый факел, забирает его, зажигает подставку и активирует цель.

### 7.7. Bonfire (`scripts/objects/bonfire.gd`)

При взаимодействии зажигает факел игрока, если тот его поднял.

### 7.8. MovableBox (`scripts/objects/movable_box.gd`)

Ящик-толкатель. Использует физику `RigidBody2D`. Добавляет себя в группу `movable`. Метод `push(direction)` применяет импульс.

### 7.9. Checkpoint (`scripts/objects/checkpoint.gd`)

При входе игрока вызывает `LevelManager.set_checkpoint(global_position)`.

### 7.10. IcePlatform (`scripts/objects/ice_platform.gd`)

Создаётся способностью «Вода», через 5 секунд исчезает.

---

## 8. Интерфейс пользователя (UI)

### 8.1. Сцена `ui.tscn`

**Узлы:**
- `HealthBar` (TextureProgressBar)
- `AbilityCooldown` (TextureProgressBar)
- `DialogueBox` (Panel) с `SpeakerLabel`, `TextLabel`, `NextButton`
- `MemoryLabel` (Label)

Скрипт `ui.gd` подписывается на сигналы `GameManager` и обновляет элементы.

### 8.2. Главное меню (`scenes/ui/MainMenu.tscn`)

Содержит кнопки «Новая игра», «Настройки», «Выход». При нажатии настройки загружают сцену `OptionsMenu.tscn`.

### 8.3. Меню настроек (`scenes/ui/OptionsMenu.tscn`)

Позволяет переключать полноэкранный режим и регулировать громкость музыки и звуков.

---

## 9. Уровни

Уровни — сцены с корневым узлом `Node2D`. Они должны содержать:
- `TileMap` (с возможностью кастомных данных для воды).
- Экземпляр `Player`.
- Камеру (можно привязать к игроку).
- Интерактивные объекты, врагов, чекпоинты.

В скрипте уровня (например, `water_land.gd`) вызывается `LevelManager.register_level(self)` и устанавливается начальный чекпоинт.

---

## 10. Ресурс способности (AbilityResource)

Базовый класс `AbilityResource` лежит в `data/abilities/ability_resource.gd`. Он содержит:
- `id` (String) – уникальный идентификатор.
- `display_name` (String)
- `icon` (Texture)
- `cooldown` (float)
- `mana_cost` (int)
- `effect_scene` (PackedScene)

Для создания новой способности:
1. Создайте новый ресурс в папке `data/abilities/`, выбрав `AbilityResource`.
2. Заполните поля.
3. Добавьте этот ресурс в массив `abilities` узла `AbilityUser` игрока.

---

## 11. Настройка проекта

### 11.1. Input Map

В Project Settings → Input Map добавьте действия:

| Action         | Key/Button        |
|----------------|-------------------|
| move_left      | A                 |
| move_right     | D                 |
| move_up        | W                 |
| move_down      | S                 |
| sprint         | Shift             |
| attack         | Left Mouse Button |
| dodge          | Space             |
| use_ability    | Q                 |
| interact       | E                 |
| ui_cancel      | Escape            |

### 11.2. Слои коллизий

В Project Settings → Layer Names задайте:

- Слой 1: `player`
- Слой 2: `interactable`
- Слой 3: `movable`

Настройте узлы:
- **Player** (CharacterBody2D): Layer = 1, Mask = 1,3.
- **InteractArea** (Area2D у игрока): Layer = 0, Mask = 2.
- **Интерактивные объекты** (StaticBody2D или Area2D): Layer = 2, Mask = 1 (если нужно, чтобы игрок их касался).
- **Ящики** (RigidBody2D): Layer = 3, Mask = 1.

### 11.3. Автозагрузки

В Project Settings → Autoload добавьте:

| Name            | Path                        |
|-----------------|-----------------------------|
| GameManager     | res://autoload/GameManager.gd |
| LevelManager    | res://autoload/LevelManager.gd |
| SaveManager     | res://autoload/SaveManager.gd |
| DialogueManager | res://autoload/DialogueManager.gd |

Файлы в `autoload/` должны содержать только ссылки на соответствующие менеджеры, например:

```gdscript
extends "res://scripts/managers/game_manager.gd"
```

---

## 12. Порядок действий для создания нового уровня

1. Создайте новую сцену с корневым узлом `Node2D`.
2. Добавьте `TileMap` и настройте тайлы.
3. Создайте скрипт уровня (например, `new_level.gd`) и добавьте в `_ready`:
   ```gdscript
   LevelManager.register_level(self)
   LevelManager.set_checkpoint($Player.global_position)
   ```
4. Добавьте экземпляр `Player.tscn`.
5. Добавьте камеру (можно дочернюю к игроку).
6. Разместите объекты, врагов, чекпоинты.
7. Настройте связи между объектами (рычаги → мосты, плиты → механизмы) через `target_node_path`.
8. Для воды добавьте кастомные данные в TileSet (свойство `water = true`), чтобы способность «Вода» работала.

---

## 13. Расширение и модификация

### 13.1. Добавление новой способности
1. Создайте ресурс `ability_resource.tres` с новым id.
2. В `player.gd` в `_on_ability_used` добавьте ветку `match` для обработки эффекта.
3. Добавьте ресурс в массив `abilities` узла `AbilityUser` игрока (можно через инспектор).

### 13.2. Добавление нового типа врага
1. Создайте сцену с корнем `CharacterBody2D`.
2. Добавьте компоненты `HealthComponent`, `AttackComponent`.
3. Создайте скрипт, наследующий `CharacterBody2D` или скопируйте `shadow_soldier.gd`, изменив поведение.
4. При необходимости добавьте новый скрипт в папку `scripts/characters/enemies/`.
5. Добавьте врага в группу `enemies`.

### 13.3. Создание нового состояния для игрока
1. Создайте новый файл в `scripts/states/player_states/`, наследующий `State`.
2. Реализуйте методы `enter`, `exit`, `update` и т.д.
3. Добавьте узел нового состояния в `StateMachine` в сцене игрока.
4. Измените код перехода в нужных местах (например, в `Idle` при нажатии на кнопку).

---

## 14. Устранение неполадок

- **Ошибка «Invalid access to property or key 'died' on a base object of type 'null instance'»** – узел `HealthComponent` отсутствует в сцене или путь к нему неверный.
- **Взаимодействие не работает** – проверьте слои коллизий: `InteractArea` должна иметь маску 2, а интерактивные объекты – слой 2. Убедитесь, что у объекта есть метод `interact()`.
- **Атака не наносит урон** – проверьте, что `AttackComponent` активируется (вызывается `activate()`) и имеет `CollisionShape2D`.
- **Способность воды не работает** – убедитесь, что ресурс `water_ability.tres` добавлен в `AbilityUser` и что в `_on_ability_used` есть обработка `"water"`.

---

## 15. Заключение

Данная архитектура обеспечивает масштабируемость, модульность и простоту добавления нового контента. Все ключевые системы изолированы и взаимодействуют через сигналы и глобальные менеджеры. Следуя документации, вы сможете поддерживать и расширять игру «Salvation» вплоть до полной версии.
