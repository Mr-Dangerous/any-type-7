# Phase 1: Core Infrastructure Implementation Plan

## Overview

**Goal**: Establish the foundational architecture and data systems for Any-Type-7

**Status**: Ready to implement (Content complete, 0% code)

**Timeline**: Foundation phase - all subsequent phases depend on this

**Deliverable**: A runnable Godot project with:
- All autoload singletons configured
- CSV data loading and caching system
- Portrait-oriented UI framework
- Input handling (touch + mouse)
- Debug/testing tools to verify data integrity

---

## Architecture Principles (Critical Rules)

Before writing any code, internalize these principles:

1. **File Size Limit**: Every GDScript file MUST be under 300 lines excepting debug lines.  eliminate unessecary whitespace.
2. **No Direct Dependencies**: Systems communicate via EventBus signals only
3. **Data-Driven**: Game content comes from CSV files, not hardcoded values
4. **Type Hints Required**: All functions and variables must have type hints
5. **Mobile-First**: Portrait orientation (1080x2340), touch-optimized from day one

---

## Phase 1 Task Breakdown

### Task 1: Project Configuration & Directory Structure

**Priority**: CRITICAL (do this first)

#### 1.1 Create Directory Structure

```
any-type-7/
├── scripts/
│   ├── autoloads/         # Singleton managers
│   ├── ui/                # UI components
│   ├── utils/             # Helper utilities
│   └── debug/             # Debug/testing tools
├── scenes/
│   ├── ui/                # UI scenes
│   ├── debug/             # Debug scenes
│   └── components/        # Reusable components
└── resources/
    └── themes/            # UI themes
```

#### 1.2 Configure Project Settings

Open `project.godot` and configure:

**Display Settings**:
- Window width: 1080
- Window height: 2340
- Window mode: Windowed (for development)
- Stretch mode: Canvas items
- Stretch aspect: Keep

**Rendering**:
- Renderer: GL Compatibility
- Anti-aliasing: MSAA 2D (2x)

**Input Devices**:
- Emulate touch from mouse: Enabled (for desktop testing)

**Success Criteria**: Project opens in Godot 4.5 with correct portrait resolution

---

### Task 2: EventBus Singleton (Signal Hub)

**Priority**: CRITICAL (needed by all other systems)

**File**: `scripts/autoloads/EventBus.gd`

**Purpose**: Centralized signal hub for decoupled cross-system communication

#### Implementation Pattern

```gdscript
extends Node

# ============================================================
# CORE GAME SIGNALS
# ============================================================

# Game state
signal game_started()
signal game_paused()
signal game_resumed()
signal game_quit()

# ============================================================
# RESOURCE SIGNALS
# ============================================================

signal resource_changed(resource_type: String, old_amount: int, new_amount: int)
signal resource_spent(resource_type: String, amount: int, reason: String)
signal resource_gained(resource_type: String, amount: int, source: String)

# ============================================================
# DATA LOADING SIGNALS
# ============================================================

signal data_load_started(database_name: String)
signal data_load_completed(database_name: String, record_count: int)
signal data_load_failed(database_name: String, error: String)
signal all_data_loaded()

# ============================================================
# COMBAT SIGNALS (Phase 3)
# ============================================================

signal combat_started(scenario_id: String)
signal combat_phase_changed(old_phase: String, new_phase: String)
signal combat_wave_spawned(wave_number: int)
signal combat_wave_completed(wave_number: int)
signal combat_ended(victory: bool, rewards: Dictionary)

signal ship_deployed(ship_id: String, lane: int)
signal ship_destroyed(ship_id: String, is_player: bool)
signal ship_damaged(ship_id: String, damage: float, remaining_hp: float)

# ============================================================
# SECTOR EXPLORATION SIGNALS (Phase 2)
# ============================================================

signal sector_entered(sector_number: int)
signal sector_exited()
signal node_discovered(node_id: String, node_type: String)
signal node_activated(node_id: String)

# ============================================================
# UI SIGNALS
# ============================================================

signal screen_changed(old_screen: String, new_screen: String)
signal notification_shown(message: String, type: String)

# ============================================================
# SAVE/LOAD SIGNALS
# ============================================================

signal save_started()
signal save_completed(save_path: String)
signal save_failed(error: String)
signal load_started(save_path: String)
signal load_completed()
signal load_failed(error: String)

# ============================================================
# HELPER FUNCTIONS
# ============================================================

func _ready() -> void:
    print("[EventBus] Initialized - Signal hub ready")
```

