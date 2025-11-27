# Any-Type-7 Game Design & Implementation Plan

## 🎯 Project Status Overview

**Phase**: Content Complete → Ready for Code Implementation
**Progress**: 95% Content & Assets | 0% Game Code

### Recent Accomplishments ✅
- **11 CSV databases fully populated** with game content (14 ships, 50 abilities, 40+ upgrades, 30 combos, etc.)
- **Visual asset pipeline complete**: 11 ship sprites, 15+ exhaust effects, 100+ projectile sprites
- **Ship visual database populated**: All 24 ship configurations with hardpoint coordinates
- **Asset processing tools created**: Web-based ship visual processor + Python merge scripts
- **Comprehensive documentation**: 5 detailed design docs covering all systems

### What's Ready to Build
- All ship statistics, abilities, and upgrade data
- Complete elemental combo and status effect system
- Weapon, drone, and powerup definitions
- Ship visual assets with hardpoint data (weapon/exhaust mount points)
- Clear architectural guidelines and coding standards

### What Needs Implementation
- **Phase 1**: Core infrastructure (autoloads, CSV loading, EventBus)
- **Phase 2**: Sector exploration module (vertical scrolling map)
- **Phase 3**: Combat system (15×25 grid autobattler)
- **Phase 4**: Hangar management (ship customization)
- **Phases 5-6**: Integration, polish, mobile optimization

---

## Game Overview

**Any-Type-7** is a vertical-format space-based autobattler designed for mobile devices. Players control a mothership fleeing from an alien threat, navigating through procedurally generated sectors while gathering resources, upgrading their fleet, and engaging in tactical grid-based combat.

### Core Gameplay Loop

1. **Sector Exploration** - Navigate a solar system searching for the exit node
2. **Resource Gathering** - Deploy miners, research teams, and scavenge what you find
3. **Combat Encounters** - Face enemies in tactical grid-based autobattler combat
4. **Fleet Management** - Use the Hangar to equip ships and assign pilots
5. **Escape** - Find the exit node before the alien mothership catches you
6. **Progression** - Each sector becomes harder (mothership arrives sooner)

### Victory & Failure Conditions

- **Victory**: Find and reach the sector exit node before being caught
- **Failure**: The alien mothership catches and destroys your mothership
- **Escalation**: The mothership gains speed each sector, arriving progressively sooner

---

## The Three Main Modules

### 1. Sector Exploration Module

The primary gameplay mode where players navigate a vertical scrolling solar system.

#### Core Mechanics
- **Vertical scrolling map** that loops (wraps vertically)
- **Fog of war** obscuring hidden nodes and encounters
- **Movement system** with gravity assist mechanics
- **Time pressure** as the alien mothership approaches

#### Node Types

| Node Type | Description | Purpose |
|-----------|-------------|---------|
| **Mining Nodes** | Uninhabited planets/asteroids | Deploy miners to gather Metal, Crystals, Fuel, or wildcard resources |
| **Outposts** | Abandoned resource caches | Instant resource bonuses, sometimes enemy encounters |
| **Alien Colonies** | Enemy spawner structures | Difficult battles with great rewards; spawn patrolling enemies |
| **Trader Ships** | Merchant vessels | Purchase upgrades and blueprints for Metal/Crystals |
| **Asteroids** | Mineable space rocks | Quick Metal/Crystal gathering |
| **Ship Graveyards** | Derelict fleets | Salvage materials and ship parts |
| **Artifact Vaults** | Ancient installations | Powerful unique upgrades |
| **Exit Node** | Portal to next sector | Hidden; must be found to progress |

#### Enemy System
- **Alien Colonies** spawn patrolling enemies that hunt the player
- **Patrolling Enemies** respawn when killed
- **Colony Assault** - Players can attack colonies directly (high risk/reward)
- **Alien Mothership** - Appears after a time limit, extremely powerful boss
  - Can be fought at any time after appearance (requires significant power)
  - Gains speed each sector, arriving progressively sooner

#### Fuel Mechanics
- **Jump** - Teleport to any map location for 10 fuel
- **Gravity Assist** - Spend 1 fuel near gravitationally significant bodies to permanently increase speed until next jump

---

### 2. Combat Module

A tactical grid-based autobattler where players deploy ships to fight off enemy waves.

