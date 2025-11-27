# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Any-Type-7** is a vertical-format space-based autobattler game for Android mobile devices built with Godot 4.5. The player controls a mothership fleeing from an alien threat, navigating sectors, gathering resources, and engaging in tactical grid-based autobattler combat.

**Current Status**: Early planning phase with comprehensive design documentation and CSV data schemas, but **no game code implemented yet**. The project exists as a well-architected clean slate ready for implementation.

## Key Technical Details

- **Engine**: Godot 4.5
- **Language**: GDScript
- **Platform**: Android mobile (1080x2340 portrait, 19.5:9 aspect ratio)
- **Renderer**: GL Compatibility (mobile-optimized)
- **Input**: Touch-first (tap, drag, long-press) with mouse fallback for development

## Running the Project

```bash
# Open in Godot 4.5 editor
godot project.godot

# Or from Godot editor
# File → Open Project → Select any-type-7 directory
```

**Note**: No export presets or build scripts exist yet. Android export would require setting up Godot export templates and Android SDK.

## Architecture

This project follows a **data-driven singleton autoload pattern** to avoid the monolithic "spaghetti code" problems of the previous iteration (any-type-4 reached 21,177 lines with a single 6,115-line combat script).

### Core Architectural Principles

1. **Singleton Autoload Pattern** - Break systems into focused single-responsibility managers (<300 lines each)
2. **EventBus Signal Pattern** - Centralized signal hub (`EventBus.gd`) for decoupled cross-system communication
3. **CSV-Driven Data Design** - Game content lives in `/data/*.csv` files, not hardcoded in scripts
4. **Component-Based Scene Composition** - Small reusable scene components that compose into larger systems
5. **Mobile-First UI** - Portrait layout (1080x2340) with touch-optimized controls from day one

### Planned Autoload Singletons (Not Yet Implemented)

**Core Infrastructure**:
- `EventBus.gd` - Global signal hub for decoupled communication
- `GameState.gd` - Persistent game state and progression tracking
- `DataManager.gd` - CSV loading, caching, and query system
- `SaveManager.gd` - Save/load system
- `SettingsManager.gd` - Player preferences
- `AudioManager.gd` - Music and sound effects

**Gameplay Systems**:
- `SectorManager.gd` - Sector exploration module, node management, map state
- `CombatManager.gd` - Combat orchestration, 15×25 grid, phases, units
- `HangarManager.gd` - Ship/pilot/equipment management
- `ResourceManager.gd` - Metal, Crystals, Fuel tracking and spending
- `EffectResolver.gd` - Data-driven ability and status effect execution
- `DamageCalculator.gd` - Hit chance, damage, crits, armor calculations

**Event & Encounter Systems**:
- `EncounterManager.gd` - Situation room and encounter flow
- `TraderManager.gd` - Shop encounters and trading
- `MiningManager.gd` - Mining node operations
- `TreasureManager.gd` - Loot and salvage

## Data-Driven Design (CSV Databases)

All game content is defined in `/data/*.csv` files. When implementing systems, **always load from CSV** rather than hardcoding values.

### CSV Database Status

| CSV File | Status | Purpose |
|----------|--------|---------|
| `ship_stat_database.csv` | **Populated** (14 ships) | Ship statistics (17 stats per ship) |
| `ability_database.csv` | **Populated** (50+ abilities) | Ship abilities, triggers, combos |
| `ship_upgrade_database.csv` | **Populated** (40+ upgrades) | Stat upgrades across 5 rarity tiers |
| `status_effects.csv` | **Populated** | Elemental and control status effects |
| `elemental_combos.csv` | **Populated** | Elemental combo damage and effects |
| `weapon_database.csv` | **Populated** (7 weapons) | Weapon systems |
| `blueprints_database.csv` | **Populated** (21 blueprints) | Unlockable ship and weapon blueprints |
| `drone_database.csv` | **Populated** (13 drones) | Combat and support drones |
| `powerups_database.csv` | **Populated** (10 powerups) | Combat powerup drops |
| `combat_scenarios.csv` | **EMPTY** | Wave definitions and enemy spawns |
| `personnel_database.csv` | **EMPTY** | Pilots and crew |
| `ship_visuals_database.csv` | **EMPTY** | Ship sprites and animations |
| `drone_visuals_database.csv` | **Populated** (11 drones) | Drone visual assets |

