# Any-Type-5 Restart Considerations

## Executive Summary

Your current project (any-type-4) has grown to **21,177 lines of GDScript** with Combat_2.gd alone at **6,115 lines**. You've recognized the "spaghetti" problem - tight coupling, monolithic scene scripts, and unclear separation of concerns. This document provides a comprehensive roadmap for restarting with a cleaner, more maintainable architecture optimized for mobile/portrait gameplay.

**Key Goals for Any-Type-5:**
1. **Singleton Architecture**: Break combat systems into clean, focused autoloads
2. **Data-Driven Design**: Offload game logic to CSV databases
3. **Portrait/Vertical Layout**: Phone-optimized UI from day one
4. **Scene Composition**: Small, reusable components instead of monoliths
5. **Signal-Based Communication**: Decouple systems with event bus pattern

---

## 1. Current State Analysis

### What Went Wrong in Any-Type-4

**Monolithic Scene Scripts:**
- Combat_2.gd: 6,115 lines (combat logic, UI, input, state management all mixed)
- Combat_3.gd: 2,959 lines (still too large despite modular refactor attempts)
- Hangar.gd: 1,600 lines
- StarMap.gd: 1,216 lines

**Tight Coupling:**
- Combat scene directly manipulates:
  - Projectiles, targeting, weapons, health, status effects, combos
  - Camera, UI, input handling
  - Grid management, ship spawning, enemy AI
  - Card system, ability queues
- Scene scripts reference each other directly (Combat → CardHandManager, Combat → CombatGridManager)

**Hybrid Singleton Approach:**
- 11 autoloads, but some are scene-initialized modules (not true singletons)
- CombatProjectileManager, CombatWeapons, etc. are created in Combat_3._ready()
- This defeats the purpose of autoloads (not globally accessible)

**CSV Structure Issues:**
- 42 columns in card_database_v2.csv (effect_type, secondary_effect_type, tertiary_effect_type, etc.)
- Hardcoded effect names requiring code changes for new cards
- Effect logic split between CSV metadata and CardEffects.gd code

### What Went Right (Keep These)

✓ **CSV-Driven Data**: Ships, cards, pilots, upgrades all in databases
✓ **SeedManager**: Clean deterministic RNG for map generation
✓ **DataManager**: Centralized CSV loading with caching
✓ **GameData**: Persistent state management across scenes
✓ **Modular Combat Subsystems**: The *idea* of separate managers is correct (just need proper autoloads)

---

## 2. Singleton Architecture Redesign

### Current Autoloads (11 total)
```
SeedManager          ✓ Good - keep as-is
DataManager          ✓ Good - keep as-is
GameData             ✓ Good - keep as-is
CombatConstants      ⚠️  Merge into CombatManager
CardHandManager      ⚠️  Needs refactor (see below)
TooltipManager       ⚠️  Could be UI component, not singleton
CombatGridManager    ⚠️  Should be in CombatManager
CombatWaveManager    ⚠️  Should be in CombatManager
TraderManager        ✓ Good for Trader scene
MiningManager        ✓ Good for Mining scene
TreasureManager      ✓ Good for Treasure scene
```

### Proposed Autoload Structure for Any-Type-5

**Core Systems (Always Loaded):**
```
1. SeedManager           - Deterministic RNG (keep as-is)
2. DataManager           - CSV loading and caching (keep as-is)
3. GameState             - Persistent game state (rename from GameData)
4. EventBus              - NEW: Global signal hub for decoupling
5. AudioManager          - NEW: Music, SFX, audio ducking
6. SettingsManager       - NEW: Player preferences, keybinds, volume
7. SaveManager           - NEW: Save/load game state to disk
```

**Gameplay Systems (Combat-Related):**
```
8. CombatManager         - NEW: Master combat orchestrator
9. DeckManager           - REFACTOR CardHandManager → full deck building
10. EffectResolver       - NEW: Process all card/ability/status effects
11. DamageCalculator     - Extract from combat scripts, centralize
```

**Event Scene Managers (Lazy Load):**
```
12. TraderManager        - Keep for Trader scene
13. MiningManager        - Keep for Mining scene
14. TreasureManager      - Keep for Treasure scene
15. HangarManager        - NEW: Ship/pilot/upgrade management
```

### Detailed Singleton Designs

#### 8. CombatManager (NEW)
**Purpose**: Master combat orchestrator - owns combat state, phase management, turn flow

**Responsibilities:**
- Phase management (DEPLOY → PRE_TACTICAL → TACTICAL → PRE_COMBAT → COMBAT → CLEANUP)
- Turn counter and combat timer
- Grid state (consolidate CombatGridManager into this)
- Unit tracking (all_units array, spawning, cleanup)
- Wave spawning (consolidate CombatWaveManager into this)
- Victory/defeat conditions

**NOT Responsible For:**
- Individual projectiles (delegates to EffectResolver)
- Damage calculation (delegates to DamageCalculator)
- Card effects (delegates to EffectResolver)
- UI rendering (Combat scene handles this)

**Key Methods:**
```gdscript
# Phase Control
func start_combat(scenario_id: String) -> void
func advance_phase() -> void
func end_combat(victory: bool) -> void

# Grid Management
func occupy_cell(pos: Vector2i, unit: Dictionary) -> bool
func free_cell(pos: Vector2i) -> void
func get_unit_at(pos: Vector2i) -> Dictionary

# Unit Management
func spawn_unit(ship_id: String, faction: String, grid_pos: Vector2i) -> Dictionary
func remove_unit(unit: Dictionary) -> void
func get_units_by_faction(faction: String) -> Array

# Wave Control
func spawn_wave(wave_index: int) -> void
```

**Signals:**
```gdscript
signal phase_changed(new_phase: Phase)
signal unit_spawned(unit: Dictionary)
signal unit_died(unit: Dictionary)
signal combat_ended(victory: bool)
signal wave_spawned(wave_index: int)
```

#### 9. DeckManager (REFACTOR CardHandManager)
**Purpose**: Full deck building, card pool, hand management, draw/discard mechanics

**Responsibilities:**
- Starting deck initialization
- Card pool filtering (owned cards, unlocks)
- Hand size limits, draw mechanics
- Deck persistence between combats
- Card upgrade/removal

**Key Methods:**
```gdscript
# Deck Building (pre-combat)
func add_card_to_deck(card_id: String) -> void
func remove_card_from_deck(card_id: String) -> void
func upgrade_card(card_id: String) -> void

# In-Combat Hand Management
func start_combat_with_deck(deck: Array[String]) -> void
func draw_cards(count: int) -> Array[Dictionary]
func discard_card(card_id: String) -> void
func shuffle_discard_into_draw() -> void
func end_combat_cleanup() -> void

# Card Pool
func get_unlocked_cards() -> Array[String]
func unlock_card(card_id: String) -> void
```

#### 10. EffectResolver (NEW)
**Purpose**: Single source of truth for all effect execution (cards, abilities, status effects, combos)

**Why This is Critical:**
- Current code has effects scattered across CardEffects.gd, CombatStatusEffectManager, CombatComboSystem, ship abilities
- Data-driven effects mean CSV defines "what", EffectResolver handles "how"
- Enables complex effect chains (card applies status → status triggers combo → combo deals damage)

**Responsibilities:**
- Execute card effects (from CSV effect_type/effect_stat/effect_value)
- Apply status effects (burn, freeze, acid, gravity, static, blind, malfunction)
- Process status ticks (DOT damage, stat modifiers)
- Detect and execute combos
- Handle AoE falloff and targeting

**Key Methods:**
```gdscript
# Effect Execution
func resolve_card_effect(card_data: Dictionary, caster: Dictionary, target: Dictionary) -> void
func apply_status_effect(status: String, stacks: int, target: Dictionary) -> void
func process_status_ticks(unit: Dictionary, delta: float) -> void
func check_combo_triggers(attacker: Dictionary, target: Dictionary, hit_success: bool) -> void

# AoE Handling
func get_units_in_aoe(center: Vector2i, range: int, faction_filter: String) -> Array
func apply_aoe_effect(effect: Dictionary, targets: Array, falloff: String) -> void

# Damage Resolution
func apply_damage(damage: int, element: String, target: Dictionary, attacker: Dictionary) -> Dictionary
```

**Effect Registry Pattern:**
```gdscript
# CSV: effect_type = "buff", effect_stat = "attack_speed", effect_value = "0.2"
# EffectResolver translates to: target.temp_stats["attack_speed"] += 0.2

var effect_handlers: Dictionary = {
	"buff": _handle_buff_effect,
	"add": _handle_add_effect,
	"projectile": _handle_projectile_effect,
	"combo": _handle_combo_effect,
	# ... extensible via CSV
}
```