**Success Criteria**:
- File exists at `scripts/autoloads/EventBus.gd`
- Under 150 lines (well under 300 limit)
- Contains all signals needed for Phase 1-3
- No logic beyond signal definitions

**Configuration**: Add to Project → Project Settings → Autoload
- Path: `res://scripts/autoloads/EventBus.gd`
- Name: `EventBus`
- Enable: ✓

---

### Task 3: DataManager Singleton (CSV Loading System)

**Priority**: CRITICAL (needed to load all game content)

**File**: `scripts/autoloads/DataManager.gd`

**Purpose**: Load, parse, cache, and query all CSV databases

#### Implementation Requirements

**Core Features**:
1. CSV parsing with type conversion (int, float, string, bool)
2. Caching by ID column for O(1) lookups
3. Error handling for missing files or malformed data
4. Integration with EventBus for load status signals

#### CSV Structure Pattern

All CSVs follow this pattern:
- **First row**: Column headers (snake_case)
- **First column**: Unique ID (e.g., `ship_ID`, `ability_ID`)
- **Data types**: Auto-detect based on content (numbers vs strings)

#### Implementation Pattern

```gdscript
extends Node

# ============================================================
# CACHED DATA DICTIONARIES
# ============================================================

var ships: Dictionary = {}              # ship_ID → ship data
var abilities: Dictionary = {}          # ability_ID → ability data
var relics: Dictionary = {}             # item_ID → relic data (upgrade items)
var status_effects: Dictionary = {}     # effect_ID → effect data
var combos: Dictionary = {}             # combo_ID → combo data
var weapons: Dictionary = {}            # weapon_ID → weapon data
var drones: Dictionary = {}             # drone_ID → drone data
var powerups: Dictionary = {}           # powerup_ID → powerup data
var blueprints: Dictionary = {}         # blueprint_ID → blueprint data
var ship_visuals: Dictionary = {}       # visual_ID → visual data
var drone_visuals: Dictionary = {}      # drone_visual_ID → visual data

# Combat scenarios (currently empty CSV)
var combat_scenarios: Dictionary = {}  # scenario_ID → scenario data

# Personnel (currently empty CSV)
var personnel: Dictionary = {}          # personnel_ID → personnel data

# ============================================================
# LOAD STATUS
# ============================================================

var is_loaded: bool = false
var load_errors: Array[String] = []

# ============================================================
# INITIALIZATION
# ============================================================

func _ready() -> void:
    print("[DataManager] Starting CSV data load...")
    load_all_databases()

func load_all_databases() -> void:
    # Load order: static data first, dynamic data later

    _load_database("res://data/ship_stat_database.csv", ships, "ship_ID")
    _load_database("res://data/ability_database.csv", abilities, "ability_ID")
    _load_database("res://data/upgrade_relics.csv", relics, "item_ID")
    _load_database("res://data/status_effects.csv", status_effects, "effect_ID")
    _load_database("res://data/elemental_combos.csv", combos, "combo_ID")
    _load_database("res://data/weapon_database.csv", weapons, "weapon_ID")
    _load_database("res://data/drone_database.csv", drones, "drone_ID")
    _load_database("res://data/powerups_database.csv", powerups, "powerup_ID")
    _load_database("res://data/blueprints_database.csv", blueprints, "blueprint_ID")
    _load_database("res://data/ship_visuals_database.csv", ship_visuals, "visual_ID")
    _load_database("res://data/drone_visuals_database.csv", drone_visuals, "drone_visual_ID")

    # Empty CSVs (will have headers but no data rows)
    _load_database("res://data/combat_scenarios.csv", combat_scenarios, "scenario_ID")
    _load_database("res://data/personnel_database.csv", personnel, "personnel_ID")

    is_loaded = true
    EventBus.all_data_loaded.emit()
    print("[DataManager] All databases loaded successfully")
    _print_load_summary()

# ============================================================
# CSV PARSING
# ============================================================

func _load_database(csv_path: String, target_dict: Dictionary, id_column: String) -> void:
    EventBus.data_load_started.emit(csv_path.get_file())

    if not FileAccess.file_exists(csv_path):
        var error := "File not found: " + csv_path
        load_errors.append(error)
        EventBus.data_load_failed.emit(csv_path.get_file(), error)
        push_error(error)
        return

    var file := FileAccess.open(csv_path, FileAccess.READ)
    if file == null:
        var error := "Failed to open: " + csv_path
        load_errors.append(error)
        EventBus.data_load_failed.emit(csv_path.get_file(), error)
        push_error(error)
        return

    # Read header row
    var header_line := file.get_csv_line()
    if header_line.is_empty():
        file.close()
        var error := "Empty CSV file: " + csv_path
        load_errors.append(error)
        EventBus.data_load_failed.emit(csv_path.get_file(), error)
        push_error(error)
        return

    var headers := header_line
    var id_column_index := headers.find(id_column)

    if id_column_index == -1:
        file.close()
        var error := "ID column '%s' not found in %s" % [id_column, csv_path]
        load_errors.append(error)
        EventBus.data_load_failed.emit(csv_path.get_file(), error)
        push_error(error)
        return

    # Read data rows
    var record_count := 0
    while not file.eof_reached():
        var row := file.get_csv_line()

        # Skip empty rows
        if row.is_empty() or (row.size() == 1 and row[0].strip_edges().is_empty()):
            continue

        # Build record dictionary
        var record := {}
        for i in range(min(row.size(), headers.size())):
            var key := headers[i].strip_edges()
            var value := row[i].strip_edges()
            record[key] = _convert_type(value)

        # Cache by ID
        var record_id: String = record.get(id_column, "")
        if not record_id.is_empty():
            target_dict[record_id] = record
            record_count += 1

    file.close()
    EventBus.data_load_completed.emit(csv_path.get_file(), record_count)
    print("[DataManager] Loaded %d records from %s" % [record_count, csv_path.get_file()])

# ============================================================
# TYPE CONVERSION
# ============================================================

func _convert_type(value: String) -> Variant:
    # Empty string
    if value.is_empty():
        return ""

    # Boolean
    if value.to_lower() == "true":
        return true
    if value.to_lower() == "false":
        return false

    # Integer (no decimal point)
    if value.is_valid_int():
        return value.to_int()

    # Float (has decimal point)
    if value.is_valid_float():
        return value.to_float()

    # Default: String
    return value

# ============================================================
# QUERY FUNCTIONS
# ============================================================

func get_ship(ship_id: String) -> Dictionary:
    return ships.get(ship_id, {})

func get_ability(ability_id: String) -> Dictionary:
    return abilities.get(ability_id, {})

func get_relic(item_id: String) -> Dictionary:
    return relics.get(item_id, {})

func get_status_effect(effect_id: String) -> Dictionary:
    return status_effects.get(effect_id, {})

func get_combo(combo_id: String) -> Dictionary:
    return combos.get(combo_id, {})

func get_weapon(weapon_id: String) -> Dictionary:
    return weapons.get(weapon_id, {})

func get_drone(drone_id: String) -> Dictionary:
    return drones.get(drone_id, {})

func get_powerup(powerup_id: String) -> Dictionary:
    return powerups.get(powerup_id, {})

func get_blueprint(blueprint_id: String) -> Dictionary:
    return blueprints.get(blueprint_id, {})

func get_ship_visual(visual_id: String) -> Dictionary:
    return ship_visuals.get(visual_id, {})

func get_drone_visual(drone_visual_id: String) -> Dictionary:
    return drone_visuals.get(drone_visual_id, {})

# ============================================================
# BULK QUERIES
# ============================================================

func get_ships_by_class(size_class: String) -> Array[Dictionary]:
    var results: Array[Dictionary] = []
    for ship in ships.values():
        if ship.get("ship_size_class", "") == size_class:
            results.append(ship)
    return results

func get_ships_by_tier(tier: String) -> Array[Dictionary]:
    var results: Array[Dictionary] = []
    for ship in ships.values():
        if ship.get("tier", "") == tier:
            results.append(ship)
    return results

func get_abilities_by_type(ability_type: String) -> Array[Dictionary]:
    var results: Array[Dictionary] = []
    for ability in abilities.values():
        if ability.get("type", "") == ability_type:
            results.append(ability)
    return results

# ============================================================
# DEBUG & VALIDATION
# ============================================================

func _print_load_summary() -> void:
    print("=" * 60)
    print("DATA LOAD SUMMARY")
    print("=" * 60)
    print("Ships: %d" % ships.size())
    print("Abilities: %d" % abilities.size())
    print("Relics: %d" % relics.size())
    print("Status Effects: %d" % status_effects.size())
    print("Combos: %d" % combos.size())
    print("Weapons: %d" % weapons.size())
    print("Drones: %d" % drones.size())
    print("Powerups: %d" % powerups.size())
    print("Blueprints: %d" % blueprints.size())
    print("Ship Visuals: %d" % ship_visuals.size())
    print("Drone Visuals: %d" % drone_visuals.size())
    print("Combat Scenarios: %d" % combat_scenarios.size())
    print("Personnel: %d" % personnel.size())
    print("=" * 60)

    if not load_errors.is_empty():
        print("ERRORS:")
        for error in load_errors:
            print("  - " + error)
        print("=" * 60)

func get_all_ship_ids() -> Array[String]:
    var ids: Array[String] = []
    ids.assign(ships.keys())
    return ids

func validate_ship_references() -> Array[String]:
    var errors: Array[String] = []

    for ship_id in ships.keys():
        var ship := ships[ship_id]
        var ability_id: String = ship.get("ship_ability", "")

        if not ability_id.is_empty() and not abilities.has(ability_id):
            errors.append("Ship '%s' references unknown ability '%s'" % [ship_id, ability_id])

    return errors
```