### CSV Loading Pattern

When implementing `DataManager.gd`, use this pattern:

```gdscript
# DataManager.gd (example)
var ship_data := {}
var ability_data := {}

func _ready():
    load_csv_database("res://data/ship_stat_database.csv", ship_data)
    load_csv_database("res://data/ability_database.csv", ability_data)

func load_csv_database(path: String, cache: Dictionary):
    var file = FileAccess.open(path, FileAccess.READ)
    # Parse CSV, cache by ID column
    # Handle type conversion for integers/floats
```

## Documentation Structure

Comprehensive game design documentation exists in `/docs/`:

- **`any-type-7-plan.md`** (483 lines) - Master game design document
  - Three main modules: Sector Exploration, Combat, Hangar
  - Core gameplay loop
  - 6-phase implementation roadmap
  - Architecture guidelines

- **`combat-formulas.md`** (472 lines) - All combat calculation formulas
  - Hit chance: `100% - (Defender_Evasion - Attacker_Accuracy)` (5-95% bounds)
  - Crit chance: `Attacker_Precision - Defender_Reinforced_Armor` (0% min)
  - Armor damage reduction: `Final_Damage = Incoming × (1 - Armor/100)` (75% cap)
  - DPS calculations and examples

- **`ship-stats-reference.md`** (580+ lines) - Complete ship statistics reference
  - 17 ship stats: Hull, Shields, Armor, Energy, Size, Damage, Projectiles, Attack Speed, Range, Movement, Accuracy, Evasion, Precision, Reinforced Armor, Amplitude, Frequency, Resilience
  - Ship size classes: Interceptor (1×1), Fighter (1×1), Frigate (2×2), Cruiser (3×3+)
  - **Ship subclasses** with specialized tactical roles:
    - **Interceptor**: Scout (stealth, range buffs), Striker (high damage), Disruptor (ability-focused)
    - **Fighter**: Ranger (stealth), Gunship (multi-weapon), Hunter (anti-stealth), Guardian (defensive), Strike Leader (buffs)
    - **Frigate**: Support (shields/buffs), Shield (tank), Corvette (heavy weapons), Flagship (armor buffs)
  - Subclass system is expandable - new subclasses may be added dynamically

- **`status-effects-and-combos.md`** (497 lines) - Status effect and elemental combo system
  - 5 elemental effects: Burn, Freeze, Static, Acid, Gravity (stackable, max 3)
  - Control effects: Stun, Blind, Malfunction, Energy Drain, Pinned Down
  - 30 elemental combos (5 same-element + 25 cross-element)
  - Trigger system mechanics (Explosive, Fire, Ice, Lightning, Acid, Gravity)

- **`weapons-system.md`** - Weapon mechanics and equipment
  - 5 weapon types: Ordinance, Multi-row, Bounce, Drone, Aura
  - Weapon qualities: Elemental triggers, piercing, shieldbuster
  - Run-and-gun combat mechanics
  - Weapon tier system and upgrade slots

- **`abilities-system.md`** - Ship abilities and activation
  - Data-driven ability system (CSV-balanced)
  - Energy system and Amplitude/Frequency scaling
  - Ability types: Damage, Buff, Debuff, Defensive, Utility
  - Integration with elemental triggers

- **`powerups-system.md`** - Combat powerup drops
  - 10 powerup types: Stat buffs, instant attacks, drones, utility
  - Drop mechanics: 8% basic enemies, 25% elites, 100% bosses
  - 15-second despawn timer
  - Pickup system and strategic positioning
  - Rarity distribution (common, uncommon, rare)

**Always consult these docs when implementing systems** - they contain complete specifications with formulas and examples.

## Three Main Game Modules

### 1. Sector Exploration Module
- Vertical scrolling map (loops vertically)
- 8 node types: Mining Nodes, Outposts, Alien Colonies, Traders, Asteroids, Graveyards, Artifact Vaults, Exit Node
- Fog of war system
- Fuel mechanics: Jump (10 fuel), Gravity Assist (1 fuel)
- Alien mothership chase mechanic (timer-based, gains speed each sector)