#### 11. DamageCalculator (Extract from Combat)
**Purpose**: Centralized damage calculation with accuracy, evasion, crits, resistances

**Responsibilities:**
- Hit chance calculation (accuracy vs evasion)
- Critical hit rolls
- Damage type resistances (fire, ice, explosive, kinetic, etc.)
- Armor/shield penetration
- Damage number generation

**Key Methods:**
```gdscript
func calculate_hit(attacker: Dictionary, target: Dictionary) -> Dictionary:
	# Returns: {hit: bool, crit: bool, damage: int, element: String}

func apply_resistances(damage: int, element: String, target: Dictionary) -> int

func generate_damage_number(damage: int, position: Vector2, crit: bool, element: String) -> void
```

---

## 3. Data-Driven Design: Offloading Logic to CSV

### Current Problem: Hardcoded Effect Logic

**Example from CardEffects.gd (703 lines):**
```gdscript
func apply_strike_effect(target_ship: Dictionary):
	target_ship["temp_stats"]["attack_speed"] += 0.5
	show_effect_text(target_ship, "ATK SPEED +0.5", Color.ORANGE)

func apply_shield_effect(target_ship: Dictionary):
	var shield_amount = 30
	if target_ship["current_shield"] < target_ship["max_shield"]:
		# ... complex shield logic
	# ... more code
```

**Every new card requires:**
1. New function in CardEffects.gd
2. New if/elif branch in card execution
3. Code changes for balancing numbers

### Solution: Effect Templates in CSV

#### New CSV Column: `effect_template`

Instead of 42 columns trying to cover every possible effect, use a template system:

**card_database_v3.csv:**
```csv
card_id,name,effect_template,template_params
strike,Strike,modify_stat,"stat:attack_speed,modifier:0.2,duration:combat,target:self"
shield,Shield,add_resource,"resource:shield,amount:30,target:single"
energy_alpha,Energy Alpha,add_resource,"resource:energy,amount:100,target:single"
energy_beta,Energy Beta,add_resource,"resource:energy,amount:75,target:single,aoe:1,aoe_falloff:0.5"
incendiary_rounds,Incendiary Rounds,modify_damage,"element:fire,bonus:3,duration:combat,on_hit:apply_status(burn,1,0.25)"
missile_lock,Missile Lock,spawn_projectile,"damage:50,element:explosive,aoe:1,sprite:missile,size:70"
alpha_strike,Alpha Strike,buff_multi,"stats:[movement_speed:3,damage:7],duration:5"
```

**template_params Syntax:**
- Key-value pairs separated by commas
- Nested effects using parentheses: `on_hit:apply_status(burn,1,0.25)`
- Arrays using brackets: `stats:[movement_speed:3,damage:7]`

#### Effect Template Handlers

**EffectResolver.gd:**
```gdscript
var template_handlers: Dictionary = {
	"modify_stat": _template_modify_stat,
	"add_resource": _template_add_resource,
	"modify_damage": _template_modify_damage,
	"spawn_projectile": _template_spawn_projectile,
	"buff_multi": _template_buff_multi,
	"apply_status": _template_apply_status,
	"combo_trigger": _template_combo_trigger,
}

func resolve_card_effect(card_data: Dictionary, caster: Dictionary, target: Dictionary):
	var template = card_data["effect_template"]
	var params = parse_template_params(card_data["template_params"])

	if template in template_handlers:
		template_handlers[template].call(params, caster, target)
	else:
		push_error("Unknown template: " + template)

func _template_modify_stat(params: Dictionary, caster: Dictionary, target: Dictionary):
	var stat = params["stat"]
	var modifier = float(params["modifier"])
	var duration = params["duration"]

	if duration == "combat":
		target["temp_stats"][stat] = target["temp_stats"].get(stat, 0.0) + modifier
	elif duration == "permanent":
		target["base_stats"][stat] += modifier
	else:
		# Timed buff (duration in seconds)
		_add_timed_buff(target, stat, modifier, float(duration))
```

### Benefits of Template System

✅ **Add new cards without code changes** - Just add CSV row
✅ **Balance via CSV** - Change numbers in spreadsheet, no recompile
✅ **Complex combos via composition** - Chain templates together
✅ **Moddable** - Players can add custom cards via CSV
✅ **AI-friendly** - AI can generate balanced cards by template
✅ **Testable** - Unit test each template handler independently

### Additional CSV Improvements

#### 1. Status Effect Database (status_effects.csv)
```csv
status_id,display_name,icon_path,type,tick_damage,tick_interval,duration,stat_modifiers,combo_enabled
burn,Burning,res://icons/burn.png,dot,5,1.0,10.0,,TRUE
freeze,Frozen,res://icons/freeze.png,modifier,0,0,2.0,"attack_speed:-0.25,evasion:-0.25",TRUE
acid,Corroded,res://icons/acid.png,dot,3,1.0,15.0,"armor:-10",TRUE
static,Shocked,res://icons/static.png,modifier,0,0,3.0,"accuracy:-15",TRUE
gravity,Slowed,res://icons/gravity.png,modifier,0,0,4.0,"movement_speed:-1",TRUE
blind,Blinded,res://icons/blind.png,modifier,0,0,2.0,"accuracy:-50",FALSE
malfunction,Malfunctioning,res://icons/malfunction.png,modifier,0,0,2.0,"attack_speed:-0.5",FALSE
```

**Benefits:**
- Status effects become data, not code
- stat_modifiers column contains comma-separated key:value pairs
- EffectResolver reads this database and applies effects dynamically

#### 2. Combo Database (combos.csv)
```csv
combo_id,display_name,setup_status,trigger_element,effect_template,effect_params,priority
shrapnel_blast,Shrapnel Blast,burn,explosive,spawn_projectile,"damage:20,element:fire,aoe:1,damage_per_stack:20",1
steam_explosion,Steam Explosion,freeze,fire,multi_effect,"damage:30,element:fire,aoe:1,apply_status:blind,status_duration:2",2
thermal_runaway,Thermal Runaway,static,fire,multi_effect,"damage:30,element:fire,aoe:1,apply_status:malfunction,status_duration:2",3
chain_lightning,Chain Lightning,static,lightning,chain_projectile,"damage:25,element:lightning,max_chains:3,chain_range:2",1
```

**EffectResolver reads this on startup:**
- When projectile hits, check `trigger_element` vs `setup_status` on target
- If match, execute combo's `effect_template` with `effect_params`
- Priority determines which combo fires first if multiple match

#### 3. Ship Ability Database (Consolidate into ship_database.csv)

**Current ship_database.csv has:**
- `ability` column (name of ability)
- `energy` column (cost to cast)

**Add columns:**
- `ability_effect_template` (same template system as cards)
- `ability_effect_params` (template parameters)
- `ability_passive_template` (for passive abilities)
- `ability_passive_params`

**Example:**
```csv
ship_id,ability,ability_effect_template,ability_effect_params
basic_interceptor,Alpha Strike,buff_multi,"stats:[movement_speed:3,damage:7],duration:5"
basic_fighter,Missile Lock,spawn_projectile,"damage:50,element:explosive,aoe:1"
basic_frigate,Shield Battery,add_resource,"resource:shield,amount:50,aoe:2,aoe_falloff:full"
burning_frigate,Burning Field,apply_status,"status:burn,stacks:1,aoe:2,tick_interval:1.0"
```

**Result**: Ship abilities use exact same EffectResolver as cards - zero code duplication!

---

## 4. Portrait/Vertical Layout for Mobile

### Current Issues
- Landscape-oriented UI (1920×1080 assumed)
- Wide starmap, horizontal lanes
- Bottom card hand UI (assumes landscape)
- Mouse/click-focused (not touch-friendly)

### Target Mobile Resolution
**Primary:** 1080×1920 (portrait, common Android/iOS)
**Secondary:** 1080×2340 (taller portrait, modern phones)
**Tertiary:** 720×1280 (budget devices)

**Design for 1080×1920, scale down gracefully**

### UI Layout Redesign

#### Portrait StarMap
```
┌─────────────────┐
│   [Fuel] [Metal]│  <- Resources at top (always visible)
│   [Crystals]    │
├─────────────────┤
│                 │
│    ╭───╮       │  <- Vertical node path
│    │ 1 │       │     (scroll up to progress)
│    ╰───╯       │
│      ▼         │
│    ╭───╮       │
│    │ 2 │       │
│    ╰───╯       │
│    ╱ ╲        │
│  ╭───╮╭───╮   │
│  │ 3 ││ 4 │   │
│  ╰───╯╰───╯   │
│      ▼         │
│    (scroll)    │
│                 │
├─────────────────┤
│  [Ship Status]  │  <- Current fleet summary
│  [3 Ships]      │     (tap to open Hangar)
└─────────────────┘
```