**Success Criteria**:
- All 13 CSV files load without errors
- `ships` dictionary contains 14 records
- `abilities` dictionary contains 50 records
- Query functions return correct data
- EventBus signals fire during load
- Under 300 lines (currently ~250)

**Configuration**: Add to Project → Project Settings → Autoload
- Path: `res://scripts/autoloads/DataManager.gd`
- Name: `DataManager`
- Enable: ✓

---

### Task 4: GameState Singleton (State Management)

**Priority**: HIGH

**File**: `scripts/autoloads/GameState.gd`

**Purpose**: Track persistent game state and progression

#### Implementation Pattern

```gdscript
extends Node

# ============================================================
# GAME STATE
# ============================================================

var current_sector: int = 1
var current_screen: String = "main_menu"
var is_paused: bool = false

# ============================================================
# FLEET STATE
# ============================================================

var owned_ships: Array[String] = []        # Ship IDs the player owns
var active_loadout: Array[String] = []     # Ships deployed in current combat
var unlocked_blueprints: Array[String] = []

# ============================================================
# PROGRESSION
# ============================================================

var sectors_completed: int = 0
var total_combats_won: int = 0
var total_enemies_destroyed: int = 0

# ============================================================
# INITIALIZATION
# ============================================================

func _ready() -> void:
    print("[GameState] Initialized")
    _initialize_starter_fleet()

func _initialize_starter_fleet() -> void:
    # Give player starter ships (Phase 1 placeholder)
    owned_ships = [
        "basic_fighter",
        "basic_interceptor"
    ]
    print("[GameState] Starter fleet initialized: ", owned_ships)

# ============================================================
# FLEET MANAGEMENT
# ============================================================

func add_ship(ship_id: String) -> void:
    if not owned_ships.has(ship_id):
        owned_ships.append(ship_id)
        print("[GameState] Added ship to fleet: ", ship_id)

func remove_ship(ship_id: String) -> void:
    owned_ships.erase(ship_id)
    print("[GameState] Removed ship from fleet: ", ship_id)

func has_ship(ship_id: String) -> bool:
    return owned_ships.has(ship_id)

# ============================================================
# SCREEN MANAGEMENT
# ============================================================

func change_screen(new_screen: String) -> void:
    var old_screen := current_screen
    current_screen = new_screen
    EventBus.screen_changed.emit(old_screen, new_screen)
    print("[GameState] Screen changed: %s → %s" % [old_screen, new_screen])

# ============================================================
# PAUSE/RESUME
# ============================================================

func pause_game() -> void:
    is_paused = true
    get_tree().paused = true
    EventBus.game_paused.emit()

func resume_game() -> void:
    is_paused = false
    get_tree().paused = false
    EventBus.game_resumed.emit()
```