#### Grid Layout
- **15 lanes** (vertical height)
- **~25 files** (horizontal depth per lane)
- **Player start position**: Center lane (Lane 7)
- **Enemy spawners**: Far end of lanes (invisible)

#### Ship Deployment
- **Lane-based placement** - Ships occupy one or more lanes
- **Large ships** can span multiple lanes and use their own internal grid
- **Deployment zone** - Player side of the grid where ships start

#### Combat Phases

**1. Tactical Phase (Pre-wave)**
- Players deploy and position ships in their lanes
- Enemy spawn lanes highlighted in red
- May show enemy class indicators
- Player commits to layout and proceeds

**2. Wave Spawn (30 seconds)**
-
**3. Combat Phase (60 seconds)**
- Enemy spawners produce units at regular intervals for the first 30 seconds of the wave
- Enemies travel down lanes toward player
- Wave composition loaded from CSV scenarios
- Player ships advance and engage enemies
- Ships attack automatically when in range, but only travel in their assigned lane.
- No player interaction during combat except a call to retreat
- Ships return to deployment zone after wave is cleared

**4. Tactical Phase (Between waves)**
- Shields recharge
- Players can swap ships and loadouts
- If previous wave not cleared, next wave spawns anyway (stacking pressure)

#### Wave System
- **CSV-driven scenarios** define enemy composition and timing
- **Progressive difficulty** - Waves exhaust until combat ends
- **Reward upon completion** - Resources and loot granted

#### Retreat Mechanic
- **Long-press RETREAT button** to begin spooling up
- **Fuel consumption** begins immediately (cost is real)
- **30-second countdown** - All ships must return to deployment zone
- **Can be cancelled** but fuel cost is not refunded
- **Ships left behind** are lost if they don't return in time
- **Emergency escape** to safe sector on map

---

### 3. Hangar Module

The ship and pilot management screen accessed before combat encounters.

#### Situation Room
When encountering an enemy, players enter the situation room:
- **Enemy intelligence** - Information about the threat
- **Combat preview** - Expected difficulty and composition
- **Options**: Fight, Flee, or other context-specific actions

#### Hangar Functions
- **Ship selection** - Choose which ships to deploy
- **Equipment management** - Assign weapons and upgrades to ships
- **Pilot assignment** - Assign pilots to ships for bonuses
- **Loadout customization** - Configure ship abilities and equipment
- **Fleet deployment** - Finalize roster before entering combat

---

## Resource System

### Three Core Resources

| Resource | Primary Use | Sources |
|----------|-------------|---------|
| **Metal** | Basic construction and repairs | Mining nodes, asteroids, salvage |
| **Crystals** | Advanced technology and upgrades | Mining nodes, asteroids, traders |
| **Fuel** | Movement, jumping, gravity assists | Mining nodes, outposts |

### Resource Gathering Methods
- **Miners** - Deploy to mining nodes for sustained gathering
- **Research Teams** - Assign to nodes for research bonuses
- **Scavenging** - Instant pickups from outposts and salvage
- **Combat Rewards** - Earned from defeating enemies

---

## Ship Statistics System

Ships have 16 core statistics that determine their combat performance.

**Documentation:**
- [Ship Stats Reference](ship-stats-reference.md) - Complete stat descriptions and mechanics
- [Combat Formulas](combat-formulas.md) - Hit/crit/damage calculations and DPS formulas
- [Status Effects & Combos](status-effects-and-combos.md) - All status effects and elemental combo system

### Stat Categories

#### Defensive Stats
- **Hull Points** - Primary health pool
- **Shield Points** - Regenerating health (restores between waves)
- **Size (Width × Height)** - Grid space occupied (e.g., 1×1, 2×2, 3×5)

#### Offensive Stats
- **Damage** - Damage per projectile
- **Projectiles** - Number of projectiles per attack
- **Attack Speed** - Attacks per second
- **Attack Range** - Range in grid squares

#### Mobility
- **Movement Speed** - Squares per second travel speed

#### Accuracy System (d100 percentage-based)
- **Accuracy** - Increases hit chance (+1% per point)
- **Evasion** - Decreases enemy hit chance (-1% per point)
- **Hit Chance Formula**: `100% - (Evasion - Accuracy)` (min 5%, max 95%)