**Vertical scrolling map:**
- Player scrolls UP to progress (feels like climbing)
- Current node centered on screen
- Future nodes dimmed/locked
- Path branches spread horizontally (max 2-3 wide)

#### Portrait Combat Grid
**Instead of wide 25×20 grid, use vertical 12×30 grid:**

```
    12 columns (narrow)
    ↓
┌──────────────┐  ← Top: Enemy spawn zone (rows 0-5)
│ ╭─╮ ╭─╮ ╭─╮ │
│ │E│ │E│ │E│ │  Enemy ships spawn here
│ ╰─╯ ╰─╯ ╰─╯ │
├──────────────┤
│              │  ← Mid: Combat zone (rows 6-23)
│   ╭─╮        │
│   │P│  ╭─╮  │  Player ships move upward
│   ╰─╯  │E│  │  Enemies move downward
│        ╰─╯  │
│              │
│              │
│   (scrollable│  Swipe to pan camera up/down
│    combat    │
│     area)    │
│              │
├──────────────┤
│ ╭─╮ ╭─╮ ╭─╮ │  ← Bottom: Player spawn (rows 24-29)
│ │P│ │P│ │P│ │
│ ╰─╯ ╰─╯ ╰─╯ │
└──────────────┘
     ↑
 Hand UI (swipe up to view cards)
```

**Key Changes:**
- **Vertical grid**: 12 columns × 30 rows (fits portrait screen)
- **Enemies at top**: Players view battlefield from bottom-up
- **Player ships deploy from bottom**: Feel like defending your base
- **Swipe-pan combat**: Touch-drag to move camera, pinch-zoom
- **Card hand drawer**: Cards hidden by default, swipe up from bottom edge to reveal

#### Portrait Hangar
```
┌──────────────────┐
│ [Back] Hangar    │  <- Top bar navigation
├──────────────────┤
│  Pilot Roster    │  <- Scrollable vertical list
│ ╭────────────╮  │
│ │ [Portrait]  │  │
│ │ Name: Alice │  │
│ │ Ability: +3 │  │
│ ╰────────────╯  │
│ ╭────────────╮  │
│ │ [Portrait]  │  │
│ │ Name: Bob   │  │
│ │ Ability: +5 │  │
│ ╰────────────╯  │
│   (scroll...)   │
├──────────────────┤
│  Ship Fleet     │  <- Scrollable vertical list
│ ╭────────────╮  │
│ │ ┌────┐      │  │
│ │ │Ship│      │  │
│ │ └────┘      │  │
│ │ Pilot: Alice│  │  <- Tap to assign/swap pilot
│ │ [Upgrades]  │  │  <- Tap to view upgrade slots
│ ╰────────────╯  │
│ ╭────────────╮  │
│ │ ┌────┐      │  │
│ │ │Ship│      │  │
│ │ └────┘      │  │
│ │ Pilot: None │  │
│ │ [Upgrades]  │  │
│ ╰────────────╯  │
│   (scroll...)   │
└──────────────────┘
```

**Single scrollable list instead of side-by-side panels:**
- Pilots section at top (vertical scroll)
- Ships section below (vertical scroll)
- Tap pilot → Tap ship to assign (no drag-drop on mobile)
- Tap upgrade slot → Shows upgrade picker modal

### Touch Controls

**Gesture Mapping:**
- **Tap**: Select ship/target, play card, navigate nodes
- **Long Press**: Show tooltip/info popup
- **Swipe Up (from bottom)**: Reveal card hand
- **Swipe Down**: Hide card hand
- **Swipe Left/Right (combat)**: Pan camera horizontally
- **Swipe Up/Down (combat)**: Pan camera vertically
- **Pinch**: Zoom in/out
- **Two-finger tap**: Reset camera to default view
- **Drag (tactical phase)**: Move ship to new grid position

**Button Sizing:**
- Minimum touch target: 96×96px (48pt at 2x density)
- All buttons at least 80px tall
- Bottom buttons offset 120px from screen edge (avoid gesture bar)

### Adaptive UI System

**Create responsive Control nodes:**
```gdscript
# ui/ResponsiveContainer.gd
extends Control

@export var mobile_layout: PackedScene
@export var desktop_layout: PackedScene

func _ready():
	var viewport_size = get_viewport_rect().size
	var is_portrait = viewport_size.y > viewport_size.x

	if is_portrait:
		add_child(mobile_layout.instantiate())
	else:
		add_child(desktop_layout.instantiate())
```

**Separate scene files:**
- `scenes/combat/Combat_Mobile.tscn` (portrait grid)
- `scenes/combat/Combat_Desktop.tscn` (landscape grid)
- `scenes/starmap/StarMap_Mobile.tscn` (vertical path)
- `scenes/starmap/StarMap_Desktop.tscn` (horizontal path)

**OR use anchors/margins dynamically:**
```gdscript
# Auto-switch card hand orientation
func _on_viewport_size_changed():
	var size = get_viewport_rect().size
	if size.y > size.x:  # Portrait
		card_hand.layout_direction = Control.LAYOUT_DIRECTION_VERTICAL
		card_hand.anchor_bottom = 1.0
		card_hand.anchor_left = 0.0
	else:  # Landscape
		card_hand.layout_direction = Control.LAYOUT_DIRECTION_HORIZONTAL
		card_hand.anchor_bottom = 1.0
		card_hand.anchor_right = 1.0
```

---

## 5. Scene Composition: Small, Reusable Components

### Current Problem: Monolithic Scenes

**Combat_2.tscn contains everything:**
- 50+ child nodes in single scene
- Camera, grid overlay, unit containers, UI layer, notification layer, hand UI
- All logic in Combat_2.gd (6,115 lines)

**When you need to change card hand UI:**
1. Open massive Combat_2.tscn
2. Find hand UI nodes deep in tree
3. Edit (risk breaking other systems)
4. Changes can't be reused in other scenes

### Solution: Component Architecture

#### Component Scene Structure
```
scenes/
├── combat/
│   ├── Combat.tscn              (master scene, lightweight)
│   ├── CombatGrid.tscn          (grid overlay + cell highlighting)
│   ├── CombatCamera.tscn        (camera + gesture controls)
│   └── components/
│       ├── UnitSprite.tscn      (ship sprite + health bars + tooltip)
│       ├── Projectile.tscn      (laser/missile sprite + animation)
│       ├── DamageNumber.tscn    (floating damage text)
│       └── StatusIcon.tscn      (burn/freeze icon above unit)
├── ui/
│   ├── CardHand.tscn            (card container + drag handling)
│   ├── Card.tscn                (single card display)
│   ├── PhaseIndicator.tscn      (current phase label)
│   ├── ResourceBar.tscn         (metal/crystals/fuel display)
│   ├── CombatTimer.tscn         (countdown bar)
│   └── Tooltip.tscn             (generic popup tooltip)
├── starmap/
│   ├── StarMap.tscn             (master scene)
│   ├── StarNode.tscn            (single node on map)
│   └── StarPath.tscn            (connection line between nodes)
└── hangar/
    ├── Hangar.tscn              (master scene)
    ├── ShipCard.tscn            (ship display + pilot slot + upgrades)
    ├── PilotCard.tscn           (pilot portrait + stats)
    └── UpgradeSlot.tscn         (upgrade icon + tooltip)
```

#### Example: UnitSprite.tscn Component

**Scene Tree:**
```
UnitSprite (Node2D)
├── Sprite (TextureRect)
├── HealthBars (VBoxContainer)
│   ├── ShieldBar (ProgressBar)
│   ├── ArmorBar (ProgressBar)
│   └── EnergyBar (ProgressBar)
├── StatusIcons (HBoxContainer)
│   └── (StatusIcon instances added dynamically)
├── SelectionRing (Sprite2D)  # Shows when unit selected
└── CollisionArea (Area2D)    # For mouse/touch detection
```

**Script (UnitSprite.gd):**
```gdscript
extends Node2D
class_name UnitSprite

signal unit_clicked(unit_data: Dictionary)
signal unit_long_pressed(unit_data: Dictionary)

@export var unit_data: Dictionary = {}

@onready var sprite: TextureRect = $Sprite
@onready var health_bars: VBoxContainer = $HealthBars
@onready var status_icons: HBoxContainer = $StatusIcons
@onready var selection_ring: Sprite2D = $SelectionRing

func initialize(data: Dictionary):
	unit_data = data
	sprite.texture = load(data["sprite_path"])
	sprite.custom_minimum_size = Vector2(data["size"], data["size"])
	update_health_bars()
	selection_ring.visible = false

func update_health_bars():
	$HealthBars/ShieldBar.value = unit_data["current_shield"]
	$HealthBars/ShieldBar.max_value = unit_data["max_shield"]
	$HealthBars/ArmorBar.value = unit_data["current_armor"]
	$HealthBars/ArmorBar.max_value = unit_data["max_armor"]
	$HealthBars/EnergyBar.value = unit_data["current_energy"]
	$HealthBars/EnergyBar.max_value = unit_data["max_energy"]

func add_status_icon(status: String, stacks: int):
	var icon = preload("res://scenes/ui/StatusIcon.tscn").instantiate()
	icon.set_status(status, stacks)
	status_icons.add_child(icon)

func set_selected(selected: bool):
	selection_ring.visible = selected

func _on_collision_area_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		unit_clicked.emit(unit_data)
	# Touch long-press detection for tooltip
	# ...
```