**Success Criteria**:
- Tracks basic game state
- Initializes starter fleet
- Under 150 lines
- Integrated with EventBus

**Configuration**: Add to Autoload
- Path: `res://scripts/autoloads/GameState.gd`
- Name: `GameState`

---

### Task 5: ResourceManager Singleton

**Priority**: HIGH

**File**: `scripts/autoloads/ResourceManager.gd`

**Purpose**: Track Metal, Crystals, Fuel

#### Implementation Pattern

```gdscript
extends Node

# ============================================================
# RESOURCE AMOUNTS
# ============================================================

var metal: int = 100       # Starting metal
var crystals: int = 50     # Starting crystals
var fuel: int = 100        # Starting fuel

# ============================================================
# INITIALIZATION
# ============================================================

func _ready() -> void:
    print("[ResourceManager] Initialized - Metal: %d, Crystals: %d, Fuel: %d" % [metal, crystals, fuel])

# ============================================================
# GETTERS
# ============================================================

func get_metal() -> int:
    return metal

func get_crystals() -> int:
    return crystals

func get_fuel() -> int:
    return fuel

func get_resource(resource_type: String) -> int:
    match resource_type.to_lower():
        "metal": return metal
        "crystals": return crystals
        "fuel": return fuel
        _:
            push_error("Unknown resource type: " + resource_type)
            return 0

# ============================================================
# RESOURCE MODIFICATION
# ============================================================

func add_metal(amount: int, source: String = "") -> void:
    var old := metal
    metal += amount
    EventBus.resource_changed.emit("metal", old, metal)
    EventBus.resource_gained.emit("metal", amount, source)

func add_crystals(amount: int, source: String = "") -> void:
    var old := crystals
    crystals += amount
    EventBus.resource_changed.emit("crystals", old, crystals)
    EventBus.resource_gained.emit("crystals", amount, source)

func add_fuel(amount: int, source: String = "") -> void:
    var old := fuel
    fuel += amount
    EventBus.resource_changed.emit("fuel", old, fuel)
    EventBus.resource_gained.emit("fuel", amount, source)

# ============================================================
# SPENDING
# ============================================================

func can_afford(cost: Dictionary) -> bool:
    var required_metal: int = cost.get("metal", 0)
    var required_crystals: int = cost.get("crystals", 0)
    var required_fuel: int = cost.get("fuel", 0)

    return metal >= required_metal and crystals >= required_crystals and fuel >= required_fuel

func spend_resources(cost: Dictionary, reason: String = "") -> bool:
    if not can_afford(cost):
        return false

    var spent_metal: int = cost.get("metal", 0)
    var spent_crystals: int = cost.get("crystals", 0)
    var spent_fuel: int = cost.get("fuel", 0)

    if spent_metal > 0:
        var old := metal
        metal -= spent_metal
        EventBus.resource_changed.emit("metal", old, metal)
        EventBus.resource_spent.emit("metal", spent_metal, reason)

    if spent_crystals > 0:
        var old := crystals
        crystals -= spent_crystals
        EventBus.resource_changed.emit("crystals", old, crystals)
        EventBus.resource_spent.emit("crystals", spent_crystals, reason)

    if spent_fuel > 0:
        var old := fuel
        fuel -= spent_fuel
        EventBus.resource_changed.emit("fuel", old, fuel)
        EventBus.resource_spent.emit("fuel", spent_fuel, reason)

    return true
```

