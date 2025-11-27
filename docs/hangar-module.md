# Hangar Module Design & Implementation Guide

## Module Overview

The **Hangar Module** is the fleet management and ship information hub for Any-Type-7. Players use the Hangar to:
- View their ship roster
- Inspect detailed ship statistics (17 stats per ship)
- View applied upgrades (earned from sector exploration)
- View ship abilities and equipment
- **Swipe right** → Navigate to Deploy screen
- *(Future)* Assign pilots and crew

**Design Philosophy**: The Hangar is a **view-only** module - upgrades are earned and applied during sector exploration encounters (traders, loot, mission rewards), not purchased here. The Hangar serves as a testing ground for the CSV-driven data architecture and provides a low-complexity entry point for prototyping before tackling combat or sector exploration.

**Navigation Flow**: Hangar ↔ Deploy Screen (swipe left/right)
- **Deploy Screen**: Shows first 5 rows of combat grid (15 lanes × 5 files) where players place ships
- **Combat Preview**: Right side shows enemy spawners and their intents (if in combat encounter)

---

## UI/UX Design

### Platform Constraints

- **Orientation**: Portrait only (1080×2340, 19.5:9 aspect ratio)
- **Input**: Touch-first design (tap, drag, long-press)
- **Touch Targets**: Minimum 200×200px for interactive elements
- **Font Sizes**: Minimum 32px for readability on mobile
- **Safe Areas**: Account for device notches and navigation bars

### Two-Screen Flow Architecture

The Hangar uses a **two-screen navigation pattern** optimized for portrait mobile:

#### Screen 1: Ship Roster (Main View)
```
┌─────────────────────────────┐
│  Metal: 500  Crystals: 200  │ ← Resource Bar (always visible)
│  Fuel: 150                  │
├─────────────────────────────┤
│                             │
│  ┌──────┐ ┌──────┐ ┌──────┐│ ← Ship Card Grid (2-3 columns)
│  │ Ship │ │ Ship │ │ Ship ││   Large touch targets
│  │  #1  │ │  #2  │ │  #3  ││   Show: Icon, Name, Health Bar
│  │      │ │      │ │      ││   Upgrade indicators (dots/glow)
│  └──────┘ └──────┘ └──────┘│
│                             │
│  ┌──────┐ ┌──────┐  [+]    │ ← Empty slots for unlocked ships
│  │ Ship │ │ Ship │  Add    │
│  │  #4  │ │  #5  │  Ship   │
│  └──────┘ └──────┘         │
│                             │
│  (Scrollable grid)          │
│                             │
│         ← Swipe →           │ ← Swipe gestures for navigation
│                             │
├─────────────────────────────┤
│  [HANGAR]  [DEPLOY]  [MAP]  │ ← Bottom Navigation tabs
└─────────────────────────────┘
```

**Interactions**:
- **Tap Ship Card** → Navigate to Ship Detail screen
- **Swipe Right** → Navigate to Deploy screen
- **Swipe Left** → Navigate to Map screen (sector exploration)
- **Long-Press Ship Card** → Quick stats tooltip (future)
- **Scroll Vertically** → View all ships in roster