**Usage in Combat.tscn:**
```gdscript
# Combat.gd
func spawn_ship(ship_id: String, grid_pos: Vector2i):
	var ship_data = DataManager.get_ship_data(ship_id)
	var unit_sprite = preload("res://scenes/combat/components/UnitSprite.tscn").instantiate()

	unit_sprite.initialize(ship_data)
	unit_sprite.position = CombatManager.grid_to_world(grid_pos)
	unit_sprite.unit_clicked.connect(_on_unit_clicked)

	$UnitContainer.add_child(unit_sprite)
	return unit_sprite
```

**Benefits:**
✅ **Reusable**: UnitSprite works for players, enemies, turrets, bosses
✅ **Testable**: Can test component in isolation
✅ **Editable**: Change UnitSprite.tscn, all units update
✅ **Portable**: Copy component to other projects
✅ **Delegated**: UnitSprite handles its own tooltip, selection, animations

#### Example: CardHand.tscn Component

**Scene Tree:**
```
CardHand (Control)
├── PanelContainer (background)
├── CardContainer (HBoxContainer or VBoxContainer)
│   └── (Card.tscn instances added dynamically)
└── DrawButton (Button)
```

**Script (CardHand.gd):**
```gdscript
extends Control
class_name CardHand

signal card_played(card_data: Dictionary, target: Dictionary)
signal draw_requested()

@export var max_hand_size: int = 7
@export var card_spacing: int = 10

@onready var card_container: HBoxContainer = $CardContainer
@onready var draw_button: Button = $DrawButton

var cards_in_hand: Array[Node] = []

func add_card(card_data: Dictionary):
	if cards_in_hand.size() >= max_hand_size:
		push_warning("Hand full, cannot add card")
		return

	var card_node = preload("res://scenes/ui/Card.tscn").instantiate()
	card_node.initialize(card_data)
	card_node.card_dragged.connect(_on_card_dragged)
	card_node.card_dropped.connect(_on_card_dropped)

	card_container.add_child(card_node)
	cards_in_hand.append(card_node)

func _on_card_dropped(card: Node, target_position: Vector2):
	var target = _get_target_at_position(target_position)
	if target:
		card_played.emit(card.card_data, target)
		remove_card(card)
	else:
		card.return_to_hand()  # Invalid drop

func remove_card(card: Node):
	cards_in_hand.erase(card)
	card_container.remove_child(card)
	card.queue_free()

func clear_hand():
	for card in cards_in_hand:
		card.queue_free()
	cards_in_hand.clear()
```

**Now CardHand can be used in:**
- Combat scene (bottom drawer)
- Deck builder scene (full-screen grid)
- Card selection rewards (horizontal strip)

---

## 6. Signal-Based Communication: EventBus Pattern

### Current Problem: Direct References

**Combat_2.gd calls:**
```gdscript
CardHandManager.draw_card()
CombatGridManager.occupy_cell(pos, unit)
health_system.apply_damage(target, damage)
```

**This creates tight coupling:**
- Combat scene must know about all managers
- Can't swap managers or test in isolation
- Circular dependencies possible

### Solution: EventBus Singleton

**EventBus.gd (autoload):**
```gdscript
extends Node

# Combat Events
signal unit_spawned(unit_data: Dictionary, world_pos: Vector2)
signal unit_moved(unit_data: Dictionary, from: Vector2i, to: Vector2i)
signal unit_died(unit_data: Dictionary)
signal unit_damaged(unit_data: Dictionary, damage: int, element: String)

# Card Events
signal card_drawn(card_data: Dictionary)
signal card_played(card_data: Dictionary, caster: Dictionary, target: Dictionary)
signal deck_shuffled()
signal hand_full()

# Combat Phase Events
signal phase_changed(new_phase: int)
signal combat_started(scenario_id: String)
signal combat_ended(victory: bool, rewards: Dictionary)
signal wave_spawned(wave_index: int, enemies: Array)

# Effect Events
signal status_applied(unit: Dictionary, status: String, stacks: int)
signal status_expired(unit: Dictionary, status: String)
signal combo_triggered(combo_id: String, targets: Array)
signal ability_cast(caster: Dictionary, ability_id: String)

# UI Events
signal tooltip_requested(target: Node, data: Dictionary)
signal tooltip_hidden()
signal notification_posted(message: String, type: String, duration: float)

# Resource Events
signal resource_changed(resource_type: String, old_value: int, new_value: int)
signal resource_collected(resource_type: String, amount: int, source: String)

# Meta Events
signal scene_transition_requested(scene_path: String, data: Dictionary)
signal save_requested()
signal settings_changed(setting_name: String, new_value: Variant)
```

**Usage Example - Unit Takes Damage:**

**Before (Tight Coupling):**
```gdscript
# Combat_2.gd
func _on_projectile_hit(projectile: Dictionary, target: Dictionary):
	var damage = DamageCalculator.calculate_damage(projectile, target)
	health_system.apply_damage(target, damage)
	combat_ui.show_damage_number(target["position"], damage)
	if target["current_armor"] <= 0:
		_remove_unit(target)
		combat_stats.increment_kills()
```

**After (EventBus Decoupling):**
```gdscript
# CombatProjectileManager.gd
func _on_projectile_hit(projectile: Dictionary, target: Dictionary):
	EventBus.unit_damaged.emit(target, projectile["damage"], projectile["element"])

# DamageCalculator.gd (autoload)
func _ready():
	EventBus.unit_damaged.connect(_on_unit_damaged)

func _on_unit_damaged(unit: Dictionary, damage: int, element: String):
	var final_damage = apply_resistances(damage, element, unit)
	unit["current_armor"] -= final_damage

	if unit["current_armor"] <= 0:
		EventBus.unit_died.emit(unit)

# CombatUI.gd
func _ready():
	EventBus.unit_damaged.connect(_on_unit_damaged)

func _on_unit_damaged(unit: Dictionary, damage: int, element: String):
	show_damage_number(unit["position"], damage, element)

# CombatManager.gd
func _ready():
	EventBus.unit_died.connect(_on_unit_died)

func _on_unit_died(unit: Dictionary):
	remove_unit(unit)
	check_victory_conditions()
```

**Benefits:**
✅ **Decoupled**: Systems don't know about each other
✅ **Testable**: Can test DamageCalculator without loading Combat scene
✅ **Flexible**: Easily add new listeners (e.g., achievement system)
✅ **Debuggable**: Can log all events through EventBus
✅ **Moddable**: Mods can listen to events without modifying core code

### EventBus Best Practices

**DO:**
- Use for cross-system communication (combat → UI, card → effect)
- Emit events after state changes (unit_died after removing from grid)
- Include all relevant data in signal parameters
- Document expected signal parameters in comments

**DON'T:**
- Use for parent-child communication (use direct signals instead)
- Emit events in tight loops (performance cost)
- Modify emitter state in signal handlers (circular logic risk)
- Rely on signal handler execution order

---

## 7. Code Organization Best Practices

### Directory Structure