**Success Criteria**:
- Tracks 3 resource types
- Emits signals on change
- Validates spending
- Under 200 lines

**Configuration**: Add to Autoload

---

### Task 6: Debug Data Viewer Scene

**Priority**: MEDIUM (needed for verification)

**File**: `scenes/debug/data_viewer.tscn` + `scripts/debug/data_viewer.gd`

**Purpose**: UI tool to browse loaded CSV data and verify DataManager

#### Scene Structure

```
Control (data_viewer.gd)
├── MarginContainer
│   └── VBoxContainer
│       ├── Label (Title: "Data Viewer")
│       ├── HBoxContainer (Database Selector)
│       │   ├── Label ("Database:")
│       │   └── OptionButton (DatabaseDropdown)
│       ├── HBoxContainer (Record Selector)
│       │   ├── Label ("Record:")
│       │   └── OptionButton (RecordDropdown)
│       └── ScrollContainer
│           └── VBoxContainer (DataDisplay)
```

#### Script Pattern

```gdscript
extends Control

@onready var database_dropdown: OptionButton = $MarginContainer/VBoxContainer/DatabaseSelector/DatabaseDropdown
@onready var record_dropdown: OptionButton = $MarginContainer/VBoxContainer/RecordSelector/RecordDropdown
@onready var data_display: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/DataDisplay

var current_database: Dictionary = {}
var database_map: Dictionary = {
    "Ships": DataManager.ships,
    "Abilities": DataManager.abilities,
    "Relics": DataManager.relics,
    "Weapons": DataManager.weapons,
    "Drones": DataManager.drones,
    "Powerups": DataManager.powerups,
    "Status Effects": DataManager.status_effects,
    "Combos": DataManager.combos,
}

func _ready() -> void:
    _populate_database_dropdown()
    database_dropdown.item_selected.connect(_on_database_selected)
    record_dropdown.item_selected.connect(_on_record_selected)

func _populate_database_dropdown() -> void:
    for db_name in database_map.keys():
        database_dropdown.add_item(db_name)

func _on_database_selected(index: int) -> void:
    var db_name := database_dropdown.get_item_text(index)
    current_database = database_map[db_name]
    _populate_record_dropdown()

func _populate_record_dropdown() -> void:
    record_dropdown.clear()
    for record_id in current_database.keys():
        record_dropdown.add_item(record_id)

func _on_record_selected(index: int) -> void:
    var record_id := record_dropdown.get_item_text(index)
    _display_record(current_database[record_id])

func _display_record(record: Dictionary) -> void:
    # Clear previous display
    for child in data_display.get_children():
        child.queue_free()

    # Display each key-value pair
    for key in record.keys():
        var label := Label.new()
        label.text = "%s: %s" % [key, str(record[key])]
        data_display.add_child(label)
```