### 2. Combat Module
- **15 lanes** (vertical) × **~25 files** (horizontal) grid
- Player starts at lane 7 (center)
- **Tactical Phase**: Deploy ships in lanes
- **Wave Spawn Phase**: 30 seconds of enemy spawning
- **Combat Phase**: 60 seconds of autobattler action
- Ships attack automatically when in range, no player interaction during combat
- **Powerup drops**: Enemies drop powerups (stat buffs, instant attacks, drones, utility) that ships can pick up
- Retreat mechanic: Long-press, 30s countdown, fuel cost
- CSV-driven wave scenarios

### 3. Hangar Module
- Situation room (encounter preview)
- Ship roster management
- Equipment and upgrade installation
- Pilot assignment
- Loadout configuration

## Ship Statistics System (17 Stats)

Ships have 17 core statistics defined in `ship_stat_database.csv`:

**Defensive**: Hull Points, Shield Points, Armor, Size (Width×Height)
**Offensive**: Damage, Projectiles, Attack Speed, Attack Range
**Mobility**: Movement Speed
**Accuracy**: Accuracy, Evasion
**Critical**: Precision, Reinforced Armor
**Ability**: Energy Points, Amplitude, Frequency
**Resistance**: Resilience

**Key Formulas** (see `combat-formulas.md` for details):
- Hit Chance: `100% - (Evasion - Accuracy)` capped 5-95%
- Crit Chance: `Precision - Reinforced_Armor` min 0%
- Armor Reduction: `Damage × (1 - Armor/100)` max 75% reduction
- Attack Cooldown: `1.0 / Attack_Speed`

## Elemental Combo System

**5 Elemental Status Effects** (stackable, max 3 per type):
- **Burn** (Fire): 2 damage/sec per stack
- **Freeze** (Ice): -20% attack speed per stack
- **Static** (Lightning): -3 energy/sec per stack, blocks shield regen
- **Acid** (Corrosive): -1 armor/sec per stack (permanent for combat), blocks hull recovery
- **Gravity**: -30% movement & evasion per stack

**Trigger System**:
- **Trigger (Explosive)**: Detonates ALL elemental effects for damage matching each element
- **Trigger (Element-Specific)**: Detonates effects and applies special cross-element combos

**Combo Damage Formula**: `Base_Combo_Damage × (1 + Stack_Count × 0.5)`

Example: 3 Burn stacks → `20 × (1 + 3 × 0.5) = 50 fire damage`

**30 Total Combos**: 5 same-element + 25 cross-element (see `elemental_combos.csv`)

## Implementation Roadmap (6 Phases)

From `docs/any-type-7-plan.md`:

1. **Core Infrastructure** - Autoloads, EventBus, DataManager, CSV loading
2. **Sector Exploration Prototype** - Vertical scrolling, nodes, fog of war, movement
3. **Combat System Prototype** - 15×25 grid, tactical/combat phases, CSV waves
4. **Hangar & Fleet Management** - Situation room, ship customization, equipment
5. **Integration & Content** - Module transitions, populate CSVs, full game loop
6. **Polish & Mobile Optimization** - Touch UX, performance, Android build

## File Size Limits & Code Style

**Critical Rule**: Keep all GDScript files **under 300 lines**. This project exists to avoid the spaghetti code of any-type-4 (which had a 6,115-line combat script).

**When a file approaches 300 lines**:
1. Break into smaller components
2. Extract data to CSV files
3. Use signals for communication (via EventBus)
4. Create helper functions in utility singletons

**Naming Conventions**:
- Autoloads: PascalCase (e.g., `EventBus`, `DataManager`)
- Scenes: snake_case (e.g., `combat_grid.tscn`, `ship_card.tscn`)
- Scripts: Match scene name (e.g., `combat_grid.gd`)
- CSV files: snake_case (e.g., `ship_stat_database.csv`)

## Common Patterns

### EventBus Communication (Decoupling)