#### Screen 2: Ship Detail (Per-Ship View)
```
┌─────────────────────────────┐
│  ← Back      BASIC FIGHTER  │ ← Header with ship name
├─────────────────────────────┤
│                             │
│     ╔═══════════════╗       │ ← Ship Visual (icon/sprite)
│     ║   [Fighter]   ║       │   Size indicator (1×1, 2×2, etc.)
│     ╚═══════════════╝       │
│                             │
│  ═══ DEFENSIVE STATS ═══    │ ← Stat categories (read-only)
│  Hull Points        120     │   Values shown include base + upgrades
│  Shield Points       80     │
│  Armor                5     │
│  Size               1×1     │
│                             │
│  ═══ OFFENSIVE STATS ═══    │
│  Damage              25     │
│  Projectiles          2     │
│  Attack Speed       1.2     │
│  Attack Range         8     │
│                             │
│  ═══ MOBILITY ═══           │
│  Movement Speed     3.0     │
│                             │
│  ═══ ACCURACY ═══           │
│  Accuracy            50     │
│  Evasion             30     │
│                             │
│  ═══ CRITICAL ═══           │
│  Precision           20     │
│  Reinforced Armor    10     │
│                             │
│  ═══ ABILITY ═══            │
│  Energy Points      100     │
│  Amplitude           50     │
│  Frequency           10     │
│                             │
│  ═══ RESISTANCE ═══         │
│  Resilience           0     │
│                             │
│  ─── ABILITIES ────────     │ ← Ship abilities from CSV
│  • Missile Barrage          │
│    └ Trigger: Explosive     │
│  • Point Defense System     │
│    └ Trigger: Ice           │
│                             │
│  ─── APPLIED UPGRADES ───   │ ← Upgrades earned from exploration
│  [Reinforced Hull] Common   │   (Tap to view upgrade details)
│  [Adv. Targeting] Rare      │
│                             │
│  (Scrollable content)       │
│                             │
├─────────────────────────────┤
│          [Deploy]           │ ← Action Button (future)
└─────────────────────────────┘
```

**Interactions**:
- **Tap Ability** → Show ability details tooltip (future)
- **Tap Upgrade Badge** → Show upgrade details and stat contribution
- **Swipe Left/Right** → Switch to previous/next ship (future)
- **Tap [← Back]** → Return to Ship Roster

#### Screen 3: Deploy Screen (Swipe Right from Roster)

**Note**: This screen is part of the combat module integration, documented here for navigation context.

```
┌─────────────────────────────┐
│  Deploying Ships │ Combat   │ ← Status indicator
├─────────────────────────────┤
│                             │
│  ═══ DEPLOYMENT GRID ═══    │ ← First 5 files of 15×25 grid
│                             │
│  Lane 1  [   ][   ][   ][   ][▓▓▓]│ ← Player zone (left 4 files)
│  Lane 2  [   ][   ][   ][   ][▓▓▓]│   Enemy zone (right, grayed)
│  Lane 3  [   ][   ][   ][   ][▓▓▓]│
│  ...     [   ][   ][   ][   ][▓▓▓]│
│  Lane 7  [S1 ][   ][   ][   ][▓▓▓]│ ← Center lane (player start)
│  ...     [   ][   ][   ][   ][▓▓▓]│
│  Lane 15 [   ][   ][   ][   ][▓▓▓]│
│                             │
│  ─── AVAILABLE SHIPS ────   │ ← Ship selection bar (bottom)
│  [Ship1] [Ship2] [Ship3]    │   Drag to grid to deploy
│                             │
│  ─── ENEMY SPAWNERS ────    │ ← Right side panel (if in combat)
│  Spawner A: 3 Fighters      │   Shows enemy intents
│  Spawner B: 1 Frigate       │
│  Wave Timer: 30s            │
│                             │
│         ← Swipe →           │ ← Swipe left to return to Hangar
│                             │
├─────────────────────────────┤
│  [HANGAR]  [DEPLOY]  [MAP]  │ ← Bottom Navigation
└─────────────────────────────┘
```

**Interactions**:
- **Swipe Left** → Return to Hangar (Ship Roster)
- **Drag Ship** → Place on deployment grid (lanes 1-15, files 1-4)
- **Tap Deployed Ship** → Remove from grid, return to available ships
- **View Enemy Spawners** → Shows enemy composition and spawn timing (if in combat)

**Integration Notes**:
- Deploy screen shows **first 5 files** of the full 15×25 combat grid
- Player can only place ships in **files 1-4** (left side)
- File 5 (right edge) shows enemy spawner zone (grayed out, non-interactive)
- Enemy spawners and intents only visible when in active combat encounter
- This screen is implemented as part of the Combat Module, not Hangar

---

## Features Breakdown

### Phase 1: Core Ship Management (MVP Prototype)
- Load 3 ships from `ship_stat_database.csv`
- Display ship roster as grid of cards
- Navigate from roster → ship detail
- Show all 17 stats on detail screen (read-only display)
- Display resource counts (Metal, Crystals, Fuel) - informational only
- Show applied upgrades (earned from sector exploration)
- Calculate and display modified stats (base + upgrade bonuses)