**Success Criteria**:
- Can browse all databases
- Displays record data correctly
- Verifies DataManager is working

---

### Task 7: Main Scene & UI Framework

**Priority**: HIGH

**File**: `scenes/main.tscn` + `scripts/main.gd`

**Purpose**: Root scene with portrait layout container

#### Scene Structure

```
Control (main.gd) [1080x2340]
└── CanvasLayer
    └── MarginContainer
        └── VBoxContainer
            ├── Label (Title: "Any-Type-7")
            ├── Label (Status: "Core Systems Online")
            ├── Button ("Open Data Viewer")
            └── VBoxContainer (Resource Display)
                ├── Label ("Metal: 100")
                ├── Label ("Crystals: 50")
                └── Label ("Fuel: 100")
```

#### Script Pattern

```gdscript
extends Control

@onready var metal_label: Label = $CanvasLayer/MarginContainer/VBoxContainer/Resources/MetalLabel
@onready var crystals_label: Label = $CanvasLayer/MarginContainer/VBoxContainer/Resources/CrystalsLabel
@onready var fuel_label: Label = $CanvasLayer/MarginContainer/VBoxContainer/Resources/FuelLabel

func _ready() -> void:
    EventBus.resource_changed.connect(_on_resource_changed)
    _update_resource_display()

func _update_resource_display() -> void:
    metal_label.text = "Metal: %d" % ResourceManager.get_metal()
    crystals_label.text = "Crystals: %d" % ResourceManager.get_crystals()
    fuel_label.text = "Fuel: %d" % ResourceManager.get_fuel()

func _on_resource_changed(_type: String, _old: int, _new: int) -> void:
    _update_resource_display()

func _on_open_data_viewer_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/debug/data_viewer.tscn")
```

**Success Criteria**:
- Portrait orientation (1080x2340)
- Displays resource counts
- Opens data viewer
- Responds to EventBus signals

---

## Testing & Validation

### Phase 1 Acceptance Criteria