```
any-type-5/
├── project.godot
├── addons/
│   └── gdai-mcp-plugin-godot/
├── autoload/
│   ├── core/
│   │   ├── SeedManager.gd
│   │   ├── DataManager.gd
│   │   ├── GameState.gd
│   │   ├── EventBus.gd
│   │   ├── AudioManager.gd
│   │   ├── SettingsManager.gd
│   │   └── SaveManager.gd
│   ├── gameplay/
│   │   ├── CombatManager.gd
│   │   ├── DeckManager.gd
│   │   ├── EffectResolver.gd
│   │   └── DamageCalculator.gd
│   └── scenes/
│       ├── TraderManager.gd
│       ├── MiningManager.gd
│       ├── TreasureManager.gd
│       └── HangarManager.gd
├── scenes/
│   ├── combat/
│   │   ├── Combat.tscn
│   │   ├── Combat.gd                 (< 300 lines - orchestration only)
│   │   ├── CombatGrid.tscn
│   │   ├── CombatCamera.tscn
│   │   └── components/
│   │       ├── UnitSprite.tscn
│   │       ├── Projectile.tscn
│   │       ├── DamageNumber.tscn
│   │       └── StatusIcon.tscn
│   ├── starmap/
│   │   ├── StarMap.tscn
│   │   ├── StarMap.gd                (< 400 lines)
│   │   ├── StarNode.tscn
│   │   └── StarPath.tscn
│   ├── hangar/
│   │   ├── Hangar.tscn
│   │   ├── Hangar.gd                 (< 300 lines)
│   │   ├── ShipCard.tscn
│   │   ├── PilotCard.tscn
│   │   └── UpgradeSlot.tscn
│   ├── events/
│   │   ├── Trader.tscn
│   │   ├── Mining.tscn
│   │   ├── Treasure.tscn
│   │   └── BattleRewards.tscn
│   └── ui/
│       ├── CardHand.tscn
│       ├── Card.tscn
│       ├── ResourceBar.tscn
│       ├── PhaseIndicator.tscn
│       ├── Tooltip.tscn
│       └── Notification.tscn
├── data/
│   ├── cards/
│   │   ├── cards.csv
│   │   ├── card_templates.csv
│   │   └── card_combos.csv
│   ├── units/
│   │   ├── ships.csv
│   │   ├── pilots.csv
│   │   └── enemies.csv
│   ├── items/
│   │   ├── upgrades.csv
│   │   ├── relics.csv
│   │   └── consumables.csv
│   ├── scenarios/
│   │   ├── combat_scenarios.csv
│   │   ├── enemy_waves.csv
│   │   └── boss_patterns.csv
│   ├── progression/
│   │   ├── starmap_nodes.csv
│   │   ├── map_templates.csv
│   │   └── unlock_conditions.csv
│   ├── effects/
│   │   ├── status_effects.csv
│   │   ├── combos.csv
│   │   └── effect_templates.csv
│   └── meta/
│       ├── star_names.csv
│       ├── starting_loadouts.csv
│       └── difficulty_modifiers.csv
├── assets/
│   ├── backgrounds/
│   ├── ships/
│   ├── effects/
│   ├── ui/
│   ├── icons/
│   ├── audio/
│   │   ├── music/
│   │   └── sfx/
│   └── fonts/
├── scripts/
│   ├── utils/
│   │   ├── CSVParser.gd
│   │   ├── MathUtils.gd
│   │   ├── StringUtils.gd
│   │   └── ArrayUtils.gd
│   └── classes/
│       ├── Unit.gd               (class_name Unit)
│       ├── Card.gd               (class_name CardData)
│       ├── Effect.gd             (class_name EffectData)
│       └── StatusEffect.gd       (class_name StatusEffectData)
└── tests/
    ├── unit/
    │   ├── test_damage_calculator.gd
    │   ├── test_effect_resolver.gd
    │   └── test_deck_manager.gd
    └── integration/
        ├── test_combat_flow.gd
        └── test_card_effects.gd
```

### File Size Guidelines

**Autoloads (Singletons):**
- Core systems: 200-500 lines
- Gameplay systems: 300-600 lines
- Scene managers: 150-300 lines

**Scene Scripts:**
- Combat.gd: < 300 lines (delegates to autoloads)
- StarMap.gd: < 400 lines
- Hangar.gd: < 300 lines
- Components: < 150 lines each

**If a file exceeds these limits, split it!**

### Naming Conventions

**Scripts:**
- PascalCase for class_name: `class_name DamageCalculator`
- Descriptive scene script names: `Combat.gd`, `StarMap.gd`
- Component scripts match scene names: `UnitSprite.gd` for `UnitSprite.tscn`

**Signals:**
- snake_case with past tense: `unit_died`, `card_played`, `phase_changed`
- Include subject and action: `resource_collected`, `tooltip_requested`

**Functions:**
- snake_case: `calculate_damage()`, `apply_status_effect()`
- Prefix private functions: `_internal_helper_function()`
- Boolean functions as questions: `is_unit_alive()`, `can_afford_card()`

**Variables:**
- snake_case: `current_phase`, `max_hand_size`
- Constants: UPPER_SNAKE_CASE: `MAX_GRID_SIZE`, `DEFAULT_ARMOR`
- Type hints always: `var ship_data: Dictionary = {}`

### Documentation Standards

**Every autoload script:**
```gdscript
extends Node

## Brief description of singleton purpose
##
## Detailed explanation of responsibilities and usage.
## Include examples of common operations.
##
## Dependencies: List other autoloads this relies on
## Signals: List all emitted signals
## API: List public functions

# Configuration constants
const MAX_HAND_SIZE: int = 7
const DEFAULT_DRAW_COUNT: int = 3

# Internal state
var _current_deck: Array[String] = []
var _discard_pile: Array[String] = []

# Public API
func draw_cards(count: int) -> Array[Dictionary]:
	"""Draw {count} cards from deck. Returns array of card data."""
	# ...
```

**Component scripts:**
```gdscript
extends Control
class_name CardHand

## Card hand UI component
##
## Displays player's hand of cards, handles drag-and-drop card playing.
## Emits signals when cards are played or draw is requested.
##
## Usage:
##   var hand = CardHand.new()
##   hand.card_played.connect(_on_card_played)
##   hand.add_card(card_data)

signal card_played(card_data: Dictionary, target: Dictionary)
signal draw_requested()
```

---

## 8. Migration Strategy: Phased Restart

### Phase 1: Foundation (Week 1)
**Goal: Set up clean project structure with core autoloads**

- [ ] Create new Godot project `any-type-5`
- [ ] Set up directory structure (autoload/, scenes/, data/, assets/)
- [ ] Implement core autoloads:
  - [ ] EventBus.gd (with all signals defined)
  - [ ] GameState.gd (port from GameData.gd, clean up)
  - [ ] SeedManager.gd (copy from any-type-4, no changes needed)
  - [ ] DataManager.gd (refactor CSV loading, add template parsing)
- [ ] Migrate CSV databases to `data/` folder, reorganize:
  - [ ] Consolidate card_database → `data/cards/cards.csv`
  - [ ] Add `data/effects/effect_templates.csv`
  - [ ] Add `data/effects/status_effects.csv`
  - [ ] Add `data/effects/combos.csv`
- [ ] Copy assets folder wholesale (no changes needed)

**Test:** DataManager loads all CSVs, EventBus signals compile

### Phase 2: Effect System (Week 2)
**Goal: Build data-driven effect resolver before any scenes**

- [ ] Implement EffectResolver.gd autoload:
  - [ ] Template parser (parse `"stat:attack_speed,modifier:0.2"` strings)
  - [ ] Template handlers (`_template_modify_stat`, `_template_add_resource`, etc.)
  - [ ] Status effect application (read from status_effects.csv)
  - [ ] AoE targeting and falloff
  - [ ] Combo detection (read from combos.csv)
- [ ] Create effect_templates.csv with all card templates
- [ ] Update cards.csv with `effect_template` and `template_params` columns
- [ ] Write unit tests for EffectResolver:
  - [ ] Test each template type
  - [ ] Test AoE falloff calculations
  - [ ] Test combo triggers

**Test:** EffectResolver can execute all card effects from CSV without scenes

### Phase 3: Combat Systems (Week 3)
**Goal: Build combat autoloads and grid system**

- [ ] Implement CombatManager.gd autoload:
  - [ ] Grid management (occupy/free cells, queries)
  - [ ] Phase state machine (DEPLOY → TACTICAL → COMBAT → CLEANUP)
  - [ ] Unit spawning/despawning
  - [ ] Wave management (read from enemy_waves.csv)
  - [ ] Victory/defeat detection
- [ ] Implement DamageCalculator.gd autoload:
  - [ ] Hit chance calculation (accuracy vs evasion)
  - [ ] Critical hit rolls
  - [ ] Resistance calculations
  - [ ] Damage number spawning (via EventBus)
- [ ] Implement DeckManager.gd autoload (refactor CardHandManager):
  - [ ] Deck building functions
  - [ ] Draw/shuffle/discard mechanics
  - [ ] Hand size limits
- [ ] Wire up EventBus connections between systems

**Test:** CombatManager can run a full combat loop headlessly (no UI)

### Phase 4: Combat Components (Week 4)
**Goal: Build reusable combat UI components**

- [ ] Create `scenes/combat/components/UnitSprite.tscn`:
  - [ ] Sprite, health bars, status icons
  - [ ] Touch/click detection
  - [ ] Selection ring visual
  - [ ] Connect to EventBus (emit unit_clicked, listen to unit_damaged)
- [ ] Create `scenes/combat/components/Projectile.tscn`:
  - [ ] Sprite, travel animation
  - [ ] Hit detection
  - [ ] Emit EventBus.unit_damaged on hit