### Phase 2: Abilities Display
- Load abilities from `ability_database.csv`
- Display ship's abilities on detail screen
- Show ability metadata: Trigger type, element, damage, cooldown
- Tooltip/expand for full ability description (future)

### Phase 3: Upgrade Details View (Future)
- Tap upgrade badge → Show detailed upgrade information
- Display upgrade contribution to stats (e.g., "+10% Hull = +12 HP")
- Show upgrade rarity and description
- Visual indication of which stats are affected

### Phase 4: Polish & Enhancement
- Ship visual representation (icons/sprites)
- Stat category collapsing/expanding
- Swipe navigation between ships
- Upgrade badges with rarity color coding
- Visual feedback (animations, transitions)
- Long-press quick stats preview on roster

### Phase 5: Integration (Post-Prototype)
- **Swipe navigation** to Deploy screen (right) and Map screen (left)
- Deploy screen shows first 5 files of combat grid for ship placement
- Display enemy spawners and intents on Deploy screen (if in combat)
- Mark ships as "In Combat" (grayed out on roster, can't deploy)
- Mark ships as "Damaged" after combat (reduced hull/shields displayed)
- Ship repair interface (if damaged, restore hull/shields for resource cost)
- Pilot assignment system
- Equipment slot system
- Receive upgrades from other modules via EventBus signals
- Real-time UI updates when ships are deployed/damaged/repaired

---

## Data Dependencies

### Required CSV Files

#### 1. `ship_stat_database.csv` (POPULATED - 3 ships)
```
ship_id, ship_name, hull_points, shield_points, armor, size_width, size_height,
damage, projectiles, attack_speed, attack_range, movement_speed, accuracy, evasion,
precision, reinforced_armor, energy_points, amplitude, frequency, resilience
```

**Current Ships**:
- `basic_interceptor` (1×1, fast, low HP)
- `basic_fighter` (1×1, balanced)
- `basic_frigate` (2×2, tanky)

**17 Stats Per Ship**:
- **Defensive**: Hull Points, Shield Points, Armor, Size (W×H)
- **Offensive**: Damage, Projectiles, Attack Speed, Attack Range
- **Mobility**: Movement Speed
- **Accuracy**: Accuracy, Evasion
- **Critical**: Precision, Reinforced Armor
- **Ability**: Energy Points, Amplitude, Frequency
- **Resistance**: Resilience

#### 2. `ship_upgrade_database.csv` (POPULATED - 40+ upgrades)
```
upgrade_id, upgrade_name, rarity, affected_stat, bonus_type, bonus_value,
cost_metal, cost_crystals, description
```

**Rarity Tiers**: Common, Uncommon, Rare, Epic, Legendary

**Affected Stats**: Hull, Shields, Armor, Damage, Attack_Speed, Movement_Speed, Accuracy, Evasion, Precision, Energy, etc.

**Bonus Types**:
- `percentage` → Multiply stat by (1 + bonus_value)
- `flat` → Add bonus_value to stat

#### 3. `ability_database.csv` (POPULATED - 34+ abilities)
```
ability_id, ability_name, description, trigger_type, element, base_damage,
cooldown, energy_cost, projectile_count, aoe_radius, status_effect,
status_duration, combo_synergy
```

**Trigger Types**: Explosive, Fire, Ice, Lightning, Acid, Gravity, None

**Elements**: Fire, Ice, Lightning, Corrosive, Gravity, Kinetic, Energy

#### 4. `status_effects.csv` (POPULATED)
Used for displaying ability effects (Burn, Freeze, Static, etc.)

#### 5. `elemental_combos.csv` (POPULATED)
Used for showing combo potential in ability tooltips

---

## Technical Architecture

### Required Autoload Singletons

#### 1. EventBus.gd (~50 lines)
Centralized signal hub for decoupled communication.

**Signals**:
```gdscript
# Resource changes
signal resource_changed(resource_type: String, new_amount: int)

# Ship events
signal ship_selected(ship_id: String)
signal ship_upgraded(ship_id: String, upgrade_id: String)
signal ship_stats_changed(ship_id: String, stat_name: String, new_value)

# Navigation
signal screen_changed(screen_name: String)
```

#### 2. DataManager.gd (~150 lines)
Loads and caches CSV data, provides query interface.

**Responsibilities**:
- Parse CSV files on startup
- Cache data in dictionaries (indexed by ID)
- Provide getter functions: `get_ship(id)`, `get_upgrade(id)`, `get_ability(id)`
- Handle type conversion (string → int/float)

**API**:
```gdscript
func get_ship(ship_id: String) -> Dictionary
func get_all_ships() -> Array[Dictionary]
func get_upgrade(upgrade_id: String) -> Dictionary
func get_upgrades_for_stat(stat_name: String) -> Array[Dictionary]
func get_ability(ability_id: String) -> Dictionary
```

#### 3. ResourceManager.gd (~100 lines)
Tracks player resources (Metal, Crystals, Fuel).

**Responsibilities**:
- Track current resource amounts
- Add/subtract resources (called by other modules, not Hangar)
- Emit signals on change (via EventBus)
- Persist resources (future: SaveManager integration)

**Hangar Usage**: Display-only (shows current resource counts in top bar)

**API**:
```gdscript
func get_resource(type: String) -> int
func add_resource(type: String, amount: int)
func spend_resource(type: String, amount: int) -> bool
```

#### 4. GameState.gd (~150 lines)
Tracks game state including ship roster and applied upgrades.

**Responsibilities**:
- Maintain ship roster (which ships are owned)
- Track applied upgrades per ship (upgrades applied by sector exploration module)
- Calculate modified ship stats (base + upgrades)
- Persist state (future: SaveManager integration)

**Hangar Usage**: Read-only access to ship data and calculated stats

**API**:
```gdscript
func get_owned_ships() -> Array[String]  # Array of ship_ids
func get_ship_stats(ship_id: String) -> Dictionary  # Base stats + upgrades calculated
func apply_upgrade(ship_id: String, upgrade_id: String)  # Called by other modules, not Hangar
func get_applied_upgrades(ship_id: String) -> Array[String]  # List of upgrade_ids
func remove_upgrade(ship_id: String, upgrade_id: String)  # Future: upgrade removal
```

---

## Implementation Plan

### Step 1: Core Infrastructure (30 mins)
- [ ] Create `autoload/EventBus.gd` with ship/resource signals
- [ ] Create `autoload/DataManager.gd` with CSV loading
- [ ] Create `autoload/ResourceManager.gd` with resource tracking
- [ ] Create `autoload/GameState.gd` with ship roster management and stat calculation
- [ ] Configure autoloads in `project.godot`
- [ ] Test CSV loading on game start
- [ ] Add test data: Pre-populate GameState with 3 ships and some sample upgrades for testing

### Step 2: Ship Roster Screen (45 mins)
- [ ] Create `scenes/hangar/ship_roster.tscn`
- [ ] Add resource bar at top (Metal, Crystals, Fuel) - display only
- [ ] Create `scenes/hangar/components/ship_card.tscn` component
  - Ship name label
  - Health bar (hull + shields)
  - Ship icon placeholder
  - Upgrade indicator (visual glow/dots showing upgrade count)
- [ ] Populate grid with ships from `GameState.get_owned_ships()`
- [ ] Wire up tap → navigate to ship detail

### Step 3: Ship Detail Screen (60 mins)
- [ ] Create `scenes/hangar/ship_detail.tscn`
- [ ] Add back button navigation
- [ ] Create stat display sections (7 categories):
  - Defensive Stats (Hull, Shields, Armor, Size)
  - Offensive Stats (Damage, Projectiles, Attack Speed, Range)
  - Mobility (Movement Speed)
  - Accuracy (Accuracy, Evasion)
  - Critical (Precision, Reinforced Armor)
  - Ability (Energy, Amplitude, Frequency)
  - Resistance (Resilience)
- [ ] Create `stat_row.tscn` component (label + value, NO upgrade button)
- [ ] Display abilities from ship data
- [ ] Show applied upgrades as badge list
- [ ] Wire up stat display to `GameState.get_ship_stats()` (returns calculated stats)

### Step 4: Polish & Testing (30 mins)
- [ ] Add transitions between screens
- [ ] Add hover/press states for buttons and cards
- [ ] Test all 3 ships display correctly
- [ ] Test stat calculation with sample upgrades
- [ ] Test navigation: roster → detail → back
- [ ] Verify upgrade badges show correctly
- [ ] Test resource bar displays correct values
- [ ] Fix bugs and edge cases

---

## File Structure

```
res://
├── autoload/
│   ├── EventBus.gd              # Global signal hub (~50 lines)
│   ├── DataManager.gd           # CSV loading & caching (~150 lines)
│   ├── ResourceManager.gd       # Metal/Crystals/Fuel tracking (~80 lines)
│   └── GameState.gd             # Ship roster & upgrades & stat calc (~200 lines)
│
├── scenes/
│   └── hangar/
│       ├── ship_roster.tscn     # Main hangar screen (ship grid)
│       ├── ship_roster.gd       # Roster logic (~100 lines)
│       ├── ship_detail.tscn     # Per-ship detail screen
│       ├── ship_detail.gd       # Detail logic (~120 lines)
│       │
│       └── components/
│           ├── ship_card.tscn   # Ship card for roster grid
│           ├── ship_card.gd     # Card logic (~50 lines)
│           ├── stat_row.tscn    # Single stat display row (read-only)
│           ├── stat_row.gd      # Stat row logic (~30 lines)
│           ├── upgrade_badge.tscn # Applied upgrade display badge
│           └── upgrade_badge.gd # Upgrade badge logic (~40 lines)
│
├── data/
│   ├── ship_stat_database.csv   # 3 ships (POPULATED)
│   ├── ship_upgrade_database.csv # 40+ upgrades (POPULATED) - for stat calc
│   ├── ability_database.csv     # 34+ abilities (POPULATED)
│   ├── status_effects.csv       # Status effects (POPULATED)
│   └── elemental_combos.csv     # Combos (POPULATED)
│
└── project.godot                # Autoload configuration
```

**Total Estimated Lines**: ~620 lines across all files (well under 300/file limit)

---

## Component Specifications

### ShipCard Component (`ship_card.tscn`)

**Node Structure**:
```
PanelContainer (ShipCard)
├── VBoxContainer
│   ├── TextureRect (Ship Icon)
│   ├── Label (Ship Name)
│   ├── ProgressBar (Health: Hull + Shields)
│   └── HBoxContainer (Upgrade Indicators)
│       ├── TextureRect (Upgrade Dot 1)
│       ├── TextureRect (Upgrade Dot 2)
│       └── TextureRect (Upgrade Dot 3)
```

**Script Properties**:
```gdscript
extends PanelContainer

var ship_id: String
var ship_data: Dictionary

signal ship_tapped(ship_id: String)

func setup(id: String):
    ship_id = id
    ship_data = GameState.get_ship_stats(id)
    _update_display()
```

**Interactions**:
- Tap → Emit `ship_tapped` signal

### StatRow Component (`stat_row.tscn`)

**Node Structure**:
```
HBoxContainer (StatRow)
├── Label (Stat Name)
└── Label (Stat Value)
```

**Script Properties**:
```gdscript
extends HBoxContainer

var stat_name: String
var stat_value: float

func setup(stat: String, value: float):
    stat_name = stat
    stat_value = value
    _update_display()

func _update_display():
    $StatName.text = stat_name
    $StatValue.text = _format_stat_value(stat_value)
```

**Note**: Read-only display, no upgrade button. Stats shown already include base + upgrade bonuses.

### UpgradeBadge Component (`upgrade_badge.tscn`)

**Node Structure**:
```
PanelContainer (UpgradeBadge)
├── HBoxContainer
│   ├── Label (Upgrade Name)
│   └── Label (Rarity Badge)
```

**Script Properties**:
```gdscript
extends PanelContainer

var upgrade_id: String
var upgrade_data: Dictionary

signal badge_tapped(upgrade_id: String)

func setup(upgrade: String):
    upgrade_id = upgrade
    upgrade_data = DataManager.get_upgrade(upgrade_id)
    _update_display()

func _update_display():
    $HBox/UpgradeName.text = upgrade_data.upgrade_name
    $HBox/RarityBadge.text = upgrade_data.rarity
    _apply_rarity_color()  # Common=gray, Rare=blue, Epic=purple, etc.
```

**Interactions**:
- Tap → Emit `badge_tapped` signal (future: show upgrade details tooltip)

---

## Edge Cases & Considerations

### Stat Calculation Formula (GameState Implementation)

The Hangar displays **calculated stats** (base + upgrade bonuses), not raw base values.

**Upgrade Stacking Rules**:
- **Same Upgrade Multiple Times**: Each instance stacks additively
- **Percentage Bonuses**: Calculated from base stat, NOT compounding
- **Flat Bonuses**: Simple addition to base stat

**Formula** (implemented in `GameState.gd`):
```gdscript
func calculate_final_stat(base_value: float, upgrades: Array) -> float:
    var flat_bonus = 0.0
    var percent_bonus = 0.0

    for upgrade in upgrades:
        if upgrade.bonus_type == "flat":
            flat_bonus += upgrade.bonus_value
        elif upgrade.bonus_type == "percentage":
            percent_bonus += upgrade.bonus_value

    return base_value * (1.0 + percent_bonus) + flat_bonus
```

**Example**:
```
Base Hull: 100
Upgrade 1: +10% Hull (0.1 percentage)
Upgrade 2: +15% Hull (0.15 percentage)
Final: 100 * (1.0 + 0.1 + 0.15) = 100 * 1.25 = 125
```

### Display Formatting

**Ship Size Display**:
- **1×1 ships**: "Small" or "1×1"
- **2×2 ships**: "Medium" or "2×2"
- **3×3+ ships**: "Large" or "3×3"

**Stat Value Formatting**:
- Hull, Shields, Energy: Integer (e.g., "120")
- Armor, Accuracy, Evasion: Integer percentage or raw value (e.g., "5" or "50")
- Attack Speed, Movement Speed: One decimal (e.g., "1.2", "3.0")

**Abilities Without Ships**:
- Some ships may have 0 abilities (basic variants)
- Show "No Abilities" placeholder in abilities section

**No Applied Upgrades**:
- Ships without upgrades show empty "Applied Upgrades" section
- Show "No Upgrades" placeholder (future)

### Navigation State
- When returning from Ship Detail → Roster, scroll to previously selected ship
- Preserve scroll position on roster screen

### Data Synchronization
- Hangar is **read-only** for ship data
- When other modules apply upgrades via `GameState.apply_upgrade()`, Hangar should refresh automatically
- Listen to `EventBus.ship_upgraded` signal to trigger UI refresh (future)

---

## Testing Checklist

### Data Loading
- [ ] All 3 ships load from CSV correctly
- [ ] All 17 stats display correctly
- [ ] Upgrades load from CSV (for stat calculation)
- [ ] Abilities load and display correctly

### Ship Roster
- [ ] All owned ships appear in grid
- [ ] Tap ship → navigates to detail screen
- [ ] Resource bar shows correct values (read-only display)
- [ ] Ship cards show correct health bars (hull + shields)
- [ ] Upgrade indicators show correct count (dots/glow)

### Ship Detail
- [ ] All 17 stats display for each ship
- [ ] Stats grouped into 7 correct categories
- [ ] Stats display **calculated values** (base + upgrades), not raw base
- [ ] Abilities display with correct metadata
- [ ] Applied upgrade badges show up
- [ ] Back button returns to roster
- [ ] No upgrade buttons present (view-only)

### Stat Calculation
- [ ] Ships without upgrades show base stats
- [ ] Ships with upgrades show modified stats correctly
- [ ] Percentage upgrades calculate correctly from base
- [ ] Flat upgrades add correctly to base
- [ ] Multiple upgrades to same stat stack additively
- [ ] Test formula: `final = base * (1 + sum(percentages)) + sum(flats)`

### Polish
- [ ] No visual glitches
- [ ] Touch targets large enough (200×200px min)
- [ ] Text readable on mobile (32px+ font)
- [ ] Transitions smooth between screens
- [ ] Stat values formatted correctly (integers vs decimals)
- [ ] No console errors or warnings

---

## Future Enhancements (Post-Prototype)

### Visual Polish
- Ship sprite display (from `ship_visuals_database.csv` when populated)
- Animated stat updates when upgrades are applied from other modules
- Rarity color coding for upgrades (Common=gray, Rare=blue, Epic=purple, Legendary=gold)
- Ship 3D preview rotation
- Particle effects when viewing newly upgraded ships

### Gameplay Integration
- Mark ships "In Combat" (grayed out, view-only during combat)
- Ship damage display (hull/shields depleted after combat)
- Repair interface (if damaged, button to restore hull/shields for resource cost)
- Blueprint unlocking (unlock new ships via `blueprints_database.csv`)
- Real-time sync with sector exploration (receive upgrades via EventBus signals)

### Advanced Features
- Pilot assignment (from `personnel_database.csv` when populated)
- Equipment slots (weapons, shields, engines)
- Loadout presets (save ship configurations for quick deployment)
- Ship comparison view (side-by-side stat comparison between two ships)
- Upgrade details tooltip (tap badge → show full description and stat impact)
- Search/filter ships by type, size, or stats
- Favorites/tagging system

### Information Display
- Fleet power rating (sum of all ship stats)
- Achievement tracking display (X upgrades equipped, Y ships unlocked)
- Combat history per ship (battles won, enemies destroyed)
- Stat breakdown tooltip (base value vs upgrade contribution)

---

## Success Criteria

The Hangar prototype is considered **complete** when:

1. ✅ All 3 ships from CSV display in roster
2. ✅ Navigation between roster ↔ detail works smoothly
3. ✅ All 17 stats display correctly for each ship (calculated values, not base)
4. ✅ Stat calculation formula works correctly (base + upgrades)
5. ✅ Applied upgrade badges display correctly
6. ✅ Resources display in top bar (read-only, informational)
7. ✅ Abilities display with metadata from CSV
8. ✅ UI is usable on 1080×2340 portrait display
9. ✅ No file exceeds 300 lines
10. ✅ No console errors or warnings
11. ✅ All interactions are read-only (no upgrade purchasing)

---

## Notes & Constraints

- **View-Only Module**: Hangar does NOT purchase or apply upgrades - it only displays ship data
- **Upgrades Applied Elsewhere**: Other modules (sector exploration, traders, loot) call `GameState.apply_upgrade()`
- **Navigation Flow**: Swipe right → Deploy screen, Swipe left → Map screen
- **Deploy Screen**: Part of Combat Module, shows first 5 files of 15×25 grid
- **Enemy Preview**: Deploy screen shows enemy spawners/intents only when in active combat
- **No cards**: Previous iterations had card mechanics; Any-Type-7 does not
- **Portrait only**: All UI designed for vertical 1080×2340 layout
- **Touch-first**: Mouse is fallback for development; touch is primary
- **CSV-driven**: All data loaded from CSV, no hardcoding
- **300-line limit**: Break files into components if approaching limit
- **Singleton pattern**: Use autoloads for systems, EventBus for communication
- **Mobile performance**: Avoid heavy computations on main thread; cache aggressively
- **Stat Display**: Always show calculated stats (base + upgrades), never raw base values

---

## References

- **Master Plan**: `docs/any-type-7-plan.md` (game loop, 6-phase roadmap)
- **Ship Stats**: `docs/ship-stats-reference.md` (17 stats explained)
- **Combat Formulas**: `docs/combat-formulas.md` (stat calculations)
- **Abilities & Combos**: `docs/status-effects-and-combos.md` (elemental system)
- **Project Setup**: `CLAUDE.md` (architecture, conventions, constraints)

---

**Document Version**: 2.1
**Last Updated**: 2025-11-24
**Status**: Ready for Implementation
**Changes**:
- v2.1: Added Deploy screen navigation (swipe right) and enemy spawner preview
- v2.0: Removed upgrade purchasing system - Hangar is now view-only
- v1.0: Initial version with upgrade purchasing