1. **Project Configuration**
   - ✓ Project opens in Godot 4.5
   - ✓ Portrait orientation (1080x2340) is correct
   - ✓ GL Compatibility renderer enabled

2. **Autoload Singletons**
   - ✓ EventBus configured and accessible
   - ✓ DataManager configured and loads all CSVs
   - ✓ GameState configured and tracks state
   - ✓ ResourceManager configured and tracks resources

3. **Data Loading**
   - ✓ All 13 CSV files load without errors
   - ✓ 14 ships loaded
   - ✓ 50 abilities loaded
   - ✓ All other databases populated correctly
   - ✓ Query functions return correct data

4. **EventBus Integration**
   - ✓ Signals defined for all major systems
   - ✓ DataManager emits load signals
   - ✓ ResourceManager emits change signals
   - ✓ UI responds to signals

5. **Debug Tools**
   - ✓ Data viewer scene functional
   - ✓ Can browse all databases
   - ✓ Displays record details correctly

6. **File Size Compliance**
   - ✓ All scripts under 300 lines
   - ✓ No monolithic files

### Manual Testing Checklist

```
[ ] Run project in Godot editor
[ ] Verify console shows successful data load
[ ] Check data load summary in console
[ ] Open data viewer from main menu
[ ] Browse ships database
[ ] Browse abilities database
[ ] Verify ship stats match CSV
[ ] Check resource display updates
[ ] Verify no errors in console
[ ] Test on mobile resolution (1080x2340)
```

---

## Next Steps After Phase 1

Once Phase 1 is complete and validated:

1. **Phase 2 Prep**: Begin sector exploration prototype
   - Vertical scrolling map
   - Node placement system
   - Fog of war

2. **Expand Autoloads**: Add gameplay-specific managers
   - SectorManager
   - CombatManager (basic structure)
   - HangarManager (basic structure)

3. **UI Theme**: Create mobile-optimized theme
   - Touch target sizes (minimum 44x44 dp)
   - Portrait-friendly layouts
   - Button styles

---

## Common Pitfalls to Avoid

1. **Don't hardcode data** - Always load from CSV
2. **Don't create direct dependencies** - Use EventBus
3. **Don't exceed 300 lines** - Break into smaller files
4. **Don't skip type hints** - Always use `: Type` syntax
5. **Don't test on desktop only** - Verify portrait layout early
6. **Don't skip error handling** - CSV loading must be robust

---

## File Size Estimates

- EventBus: ~150 lines
- DataManager: ~280 lines (close to limit!)
- GameState: ~120 lines
- ResourceManager: ~180 lines
- Main scene script: ~50 lines
- Data viewer script: ~100 lines

**Total**: ~880 lines across 6 files (average 147 lines/file)

---

## Resources & References

- [Godot CSV Parsing](https://docs.godotengine.org/en/stable/classes/class_fileaccess.html#class-fileaccess-method-get-csv-line)
- [Autoload Singletons](https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html)
- [Godot Signals](https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html)
- Project docs: `/docs/any-type-7-plan.md`
- Combat formulas: `/docs/combat-formulas.md`

---

## Completion Checklist

### Infrastructure
- [ ] Directory structure created
- [ ] Project settings configured
- [ ] Portrait orientation verified

### Autoloads
- [ ] EventBus.gd implemented and configured
- [ ] DataManager.gd implemented and configured
- [ ] GameState.gd implemented and configured
- [ ] ResourceManager.gd implemented and configured

### Data Loading
- [ ] All 13 CSV files load successfully
- [ ] Data cache populated correctly
- [ ] Query functions tested
- [ ] Load summary printed to console

### Debug Tools
- [ ] Data viewer scene created
- [ ] Data viewer script implemented
- [ ] Can browse all databases
- [ ] Data displays correctly

### Testing
- [ ] All manual tests passed
- [ ] No console errors
- [ ] EventBus signals working
- [ ] Resource display updates

### Documentation
- [ ] Code comments added
- [ ] Function signatures documented
- [ ] README updated (if needed)

---

**Phase 1 Complete When**: All checkboxes above are marked ✓ and the project runs without errors.

**Estimated Effort**: 4-6 hours for experienced Godot developer

**Next Phase**: Phase 2 - Sector Exploration Prototype