- [ ] Create `scenes/combat/components/DamageNumber.tscn`:
  - [ ] Floating text with fade-out
  - [ ] Element color-coding
  - [ ] Listen to EventBus.unit_damaged
- [ ] Create `scenes/ui/CardHand.tscn`:
  - [ ] Vertical/horizontal layout modes
  - [ ] Card drag-and-drop
  - [ ] Swipe-up drawer for mobile
- [ ] Create `scenes/ui/Card.tscn`:
  - [ ] Card frame, artwork, text
  - [ ] Drag handling
  - [ ] Glow effect for valid targets

**Test:** Spawn units and projectiles, verify visuals update from EventBus

### Phase 5: Combat Scene (Week 5)
**Goal: Assemble combat scene with portrait layout**

- [ ] Create `scenes/combat/Combat.tscn`:
  - [ ] CombatCamera (pinch zoom, swipe pan)
  - [ ] CombatGrid overlay (12×30 portrait grid)
  - [ ] UnitContainer (spawns UnitSprite components)
  - [ ] ProjectileContainer (spawns Projectile components)
  - [ ] CardHand component at bottom
  - [ ] PhaseIndicator, ResourceBar, CombatTimer UI
- [ ] Create `Combat.gd` (< 300 lines):
  - [ ] Call CombatManager.start_combat(scenario_id)
  - [ ] Listen to EventBus.unit_spawned → spawn UnitSprite
  - [ ] Listen to EventBus.phase_changed → update UI
  - [ ] Handle touch input → call CombatManager functions
  - [ ] NO business logic (all in autoloads)
- [ ] Create mobile controls:
  - [ ] Swipe-pan camera
  - [ ] Pinch-zoom
  - [ ] Tap-to-select units
  - [ ] Long-press for tooltip

**Test:** Play a full combat scenario on mobile (portrait mode)

### Phase 6: StarMap Scene (Week 6)
**Goal: Vertical portrait starmap with node navigation**

- [ ] Create `scenes/starmap/StarNode.tscn` component:
  - [ ] Button with node icon
  - [ ] Node type indicator (combat/treasure/shop/etc.)
  - [ ] Lock/unlock visual state
- [ ] Create `scenes/starmap/StarPath.tscn` component:
  - [ ] Line2D connecting nodes
  - [ ] Path availability state
- [ ] Create `scenes/starmap/StarMap.tscn`:
  - [ ] Vertical scrolling container
  - [ ] Node generation (read from map_nodes.csv)
  - [ ] Path validation
  - [ ] ResourceBar at top
  - [ ] Ship status button at bottom
- [ ] Create `StarMap.gd` (< 400 lines):
  - [ ] Generate map nodes on startup (via SeedManager)
  - [ ] Handle node taps → transition to event scenes
  - [ ] Save map state to GameState
  - [ ] NO combat logic (delegates to CombatManager)

**Test:** Generate random starmap, navigate nodes, transition to combat

### Phase 7: Hangar Scene (Week 7)
**Goal: Vertical mobile hangar with pilot/ship/upgrade management**

- [ ] Create `scenes/hangar/ShipCard.tscn` component:
  - [ ] Ship sprite, stats display
  - [ ] Pilot slot (tap to assign)
  - [ ] Upgrade slots (tap to assign)
  - [ ] Tooltip on long-press
- [ ] Create `scenes/hangar/PilotCard.tscn` component:
  - [ ] Portrait, name, ability
  - [ ] Tap to select for assignment
- [ ] Create `scenes/hangar/UpgradeSlot.tscn` component:
  - [ ] Upgrade icon, name
  - [ ] Tap to view/remove
- [ ] Create `scenes/hangar/Hangar.tscn`:
  - [ ] Single vertical ScrollContainer
  - [ ] Pilots section (vertical list)
  - [ ] Ships section (vertical list)
  - [ ] Tap-based assignment (no drag-drop)
- [ ] Create `HangarManager.gd` autoload:
  - [ ] Track pilot/ship/upgrade assignments
  - [ ] Validate assignment rules
  - [ ] Save to GameState

**Test:** Assign pilots and upgrades to ships, verify persistence

### Phase 8: Polish & Meta (Week 8)
**Goal: Settings, save/load, audio, menus**

- [ ] Implement SettingsManager.gd:
  - [ ] Graphics settings (resolution, fullscreen)
  - [ ] Audio settings (music/SFX volume)
  - [ ] Control settings (touch sensitivity)
  - [ ] Language selection (if applicable)
- [ ] Implement SaveManager.gd:
  - [ ] Save GameState to JSON file
  - [ ] Load saved games
  - [ ] Auto-save after each node
- [ ] Implement AudioManager.gd:
  - [ ] Music playback with crossfade
  - [ ] SFX pools (pre-load common sounds)
  - [ ] Audio ducking (lower music during SFX)
- [ ] Create main menu, pause menu, settings menu scenes
- [ ] Add screen transitions (fade, swipe)

**Test:** Full gameplay loop, save/load, settings persistence

---

## 9. Portrait Layout Specifics

### Grid Dimensions for Portrait

**Old (Landscape):** 25 columns × 20 rows = 500 cells
**New (Portrait):** 12 columns × 30 rows = 360 cells

**Cell Size:** 32px (same as before)
**Total Grid:** 384px wide × 960px tall

**Screen Breakdown (1080×1920):**
```
┌───────────────────────┐  1920px tall
│   Top UI (120px)      │  <- Resources, phase indicator
├───────────────────────┤
│                       │
│   Combat Grid         │  960px (30 rows × 32px)
│   (384px × 960px)     │
│   Centered            │
│                       │
├───────────────────────┤
│   Bottom Margin       │  120px (safe area for gestures)
├───────────────────────┤
│   Card Hand Drawer    │  720px (hidden, swipe up to reveal)
└───────────────────────┘
        1080px wide
```

**Zone Layout (30 rows):**
- Rows 0-5: Enemy spawn zone (6 rows)
- Rows 6-23: Combat area (18 rows)
- Rows 24-29: Player deploy zone (6 rows)

**Camera Settings:**
- Default zoom: 1.0 (show ~15 rows at once)
- Min zoom: 0.5 (see entire grid)
- Max zoom: 2.0 (close-up for precision)
- Smooth follow: Camera centers on action when combat starts

### Card Hand Drawer System

**Closed State (Combat View):**
- Cards hidden off-screen (y = 1920 + 720)
- Swipe-up hint visible (small arrow at bottom)
- Card count indicator visible (e.g., "5 Cards")

**Opening Transition:**
- User swipes up from bottom edge
- Drawer slides up (0.3s ease-out tween)
- Cards visible in vertical or horizontal layout
- Background dimming overlay (50% opacity) on combat area

**Open State (Card Selection):**
- Cards fully visible
- Tap card → Highlight valid targets on grid
- Tap target → Play card
- Swipe down or tap overlay → Close drawer

**Implementation:**
```gdscript
# CardHand.gd
func _input(event):
	if event is InputEventScreenDrag:
		if event.relative.y < -50:  # Swipe up threshold
			open_drawer()
		elif event.relative.y > 50:  # Swipe down threshold
			close_drawer()

func open_drawer():
	var tween = create_tween()
	tween.tween_property(self, "position:y", 1200, 0.3).set_ease(Tween.EASE_OUT)
	EventBus.card_drawer_opened.emit()

func close_drawer():
	var tween = create_tween()
	tween.tween_property(self, "position:y", 1920, 0.3).set_ease(Tween.EASE_OUT)
	EventBus.card_drawer_closed.emit()
```

---

## 10. CSV Template System Examples

### Example 1: Buff with Duration

**cards.csv:**
```csv
card_id,name,effect_template,template_params
alpha_strike,Alpha Strike,buff_multi,"stats:[movement_speed:3,damage:7],duration:5,target:self"
```

**EffectResolver._template_buff_multi():**
```gdscript
func _template_buff_multi(params: Dictionary, caster: Dictionary, target: Dictionary):
	var stats = parse_array(params["stats"])  # {movement_speed: 3, damage: 7}
	var duration = float(params["duration"])
	var target_unit = target if params.get("target", "single") == "self" else target

	for stat in stats:
		var value = stats[stat]
		_add_timed_buff(target_unit, stat, value, duration)

func _add_timed_buff(unit: Dictionary, stat: String, value: float, duration: float):
	if not unit.has("active_buffs"):
		unit["active_buffs"] = []

	var buff = {
		"stat": stat,
		"value": value,
		"remaining": duration,
		"original": unit["temp_stats"].get(stat, 0.0)
	}

	unit["active_buffs"].append(buff)
	unit["temp_stats"][stat] = unit["temp_stats"].get(stat, 0.0) + value

	EventBus.notification_posted.emit("+" + str(value) + " " + stat.to_upper(), "buff", 2.0)
```