#### Critical Hit System
- **Precision** - Increases crit chance (+1% per point, 0% base)
- **Reinforced Armor** - Reduces enemy crit chance (-1% per point)
- **Crit Chance Formula**: `Precision - Reinforced_Armor` (min 0%)

#### Ability Stats (for ships with abilities)
- **Energy Points** - Maximum energy for abilities
- **Amplitude** - +% to ability numerical effects
- **Frequency** - +% to ability durations

#### Resistance
- **Resilience** - % chance to ignore status effects

### Combat Formulas Summary

```
Hit Chance = 100% - (Defender_Evasion - Attacker_Accuracy)
Crit Chance = Attacker_Precision - Defender_Reinforced_Armor
Damage per Attack = Damage × Projectiles (each rolls separately)
Attack Cooldown = 1.0 / Attack_Speed
```

### Ship Archetypes

- **Interceptor** (1×1): High evasion, high speed, low health
- **Fighter** (1×1): Balanced stats, medium range
- **Frigate** (2×2): High shields, reinforced armor, slower
- **Cruiser** (3×3+): High hull, powerful attacks, low mobility
- **Support** (varies): Ability-focused, uses Amplitude/Frequency

### CSV Reference

Ship stats are defined in `data/ship_stat_database.csv` with columns:
- Basic: ship_ID, ship_name, ship_size_class, ship_sub_class
- Defense: hull_points, shield_points, size_width, size_height
- Offense: attack_damage, attack_speed, projectile_count, attack_range
- Mobility: movement_speed
- Combat: accuracy, evasion, precision, reinforced_armor
- Abilities: energy_points, amplitude, frequency, resilience
- Equipment: ship_ability, upgrade_slots, weapon_slots

---

## Technical Requirements

### Platform & Engine
- **Engine**: Godot 4.5
- **Language**: GDScript
- **Target Platform**: Android mobile devices
- **Rendering**: GL Compatibility (mobile-optimized)

### Screen Format
- **Resolution**: 1080x2340 (19.5:9 aspect ratio)
- **Orientation**: Portrait/Vertical (phone-optimized)
- **UI Design**: Touch-first with mouse input fallback

### Input Methods
- **Primary**: Touch screen (tap, drag, long-press)
- **Secondary**: Mouse (for desktop testing and development)

---

## Architecture Guidelines

Following lessons learned from **any-type-5-considerations.md**, this project will use clean, modular architecture to avoid the code bloat and spaghetti coupling of previous iterations.

### Core Architectural Principles

1. **Singleton Autoload Pattern**
   - Break systems into focused, single-responsibility singletons
   - Each manager handles one domain (Combat, Resources, Data, etc.)
   - Prevents monolithic "god scripts"

2. **EventBus Signal Pattern**
   - Centralized signal hub for cross-system communication
   - Decouples systems (no direct dependencies)
   - Example: `EventBus.combat_wave_completed.emit(wave_number)`

3. **CSV-Driven Data Design**
   - Game content lives in CSV databases, not code
   - Ships, weapons, abilities, scenarios all data-driven
   - Easy to balance and extend without touching code

4. **Component-Based Scene Composition**
   - Small, reusable scene components (<300 lines per script)
   - Compose complex systems from simple parts
   - Example: Ship = ShipSprite + HealthBar + WeaponSlots

5. **Mobile-First UI Design**
   - Portrait layout from day one (1080x2340)
   - Touch targets sized appropriately (minimum 44x44 px)
   - Vertical scrolling and single-handed operation where possible

### Key Autoloads/Singletons

#### Core Infrastructure
- **EventBus** - Global signal hub for decoupled communication
- **GameState** - Persistent game state and progression
- **DataManager** - CSV loading, caching, and queries
- **SaveManager** - Save/load system
- **SettingsManager** - Player preferences
- **AudioManager** - Music and sound effects

#### Gameplay Systems
- **SectorManager** - Sector exploration, node management, map state
- **CombatManager** - Combat orchestration, grid, phases, units
- **HangarManager** - Ship/pilot/equipment management
- **ResourceManager** - Metal, Crystals, Fuel tracking and spending
- **EffectResolver** - Data-driven ability and effect execution
- **DamageCalculator** - Hit chance, damage, crits, resistances

#### Event & Encounter Systems
- **EncounterManager** - Situation room and encounter flow
- **TraderManager** - Shop encounters and trading
- **MiningManager** - Mining node operations
- **TreasureManager** - Loot and salvage