```gdscript
# EventBus.gd
signal combat_wave_completed(wave_number: int)
signal ship_destroyed(ship_id: String)
signal resource_changed(resource_type: String, amount: int)

# Emitter (CombatManager.gd)
EventBus.combat_wave_completed.emit(current_wave)

# Listener (HangarManager.gd)
func _ready():
    EventBus.combat_wave_completed.connect(_on_wave_completed)
```

### CSV Data Query

```gdscript
# Get ship data by ID
var ship = DataManager.get_ship("basic_interceptor")
print(ship.hull_points)  # 50
print(ship.armor)  # 0

# Get ability data
var ability = DataManager.get_ability("rocket")
print(ability.trigger_type)  # "explosive"
print(ability.base_damage)  # 30
```

### Component-Based Scene Pattern

```gdscript
# Ship.gd (component)
extends Node2D

@export var ship_id: String
var stats: Dictionary

func _ready():
    stats = DataManager.get_ship(ship_id)
    $HealthBar.max_value = stats.hull_points + stats.shield_points
```

## Resource System

Three core resources:
- **Metal**: Basic construction, common upgrades
- **Crystals**: Advanced technology, rare upgrades
- **Fuel**: Movement, jumping, gravity assists, retreat

Track via `ResourceManager` singleton, emit signals on change via EventBus.

## Combat Grid Mechanics

- **15 lanes** (vertical height)
- **~25 files** (horizontal depth)
- **Player deployment zone**: Left side, centered on lane 7
- **Enemy spawners**: Right side (invisible)
- **Ship sizes**: 1×1 (small), 2×2 (frigate), 3×3+ (capital)
- **Large ship rule**: 2×2+ ships have own grid, smaller units fly over them

## Important Constraints

1. **Portrait orientation only** - 1080x2340, design all UI for vertical layout
2. **Touch-first controls** - Tap, drag, long-press; mouse is fallback for testing
3. **No cards** - Previous iterations had cards, removed in any-type-7
4. **15 lanes fixed** - Combat grid is always 15 lanes tall
5. **Max 3 stacks** - Elemental status effects cap at 3 stacks per type
6. **75% armor cap** - Damage reduction maxes at 75%
7. **5-95% hit chance** - Always 5% min, 95% max regardless of stats

## What NOT to Do

Based on lessons from any-type-4/5 (see `plan/any-type-5-considerations.md`):

❌ **Don't** create monolithic scripts (keep under 300 lines)
❌ **Don't** hardcode game data (use CSVs)
❌ **Don't** create tight coupling between systems (use EventBus)
❌ **Don't** add card mechanics (explicitly removed from any-type-7)
❌ **Don't** design for landscape orientation (mobile portrait only)
❌ **Don't** create god objects or manager-of-managers

✅ **Do** use singleton autoloads for systems
✅ **Do** load all content from CSV databases
✅ **Do** use EventBus signals for cross-system communication
✅ **Do** create small reusable components (<300 lines)
✅ **Do** design for touch input from day one

## Next Steps for Implementation

If starting implementation from scratch:

1. **Set up autoload singletons** in project settings:
   - EventBus.gd (empty with signals)
   - DataManager.gd (CSV loading)
   - GameState.gd (state tracking)

2. **Implement CSV loading** in DataManager:
   - Parse ship_stat_database.csv (3 ships ready)
   - Parse ability_database.csv (34+ abilities ready)
   - Parse upgrade/status/combo CSVs

3. **Create basic combat grid prototype** (Phase 3 priority):
   - 15×25 grid scene
   - Lane-based ship placement
   - Basic ship movement down lanes
   - Simple attack range checking

4. **Follow the 6-phase roadmap** in `docs/any-type-7-plan.md`

## Additional Notes

- **GDAI MCP Plugin**: Present in `/addons/gdai-mcp-plugin-godot/` for AI-assisted development
- **Previous iteration reference**: See `/plan/any-type-5-considerations.md` for architectural lessons learned
- **Backup file**: `docs/ship-stats-system.md.backup` is deprecated (split into 3 focused docs)
- **Empty CSVs**: Several CSVs are 1-byte placeholders awaiting population (blueprints, scenarios, personnel, visuals)