**Update Loop (in CombatManager):**
```gdscript
func _process(delta):
	if combat_active:
		for unit in all_units:
			if unit.has("active_buffs"):
				for buff in unit["active_buffs"]:
					buff["remaining"] -= delta
					if buff["remaining"] <= 0:
						# Buff expired
						unit["temp_stats"][buff["stat"]] = buff["original"]
						unit["active_buffs"].erase(buff)
						EventBus.notification_posted.emit(buff["stat"].to_upper() + " expired", "debuff", 1.0)
```

### Example 2: AoE Projectile with Combo Trigger

**cards.csv:**
```csv
card_id,name,effect_template,template_params
missile_lock,Missile Lock,spawn_projectile,"damage:50,element:explosive,aoe:1,sprite:res://projectile.png,combo_trigger:explosive"
```

**EffectResolver._template_spawn_projectile():**
```gdscript
func _template_spawn_projectile(params: Dictionary, caster: Dictionary, target: Dictionary):
	var projectile_data = {
		"damage": int(params["damage"]),
		"element": params["element"],
		"aoe_range": int(params.get("aoe", 0)),
		"sprite_path": params["sprite"],
		"caster": caster,
		"target": target,
		"combo_trigger": params.get("combo_trigger", "")
	}

	EventBus.projectile_spawned.emit(projectile_data)

# Combat.gd listens to projectile_spawned, creates visual:
func _on_projectile_spawned(data: Dictionary):
	var projectile = preload("res://scenes/combat/components/Projectile.tscn").instantiate()
	projectile.initialize(data)
	projectile.hit_target.connect(_on_projectile_hit)
	$ProjectileContainer.add_child(projectile)

func _on_projectile_hit(projectile_data: Dictionary):
	# Get all units in AoE
	var targets = CombatManager.get_units_in_aoe(
		projectile_data["target"]["grid_pos"],
		projectile_data["aoe_range"],
		"enemy"  # Faction filter
	)

	for target in targets:
		# Calculate damage for each target
		var hit_result = DamageCalculator.calculate_hit(projectile_data["caster"], target)

		if hit_result["hit"]:
			EventBus.unit_damaged.emit(target, hit_result["damage"], projectile_data["element"])

			# Check combo triggers
			if projectile_data["combo_trigger"] != "":
				EffectResolver.check_combo_triggers(
					projectile_data["caster"],
					target,
					projectile_data["combo_trigger"]
				)
```

### Example 3: Status Effect with Nested On-Hit Effect

**cards.csv:**
```csv
card_id,name,effect_template,template_params
incendiary_rounds,Incendiary Rounds,modify_damage,"element:fire,bonus:3,duration:combat,on_hit:apply_status(burn,1,0.25)"
```

**EffectResolver._template_modify_damage():**
```gdscript
func _template_modify_damage(params: Dictionary, caster: Dictionary, target: Dictionary):
	var element = params["element"]
	var bonus = int(params["bonus"])
	var duration = params["duration"]

	# Apply damage type modifier
	if duration == "combat":
		target["temp_damage_type"] = element
		target["temp_damage_bonus"] = bonus

	# Parse nested on-hit effect
	if params.has("on_hit"):
		var on_hit_effect = parse_nested_effect(params["on_hit"])
		# on_hit_effect = {template: "apply_status", params: ["burn", 1, 0.25]}

		target["on_hit_effects"] = target.get("on_hit_effects", [])
		target["on_hit_effects"].append(on_hit_effect)

	EventBus.notification_posted.emit("Damage type: " + element.to_upper(), "buff", 2.0)

# When projectile hits in combat:
func process_hit(attacker: Dictionary, target: Dictionary):
	# ... damage calculation ...

	# Process on-hit effects
	if attacker.has("on_hit_effects"):
		for effect in attacker["on_hit_effects"]:
			if randf() <= effect["chance"]:  # Roll for proc
				_execute_effect(effect["template"], effect["params"], attacker, target)
```

---

## 11. Quick Reference: Porting Checklist

When migrating specific features from any-type-4 → any-type-5:

### Ship Spawning
- [ ] **Old:** Combat_3.gd `spawn_unit()` function (lines 500-600)
- [ ] **New:** CombatManager.spawn_unit() autoload function
- [ ] **Visual:** Combat.gd listens to EventBus.unit_spawned, instantiates UnitSprite.tscn component

### Card Playing
- [ ] **Old:** CardHandManager.play_card() + CardEffects.apply_X_effect()
- [ ] **New:** DeckManager.play_card() emits EventBus.card_played → EffectResolver.resolve_card_effect()
- [ ] **Visual:** CardHand.tscn component handles drag-drop, emits card_played signal

### Damage Application
- [ ] **Old:** health_system.apply_damage() in Combat scripts
- [ ] **New:** EventBus.unit_damaged.emit() → DamageCalculator._on_unit_damaged() → Updates unit.current_armor
- [ ] **Visual:** DamageNumber.tscn listens to unit_damaged, spawns floating text

### Status Effects
- [ ] **Old:** CombatStatusEffectManager class in Combat_3.gd
- [ ] **New:** status_effects.csv database + EffectResolver.apply_status_effect()
- [ ] **Visual:** StatusIcon.tscn component added to UnitSprite dynamically

### Grid Positioning
- [ ] **Old:** CombatGridManager.occupy_cell() autoload (separate from combat)
- [ ] **New:** CombatManager.occupy_cell() (grid management is part of combat state)
- [ ] **Visual:** Combat.gd calls CombatManager.grid_to_world() for sprite positioning

### Enemy Waves
- [ ] **Old:** CombatWaveManager.spawn_wave() autoload + CombatEnemyManager class
- [ ] **New:** CombatManager.spawn_wave() (reads enemy_waves.csv)
- [ ] **Visual:** Combat.gd listens to EventBus.wave_spawned, shows wave notification

---

## 12. Final Recommendations

### Do's for Any-Type-5

✅ **Start with autoloads** - Build all core systems (CombatManager, EffectResolver, DeckManager) BEFORE scenes
✅ **Write unit tests** - Test EffectResolver templates, DamageCalculator formulas in isolation
✅ **Design for portrait** - Every UI mockup should be 1080×1920 vertical
✅ **Component-first** - Build UnitSprite, Card, StarNode components before full scenes
✅ **EventBus everything** - Use signals for all cross-system communication
✅ **CSV-driven balance** - Damage numbers, durations, chances all in CSV templates
✅ **Keep scenes thin** - Scene scripts < 300 lines, delegate to autoloads
✅ **Document as you go** - Write docstrings for every autoload function

### Don'ts for Any-Type-5

❌ **Don't nest logic in scenes** - No business logic in Combat.gd, only orchestration
❌ **Don't hardcode effects** - No `if card_name == "Strike"` branches, use templates
❌ **Don't reference scenes directly** - No `get_node("/root/Combat/UnitContainer")`, use EventBus
❌ **Don't create giant files** - If file > 500 lines, split it
❌ **Don't couple systems** - No CombatManager calling DeckManager directly, use EventBus
❌ **Don't assume landscape** - No 1920×1080 hardcoded dimensions
❌ **Don't skip tests** - EffectResolver needs unit tests before using in scenes
❌ **Don't delay refactoring** - If you see spaghetti forming, split files immediately

---

## 13. Example File: CombatManager.gd (Skeleton)