---

## Data Structure (CSV Databases)

### CSV Database Status

| CSV File | Status | Count | Notes |
|----------|--------|-------|-------|
| `ship_stat_database.csv` | ✅ Complete | 14 ships | All 17 stats populated |
| `ability_database.csv` | ✅ Complete | 50 abilities | Triggers, combos, and effects defined |
| `ship_upgrade_database.csv` | ✅ Complete | 40+ upgrades | 5 rarity tiers (common to legendary) |
| `status_effects.csv` | ✅ Complete | 10 effects | Elemental (5) + Control (5) |
| `elemental_combos.csv` | ✅ Complete | 30 combos | Same-element (5) + Cross-element (25) |
| `weapon_database.csv` | ✅ Complete | 7 weapons | All weapon types and behaviors |
| `blueprints_database.csv` | ✅ Complete | 21 blueprints | Ship and weapon unlock progression |
| `drone_database.csv` | ✅ Complete | 13 drones | Combat and support drone stats |
| `powerups_database.csv` | ✅ Complete | 10 powerups | Drop rates and effects defined |
| `ship_visuals_database.csv` | ✅ Complete | 24 entries | Sprites, hardpoints, exhausts, colors |
| `drone_visuals_database.csv` | ✅ Complete | 11 entries | Drone visual definitions |
| `combat_scenarios.csv` | ⚠️ Empty | 0 | Placeholder - waves to be designed |
| `personnel_database.csv` | ⚠️ Empty | 0 | Placeholder - pilots/crew to be designed |

### Additional CSVs To Create (Future)

- `sector_node_types.csv` - Node type definitions and properties
- `enemy_database.csv` - Enemy unit stats and behaviors
- `resource_costs.csv` - Construction and upgrade costs
- `trader_inventory.csv` - Shop inventory pools
- `progression_curve.csv` - Difficulty scaling per sector

---

## Implementation Progress Tracker

### Content & Assets: ✅ 95% Complete
- ✅ CSV databases populated (11 of 13 files complete)
- ✅ Ship visual assets imported (11 ships, 15+ exhausts, 100+ projectiles)
- ✅ Asset processing tools created (ship_visual_processor.html + Python scripts)
- ✅ Ship coordinate data exported (10+ JSON hardpoint files)
- ⚠️ Combat scenarios CSV (needs wave design)
- ⚠️ Personnel database CSV (needs pilot/crew design)

### Game Code: ❌ 0% Complete
- ❌ No autoload singletons implemented
- ❌ No scenes created
- ❌ No GDScript systems written
- ❌ No UI components built

**Current Phase**: Transition from content creation to code implementation

---

## High-Level Implementation Phases

### Phase 1: Core Infrastructure ⏳ **NEXT UP**
**Goal**: Establish the foundation and architectural patterns

- Set up singleton autoloads (EventBus, GameState, DataManager, etc.)
- Implement CSV loading and data caching system
- Create basic UI framework for portrait layout
- Set up input handling (touch + mouse)
- Implement save/load system skeleton

**Deliverable**: A runnable foundation with data loading and basic UI

---

### Phase 2: Sector Exploration Prototype ⏳ Pending
**Goal**: Build the primary gameplay loop

- Vertical scrolling map system with looping
- Node placement and generation
- Player movement and navigation
- Fog of war system
- Basic node interactions (outposts, mining nodes)
- Resource gathering mechanics
- Fuel-based jumping and gravity assist
- Alien mothership timer and chase mechanic

**Deliverable**: Playable sector exploration with basic node types

---

### Phase 3: Combat System Prototype ⏳ Pending
**Goal**: Implement the tactical autobattler

- 15x25 grid system with lane-based deployment
- Ship placement and positioning
- Tactical phase UI and controls
- Combat phase automation (movement, attacking, AI)
- Enemy spawning from CSV wave data
- Wave timing and progression
- Retreat mechanic with fuel cost
- Combat rewards and completion flow

**Deliverable**: Functional grid-based combat with CSV-driven waves

---

### Phase 4: Hangar & Fleet Management ⏳ Pending
**Goal**: Create ship customization and preparation systems

- Situation room UI and encounter flow
- Ship roster management
- Equipment and upgrade system
- Pilot assignment and bonuses
- Loadout saving and presets
- Integration with combat deployment

**Deliverable**: Full pre-combat preparation flow

---

### Phase 5: Integration & Content ⏳ Pending
**Goal**: Connect all modules and populate game content

- Seamless module transitions (Sector → Encounter → Hangar → Combat → Sector)
- Complete all CSV databases with game content
- Enemy variety and alien colony encounters
- Trader ships and shop system
- Graveyards, artifact vaults, special nodes
- Boss encounter with alien mothership
- Progression and difficulty scaling
- Tutorial and onboarding flow

**Deliverable**: Fully integrated game loop with rich content

---

### Phase 6: Polish & Mobile Optimization ⏳ Pending
**Goal**: Prepare for Android deployment

- Touch gesture refinement and UX polish
- Performance optimization for mobile
- Visual effects and animations
- Sound design and music integration
- UI/UX improvements and accessibility
- Balance tuning and playtesting
- Android build configuration and testing

**Deliverable**: Release-ready Android build

---

## Key Design Changes from Previous Iterations

### What's Different in Any-Type-7

1. **No Card System**
   - Previous iterations (any-type-4/5) included card-based mechanics
   - Removed in any-type-7 as it didn't fit the core gameplay
   - Focus shifted to direct ship/pilot/equipment management

2. **Vertical Portrait Format**
   - Optimized for phone screens from the start (1080x2340)
   - UI designed for single-handed touch operation
   - Combat grid adjusted to fit vertical orientation (15 lanes tall)

3. **Simplified Core Loop**
   - Three clear modules: Sector Exploration → Combat → Hangar
   - Direct connection between exploration encounters and combat
   - Removed intermediate card-drafting phases

4. **Mobile-First Development**
   - Touch controls as primary input method
   - Android as target platform from day one
   - Performance and battery optimization prioritized

---

## Immediate Next Steps

### Phase 1 Implementation (Core Infrastructure)

1. **Create Autoload Singletons** - Set up the foundational managers:
   - `EventBus.gd` - Define all global signals
   - `DataManager.gd` - CSV parsing and caching system
   - `GameState.gd` - Game state tracking
   - `ResourceManager.gd` - Metal/Crystals/Fuel management

2. **Implement CSV Loading** - DataManager should load:
   - ✅ ship_stat_database.csv (14 ships ready)
   - ✅ ability_database.csv (50 abilities ready)
   - ✅ ship_visuals_database.csv (24 visuals ready)
   - ✅ All other populated CSVs

3. **Create Basic Scene Structure**:
   - `main.tscn` - Root scene with UI framework
   - `debug_data_viewer.tscn` - Tool to verify CSV loading
   - Portrait layout (1080x2340) container setup

4. **Test Asset Loading**:
   - Verify ship sprites load correctly
   - Test exhaust animations
   - Confirm projectile assets accessible

5. **After Phase 1 Complete** → Move to Phase 2 (Sector Exploration)

---

## Notes & Considerations

### From any-type-5 Lessons Learned

- **Avoid monolithic scripts** - Previous combat script reached 6,115 lines
- **Keep files under 300 lines** - Enforce strict modularity
- **Use EventBus for all cross-system communication** - No direct script dependencies
- **Data-driven over code-driven** - Put game logic in CSVs, not GDScript
- **Test on mobile early and often** - Don't wait until late to test performance

### Open Questions for Design

- [ ] How should large ships (multi-lane) handle movement and collision?
- [ ] Should fog of war be per-sector or persistent across sectors?
- [ ] What happens to deployed miners when jumping to a new location?
- [ ] How does the mothership chase mechanic work visually?
- [ ] Should there be permadeath or meta-progression between runs?

---

## Conclusion

**Any-Type-7** is a focused, mobile-first space autobattler with clear architectural guidelines learned from previous iterations. By following the singleton autoload pattern, EventBus communication, and CSV-driven design, the project will avoid the code bloat and coupling issues that plagued earlier versions.

The game loop is straightforward: explore sectors, gather resources, fight tactical battles, upgrade your fleet, and escape before the alien mothership catches you. Each sector ramps up the pressure, creating natural progression and difficulty escalation.

This plan provides a roadmap for incremental development, starting with core infrastructure and building up to a fully integrated mobile game ready for Android deployment.