```gdscript
extends Node

## CombatManager - Master combat orchestrator
##
## Responsibilities:
## - Phase state management (DEPLOY → TACTICAL → COMBAT → CLEANUP)
## - Grid cell occupation and queries
## - Unit spawning, tracking, and removal
## - Wave management and scenario loading
## - Victory/defeat condition checking
##
## Dependencies: DataManager, EventBus, SeedManager
## Used by: Combat.gd scene (listens to signals, calls public functions)

# Phase enum
enum Phase {
	DEPLOY,          # Initial ship deployment
	PRE_TACTICAL,    # Enemy spawn, pre-tactical abilities
	TACTICAL,        # Player draws cards, moves ships
	PRE_COMBAT,      # Ability queue execution
	COMBAT,          # Auto-combat (20 seconds)
	CLEANUP          # Discard cards, clear effects
}

# Grid configuration
const GRID_ROWS: int = 30
const GRID_COLS: int = 12
const CELL_SIZE: int = 32

# State
var current_phase: Phase = Phase.DEPLOY
var current_scenario: String = ""
var combat_active: bool = false
var combat_timer: float = 20.0

# Grid and units
var grid: Array = []  # 2D array of unit references
var all_units: Array[Dictionary] = []
var player_units: Array[Dictionary] = []
var enemy_units: Array[Dictionary] = []

# Signals
signal phase_changed(new_phase: Phase)
signal unit_spawned(unit_data: Dictionary, grid_pos: Vector2i)
signal unit_died(unit_data: Dictionary)
signal combat_ended(victory: bool, rewards: Dictionary)

func _ready():
	_initialize_grid()
	EventBus.unit_damaged.connect(_on_unit_damaged)

func _initialize_grid():
	grid.resize(GRID_ROWS)
	for row in GRID_ROWS:
		grid[row] = []
		grid[row].resize(GRID_COLS)
		for col in GRID_COLS:
			grid[row][col] = null

# ============================================================================
# PUBLIC API - COMBAT CONTROL
# ============================================================================

func start_combat(scenario_id: String) -> void:
	"""Initialize combat with given scenario"""
	print("CombatManager: Starting combat with scenario: ", scenario_id)
	current_scenario = scenario_id
	current_phase = Phase.DEPLOY
	combat_active = false
	all_units.clear()
	player_units.clear()
	enemy_units.clear()
	_initialize_grid()

	# Load scenario data (enemy waves, grid size, etc.)
	var scenario_data = DataManager.get_scenario_data(scenario_id)
	# ... configure combat based on scenario ...

	phase_changed.emit(current_phase)

func advance_phase() -> void:
	"""Progress to next combat phase"""
	match current_phase:
		Phase.DEPLOY:
			current_phase = Phase.PRE_TACTICAL
		Phase.PRE_TACTICAL:
			current_phase = Phase.TACTICAL
		Phase.TACTICAL:
			current_phase = Phase.PRE_COMBAT
		Phase.PRE_COMBAT:
			current_phase = Phase.COMBAT
			combat_active = true
			combat_timer = 20.0
		Phase.COMBAT:
			current_phase = Phase.CLEANUP
			combat_active = false
		Phase.CLEANUP:
			_check_victory_conditions()

	phase_changed.emit(current_phase)
	print("CombatManager: Phase changed to ", Phase.keys()[current_phase])

func end_combat(victory: bool) -> void:
	"""End combat and emit results"""
	combat_active = false
	var rewards = _calculate_rewards(victory)
	combat_ended.emit(victory, rewards)

# ============================================================================
# PUBLIC API - GRID MANAGEMENT
# ============================================================================

func occupy_cell(pos: Vector2i, unit: Dictionary) -> bool:
	"""Mark grid cell as occupied by unit. Returns false if already occupied."""
	if not _is_valid_grid_pos(pos):
		push_error("Invalid grid position: ", pos)
		return false

	if grid[pos.y][pos.x] != null:
		push_warning("Grid cell already occupied: ", pos)
		return false

	grid[pos.y][pos.x] = unit
	return true

func free_cell(pos: Vector2i) -> void:
	"""Mark grid cell as empty"""
	if _is_valid_grid_pos(pos):
		grid[pos.y][pos.x] = null

func get_unit_at(pos: Vector2i) -> Dictionary:
	"""Get unit at grid position, or empty dict if none"""
	if _is_valid_grid_pos(pos):
		return grid[pos.y][pos.x] if grid[pos.y][pos.x] != null else {}
	return {}

func get_units_in_aoe(center: Vector2i, range_val: int, faction_filter: String) -> Array[Dictionary]:
	"""Get all units within AoE range of center position"""
	var units_in_range: Array[Dictionary] = []

	for row in range(max(0, center.y - range_val), min(GRID_ROWS, center.y + range_val + 1)):
		for col in range(max(0, center.x - range_val), min(GRID_COLS, center.x + range_val + 1)):
			var unit = grid[row][col]
			if unit != null:
				# Check Manhattan distance
				var distance = abs(row - center.y) + abs(col - center.x)
				if distance <= range_val:
					if faction_filter == "" or unit["faction"] == faction_filter:
						units_in_range.append(unit)

	return units_in_range

# ============================================================================
# PUBLIC API - UNIT MANAGEMENT
# ============================================================================

func spawn_unit(ship_id: String, faction: String, grid_pos: Vector2i) -> Dictionary:
	"""Spawn a unit from ship database at grid position"""
	var ship_data = DataManager.get_ship_data(ship_id)
	if ship_data.is_empty():
		push_error("Ship not found: ", ship_id)
		return {}

	var unit = ship_data.duplicate(true)
	unit["faction"] = faction
	unit["grid_pos"] = grid_pos
	unit["current_armor"] = unit["armor"]
	unit["current_shield"] = unit["shield"]
	unit["current_energy"] = unit.get("starting_energy", 0)
	unit["temp_stats"] = {}  # For buffs/debuffs
	unit["active_statuses"] = {}  # For burn, freeze, etc.

	if not occupy_cell(grid_pos, unit):
		push_error("Cannot spawn unit, cell occupied: ", grid_pos)
		return {}

	all_units.append(unit)
	if faction == "player":
		player_units.append(unit)
	else:
		enemy_units.append(unit)

	unit_spawned.emit(unit, grid_pos)
	return unit

func remove_unit(unit: Dictionary) -> void:
	"""Remove unit from combat (death or retreat)"""
	free_cell(unit["grid_pos"])
	all_units.erase(unit)
	player_units.erase(unit)
	enemy_units.erase(unit)
	unit_died.emit(unit)

func get_units_by_faction(faction: String) -> Array[Dictionary]:
	"""Get all units of a faction"""
	if faction == "player":
		return player_units
	elif faction == "enemy":
		return enemy_units
	else:
		return []

# ============================================================================
# PUBLIC API - WAVE MANAGEMENT
# ============================================================================

func spawn_wave(wave_index: int) -> void:
	"""Spawn enemy wave from scenario data"""
	var wave_data = DataManager.get_wave_data(current_scenario, wave_index)
	if wave_data.is_empty():
		push_warning("No wave data for wave ", wave_index)
		return

	for enemy_spawn in wave_data["enemies"]:
		spawn_unit(enemy_spawn["ship_id"], "enemy", enemy_spawn["grid_pos"])

	EventBus.wave_spawned.emit(wave_index)

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	"""Convert grid coordinates to world position"""
	return Vector2(grid_pos.x * CELL_SIZE, grid_pos.y * CELL_SIZE)

func world_to_grid(world_pos: Vector2) -> Vector2i:
	"""Convert world position to grid coordinates"""
	return Vector2i(int(world_pos.x / CELL_SIZE), int(world_pos.y / CELL_SIZE))

func _is_valid_grid_pos(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < GRID_COLS and pos.y >= 0 and pos.y < GRID_ROWS

# ============================================================================
# INTERNAL EVENT HANDLERS
# ============================================================================

func _on_unit_damaged(unit: Dictionary, damage: int, element: String):
	"""React to unit taking damage (check for death)"""
	if unit["current_armor"] <= 0 and unit.get("current_shield", 0) <= 0:
		remove_unit(unit)

func _check_victory_conditions():
	"""Check if combat should end"""
	if enemy_units.is_empty():
		end_combat(true)
	elif player_units.is_empty():
		end_combat(false)
	else:
		# Continue to next turn
		advance_phase()

func _calculate_rewards(victory: bool) -> Dictionary:
	"""Calculate rewards based on combat outcome"""
	if victory:
		return {
			"metal": 50,
			"crystals": 10,
			"cards_offered": 3
		}
	else:
		return {}

# ============================================================================
# COMBAT LOOP
# ============================================================================

func _process(delta):
	if combat_active and current_phase == Phase.COMBAT:
		combat_timer -= delta
		EventBus.combat_timer_updated.emit(combat_timer)

		if combat_timer <= 0:
			advance_phase()  # Move to CLEANUP
```

---

## Conclusion

Restarting **any-type-5** is the right call. Your current project has reached the complexity ceiling where adding features becomes painful. By following this guide, you'll build a:

1. **Maintainable** codebase (small files, clear responsibilities)
2. **Extensible** architecture (add cards/effects via CSV, no code changes)
3. **Mobile-optimized** game (portrait layout, touch controls from day one)
4. **Testable** system (unit test autoloads independently)
5. **Scalable** structure (add features without bloating core systems)

**Remember:**
- Singletons for cross-cutting concerns (CombatManager, EffectResolver, DeckManager)
- Components for reusable UI (UnitSprite, Card, StarNode)
- EventBus for decoupling (no direct references between systems)
- CSV templates for data-driven effects (balancing without code)
- Portrait-first design (12×30 grid, vertical layouts)

Start with Phase 1 (foundation), get the autoloads right, and the rest will flow naturally. You've already proven you can build this game - now build it *right*.

Good luck with any-type-5! 🚀
