# Sector Exploration Module - Beta Implementation

**Status:** ✅ Fully Implemented
**Version:** Beta 1.0
**Last Updated:** December 2024

---

## Overview

The Sector Exploration module is a **momentum-based infinite scrolling system** where players navigate a colony ship through procedurally generated space sectors. The module features automatic forward movement, lateral steering, special maneuvers (jump, boost, brake), resource collection, and hostile alien encounters.

---

## Architecture

### **Coordinator Pattern**
The module uses a **clean coordinator architecture** with focused, single-responsibility systems:

```
sector_map.gd (272 lines - COORDINATOR)
├─→ scrolling_system.gd (infinite scrolling, speed control)
├─→ node_spawner.gd (procedural generation)
├─→ player_movement.gd (lateral steering with momentum)
├─→ boost_system.gd (temporary speed increase)
├─→ brake_system.gd (emergency stop)
├─→ gravity_system.gd (gravity assists from planets)
├─→ jump_system.gd (lateral teleport)
├─→ camera_system.gd (zoom + shake effects)
├─→ tractor_beam_system.gd (debris collection)
├─→ enemy_sweep_manager.gd (alien attack patterns)
└─→ debug_ui_system.gd (dev tools - disabled in production)
```

### **Singleton Managers (Autoloads)**
```
UIManager (191 lines) - UI/HUD coordination
AnimationManager (256 lines) - Visual feedback (tweens, particles, flying icons)
CollectionManager (213 lines) - Resource collection with multipliers
ResourceManager - Metal, Crystals, Fuel tracking
GameState - Progression, streaks, statistics
SectorManager - Sector data and progression
DebugManager - Runtime tuning parameters
EventBus - Decoupled signal communication
```

---

## Core Systems

### **1. Scrolling System** (`scrolling_system.gd`)

**Purpose:** Infinite vertical scrolling with speed control

**Key Features:**
- Automatic forward movement (always scrolling down)
- Three-tile grid system (seamless looping)
- Speed multiplier system (1.0x - 10.0x)
- Distance tracking

**Tunable Parameters:**

| Parameter | Location | Default | Description |
|-----------|----------|---------|-------------|
| `base_scroll_speed` | scrolling_system.gd:12 | 150.0 | Base pixels/second |
| `speed_multiplier` | scrolling_system.gd:13 | 3.0 | Current speed factor |
| `min_speed` | scrolling_system.gd:14 | 1.0 | Minimum speed multiplier |
| `max_speed` | scrolling_system.gd:15 | 10.0 | Maximum speed multiplier |
| `TILE_HEIGHT` | scrolling_system.gd:18 | 2340.0 | Vertical tile size (screen height) |

---

### **2. Node Spawner** (`node_spawner.gd`)

**Purpose:** Procedural generation of celestial bodies, debris, and structures

**Key Features:**
- 29+ node types (planets, asteroids, stations, debris, traders, etc.)
- CSV-driven spawn weights and properties
- Orbital mechanics (moons, satellites orbit planets)
- Distance-based spawning (ahead of player)
- Rarity system (poor, standard, rich, abundant, jackpot) NOTE:  this wil change to asteroids granting just 1 resource

**Tunable Parameters:**

| Parameter | Location | Default | Description |
|-----------|----------|---------|-------------|
| `planetary_spawn_interval` | node_spawner.gd:~20 | 600.0 | Distance between planetary bodies (px) |
| `debris_spawn_interval` | node_spawner.gd:~21 | 400.0 | Distance between debris fields (px) |
| `debris_cluster_min` | node_spawner.gd:~22 | 3 | Min debris per cluster |
| `debris_cluster_max` | node_spawner.gd:~23 | 7 | Max debris per cluster |
| `node_spawn_interval` | node_spawner.gd:~24 | 800.0 | Distance between special nodes (px) |
| `proximity_distance` | node_spawner.gd:~25 | 150.0 | Activation distance (px) |
| `orbit_radius` | node_spawner.gd:~300 | 100.0 | Orbital distance for moons (px) |

**CSV Data Source:** `data/sector_nodes.csv`

---

### **3. Player Movement** (`player_movement.gd`)

**Purpose:** Lateral steering with momentum physics

**Key Features:**
- Swipe-based lateral control (A/D keys or touch)
- Momentum system with direction change resistance
- Decoupled visual rotation (ship points where you're pressing)
- Heavy "spaceship feel"

**Tunable Parameters:**

| Parameter | Location | Default | Description |
|-----------|----------|---------|-------------|
| `BASE_ACCELERATION` | player_movement.gd:14 | 800.0 | Lateral acceleration (px/s²) |
| `MAX_LATERAL_SPEED` | player_movement.gd:15 | 600.0 | Max lateral velocity (px/s) |
| `VELOCITY_DAMPING` | player_movement.gd:16 | 0.96 | Friction multiplier per frame |
| `DIRECTION_CHANGE_DECEL` | player_movement.gd:19 | 0.78 | Velocity bleed when reversing (22% loss) |
| `DIRECTION_CHANGE_ACCEL_MULT` | player_movement.gd:20 | 0.05 | Acceleration when fighting momentum (5%) |
| `VISUAL_ROTATION_SPEED` | player_movement.gd:23 | 45.0 | Visual tilt speed (degrees/sec) |
| `VISUAL_ROTATION_EXAGGERATION` | player_movement.gd:24 | 1.25 | Visual rotation overshoot (25% extra) |
| `MAX_TILT_ANGLE` | player_movement.gd:25 | 30.0 | Max visual tilt (degrees) |

---

### **4. Jump System** (`jump_system.gd`)

**Purpose:** Lateral teleport mechanic with charge, fuel cost, and cooldown

**Key Features:**
- Hold SPACE for 1 second to charge
- Choose direction (A/D) after charge completes
- Arrows pulse when ready
- 360° spin animation during jump
- Split fuel cost (3 on press, 5 on execution)

**Tunable Parameters:**

| Parameter | Location | Default | Description |
|-----------|----------|---------|-------------|
| `JUMP_INITIAL_FUEL_COST` | jump_system.gd:20 | 3 | Fuel spent when SPACE pressed |
| `JUMP_EXECUTION_FUEL_COST` | jump_system.gd:21 | 5 | Fuel spent when jump executes |
| `JUMP_CHARGE_DURATION` | jump_system.gd:22 | 1.0 | Hold time required (seconds) |
| `JUMP_DISTANCE` | jump_system.gd:23 | 300.0 | Fixed jump distance (px) |
| `JUMP_ANIMATION_DURATION` | jump_system.gd:24 | 0.5 | Spin animation time (seconds) |
| `JUMP_COOLDOWN_DURATION` | jump_system.gd:25 | 10.0 | Cooldown after jump (seconds) |
| `SCREEN_CENTER` | jump_system.gd:26 | 540.0 | Screen center X (1080/2) |
| `PLAYER_Y_POSITION` | jump_system.gd:27 | 1950.0 | Player ship Y position |

---

### **5. Boost System** (`boost_system.gd`)

**Purpose:** Temporary speed increase (W key)

**Key Features:**
- Hold W to boost (+2.0x speed)
- Consumes 1 fuel/second
- Smooth acceleration/deceleration
- Auto-cancels when out of fuel
- Incompatible with brake (mutual exclusion)

**Tunable Parameters:**

| Parameter | Location | Default | Description |
|-----------|----------|---------|-------------|
| `BOOST_SPEED_INCREASE` | boost_system.gd:~15 | 2.0 | Speed multiplier bonus |
| `BOOST_FUEL_COST_PER_SECOND` | boost_system.gd:~16 | 1.0 | Fuel consumption rate |
| `BOOST_ACCELERATION` | boost_system.gd:~17 | 4.0 | Speed ramp-up rate |
| `BOOST_DECELERATION` | boost_system.gd:~18 | 3.0 | Speed ramp-down rate |

---

### **6. Brake System** (`brake_system.gd`)

**Purpose:** Emergency stop mechanic (S key)

**Key Features:**
- Hold S to decelerate rapidly
- Speed drops to 0.1x
- Camera zoom out effect
- No fuel cost
- Incompatible with boost

**Tunable Parameters:**

| Parameter | Location | Default | Description |
|-----------|----------|---------|-------------|
| `BRAKE_TARGET_SPEED` | brake_system.gd:~15 | 0.1 | Target speed multiplier |
| `BRAKE_DECELERATION` | brake_system.gd:~16 | 5.0 | Speed reduction rate |
| `BRAKE_ACCELERATION` | brake_system.gd:~17 | 3.0 | Speed recovery rate |
| `BRAKE_ZOOM_AMOUNT` | brake_system.gd:~18 | 0.8 | Camera zoom out factor |
| `BRAKE_ZOOM_DURATION` | brake_system.gd:~19 | 0.5 | Zoom animation time |

---

### **7. Gravity System** (`gravity_system.gd`)

**Purpose:** Speed modification near planetary bodies

**Key Features:**
- Automatic proximity detection
- CSV-driven gravity multipliers per node
- Can increase OR decrease speed
- Visual indicator when active

**Tunable Parameters:**

| Parameter | Location | Default | Description |
|-----------|----------|---------|-------------|
| `gravity_multiplier` | sector_nodes.csv (per node) | 0.5 - 3.0 | Speed change factor |
| `GRAVITY_DETECTION_RANGE` | gravity_system.gd:~15 | 200.0 | Activation distance (px) |
| `GRAVITY_RAMP_SPEED` | gravity_system.gd:~16 | 2.0 | Smooth transition rate |

**CSV Data Source:** `data/sector_nodes.csv` (column: `gravity_multiplier`)

---

### **8. Tractor Beam System** (`tractor_beam_system.gd`)

**Purpose:** Debris collection with visual beams

**Key Features:**
- Passive attraction (debris drifts toward player)only with upgrades
- Active beam lock (cyan beam connects, pulls debris)
- Multiple simultaneous beams
- Visual Line2D rendering

**Tunable Parameters:**

| Parameter | Location | Default | Description |
|-----------|----------|---------|-------------|
| `debris_attraction_range` | DebugManager.gd:15 | 0.0 | Passive attraction range (disabled) |
| `debris_attraction_speed` | DebugManager.gd:16 | 150.0 | Passive drift speed (px/s) |
| `tractor_beam_range` | DebugManager.gd:17 | 200.0 | Active beam lock range (px) |
| `tractor_beam_duration` | DebugManager.gd:18 | 2.0 | Pull time to collect (seconds) |
| `tractor_beam_projectile_count` | DebugManager.gd:19 | 3 | Max simultaneous beams |

**Note:** These are in DebugManager for runtime tuning via debug UI

---

### **9. Enemy Sweep System** (`enemy_sweep_manager.gd`)

**Purpose:** Alien attack patterns that sweep across the screen

**Key Features:**
- 13 distinct sweep patterns (CSV-driven)
- Triple-sweep system (3 patterns per attack, 1-second stagger)
- Vertical, diagonal, pincer, wave formations
- 4-second warning flash before spawn
- Screen shake on collision

**Tunable Parameters:**

| Parameter | Location | Default | Description |
|-----------|----------|---------|-------------|
| `WARNING_DURATION` | enemy_sweep_manager.gd:16 | 4.0 | Warning time (seconds) |
| `SPAWN_STAGGER_TIME` | enemy_sweep_manager.gd:20 | 1.0 | Delay between sweeps (seconds) |
| `time_between_attacks` | enemy_sweep_manager.gd:24 | 15.0 | Cooldown between attacks (seconds) |
| `base_speed` | alien_sweep_patterns.csv (per pattern) | 300.0 | Sweep speed (px/s) |
| `width_px` | alien_sweep_patterns.csv (per pattern) | 150-400 | Sweep width |
| `gap_px` | alien_sweep_patterns.csv (per pattern) | 0-280 | Gap in pincer/wave patterns |
| `spawn_weight` | alien_sweep_patterns.csv (per pattern) | 12-100 | Selection probability |

**CSV Data Source:** `data/alien_sweep_patterns.csv`

**Pattern Types:**
- `vertical` - Straight down (left, right, center, aim center)
- `diagonal` - Angled sweep (top-left, top-right)
- `pincer` - Two sweeps from sides with center gap
- `wave` - Multiple small groups (3, 5, or 7 groups)

---

### **10. Camera System** (`camera_system.gd`)

**Purpose:** Camera zoom and shake effects

**Key Features:**
- Zoom in/out with smooth lerp
- Screen shake on impacts
- Cooldown system for zooms

**Tunable Parameters:**

| Parameter | Location | Default | Description |
|-----------|----------|---------|-------------|
| `base_zoom` | camera_system.gd:10 | Vector2(1.0, 1.0) | Default zoom level |
| `ZOOM_SPEED` | camera_system.gd:22 | 8.0 | Lerp speed for zoom |
| `ZOOM_COOLDOWN_TIME` | camera_system.gd:19 | 2.0 | Cooldown between zooms (seconds) |
| `shake_intensity` | (passed at runtime) | 5.0-20.0 | Shake magnitude (px) |
| `shake_duration` | (passed at runtime) | 0.1-0.5 | Shake time (seconds) |

---

## Resource Collection System

### **CollectionManager Integration**

The resource collection system uses a **multi-layered multiplier approach**:

**Formula:**
`Final_Resources = base_amount × quality_tier × streak_multiplier`

**Quality Tiers (Rarity System):**
- **Poor:** 0.5x (gray glow)
- **Standard:** 1.0x (white glow)
- **Rich:** 1.5x (blue glow)
- **Abundant:** 2.0x (purple glow)
- **Jackpot:** 3.0x (gold glow)

**Streak System (GameState):**
- Collecting same resource type consecutively builds streak
- +10% per streak level (max 5 = +50%)
- Resets when collecting different resource type

**CSV Data Source:** `data/resource_quality_tiers.csv`, `data/sector_nodes.csv`

---

## Visual Feedback Systems

### **AnimationManager Integration**

All visual feedback uses AnimationManager singleton:

**Flying Icons:**
- Resources fly from node to UI panel
- Scale animation (0.6x → 0.3x)
- Duration: 0.5 seconds
- On arrival: number count + panel pulse

**Number Counting:**
- Smooth value interpolation
- Duration: 0.3 seconds
- Updates resource label in real-time

**Panel Pulse:**
- Scale up to 1.15x, return to 1.0x
- Duration: 0.3 seconds total
- Triggered on collection completion

**Floating Text (Future):**
- Rising text with fade out
- Configurable color per resource type

---

## UI System

### **UIManager Integration**

The UI system is split into **static** (scene-based) and **dynamic** (code-generated) elements:

**Static UI (sector_map.tscn):**
- Distance label (top-left)
- Timer label (top-center)
- place_boi counter (top-right)
- Resource panels (fuel, metal, crystals)
- Speed indicator

**Dynamic UI (created at runtime):**
- Streak display (UIManager.create_label)
- Enemy trigger counter
- Debug controls (when enabled)

**Update Pattern:**
```gdscript
# Every frame
UIManager.update_sector_ui(scrolling_system)

# On collection
CollectionManager.collect_from_node(node, ui_overlay)
  └─→ AnimationManager.create_flying_icon()
  └─→ AnimationManager.animate_number_count()
  └─→ AnimationManager.pulse_scale()
```

---

## Event Flow

### **EventBus Signals**

```gdscript
# Node proximity
EventBus.node_proximity_entered.emit(node_id, node_type)
EventBus.node_proximity_exited.emit(node_id)

# Node activation
EventBus.node_activated.emit(node_id)

# Visual feedback
EventBus.screen_shake_requested.emit(duration, intensity)

# Resource changes
EventBus.resource_changed.emit(resource_type, old_amount, new_amount)
EventBus.resource_gained.emit(resource_type, amount, source)
EventBus.resource_spent.emit(resource_type, amount, reason)

# Streak system
EventBus.resource_streak_updated.emit(resource_type, streak_count, multiplier)
EventBus.resource_streak_broken.emit()
```

---

## Tuning the Game

### **Quick Access Parameter Locations**

**Speed & Feel:**
- Base scroll speed: `scrolling_system.gd:12`
- Player acceleration: `player_movement.gd:14`
- Direction change feel: `player_movement.gd:19-20`

**Jump Mechanic:**
- Fuel costs: `jump_system.gd:20-21`
- Jump distance: `jump_system.gd:23`
- Cooldown: `jump_system.gd:25`

**Boost/Brake:**
- Boost multiplier: `boost_system.gd:15`
- Boost fuel cost: `boost_system.gd:16`
- Brake target speed: `brake_system.gd:15`

**Spawning:**
- Planetary interval: `node_spawner.gd:~20`
- Debris interval: `node_spawner.gd:~21`
- Node spawn weights: `data/sector_nodes.csv`

**Enemy Attacks:**
- Attack frequency: `enemy_sweep_manager.gd:24`
- Warning time: `enemy_sweep_manager.gd:16`
- Pattern data: `data/alien_sweep_patterns.csv`

**Tractor Beam:**
- All parameters: `DebugManager.gd:15-19`

---

## Debug UI System

**Status:** Disabled by default (production mode)

**Enable Debug UI:**
Uncomment lines 136-138 in `sector_map.gd`:
```gdscript
debug_ui_system = load("res://scenes/sector_exploration/debug_ui_system.gd").new()
add_child(debug_ui_system)
debug_ui_system.initialize(ui_overlay, node_spawner)
```

**Debug Controls (9 total):**
1. **Planetary** - Adjust planetary body spawn interval
2. **Debris** - Adjust debris field spawn interval
3. **Cluster** - Adjust debris cluster size (min-max)
4. **Nodes** - Adjust special node spawn interval
5. **Attr Range** - Tractor beam attraction range
6. **Attr Speed** - Attraction drift speed
7. **Beam Range** - Beam lock range
8. **Beam Time** - Pull duration
9. **Max Beams** - Simultaneous beam count

---

## Performance Considerations

**Node Pooling:**
- Nodes despawn when 3000px behind player
- Prevents memory leaks
- Maintains stable frame rate

**Animation Optimization:**
- Flying icons auto-cleanup on complete
- Tweens use lightweight interpolation
- Particle limits enforced

**CSV Caching:**
- DataManager caches all CSV data on load
- No runtime file I/O
- Fast lookups via dictionary

---

## Future Enhancements

**Planned Features:**
1. ⏳ **Mothership Pursuit System** - Distance-based threat that spawns behind player
2. ⏳ **Resource Mining Restrictions** - Speed-based mining limitations
3. ⏳ **Position Multiplier System** - Edge vs center collection bonuses
4. ⏳ **Visual Quality Indicators** - Glowing auras on high-quality nodes
5. ⏳ **Floating Collection Text** - Show +amounts above collected nodes
6. ⏳ **Trail Animations** - Particle trails during boost/jump
7. ⏳ **Audio Integration** - AudioManager for pings, swooshes, impacts

**Completed Features:**
- ✅ Infinite scrolling system
- ✅ Procedural node generation
- ✅ Momentum-based movement
- ✅ Jump mechanic with charge system
- ✅ Boost/brake systems
- ✅ Gravity assists
- ✅ Tractor beam collection
- ✅ Enemy sweep patterns
- ✅ Resource collection with animations
- ✅ Streak multiplier system
- ✅ Orbiting nodes (moons, satellites)

---

## File Reference

### **Core Module Files:**
```
scenes/sector_exploration/
├── sector_map.gd (272 lines) - Main coordinator
├── sector_map.tscn - Scene with UI layout
├── scrolling_system.gd - Infinite scrolling
├── node_spawner.gd - Procedural generation
├── player_movement.gd - Lateral steering
├── boost_system.gd - Speed boost (W key)
├── brake_system.gd - Emergency brake (S key)
├── gravity_system.gd - Gravity assists
├── jump_system.gd - Lateral teleport (SPACE key)
├── camera_system.gd (205 lines) - Zoom + shake
├── tractor_beam_system.gd - Debris collection
├── enemy_sweep_manager.gd - Alien attacks
└── debug_ui_system.gd (228 lines) - Dev tools
```

### **Autoload Singletons:**
```
scripts/autoloads/
├── EventBus.gd - Signal hub
├── GameState.gd - Progression & streaks
├── ResourceManager.gd - Metal, Crystals, Fuel
├── DataManager.gd - CSV loading
├── SectorManager.gd - Sector data
├── UIManager.gd (191 lines) - HUD coordination
├── AnimationManager.gd (256 lines) - Visual feedback
├── CollectionManager.gd (213 lines) - Resource collection
├── IndicatorManager.gd - Jump indicators
└── DebugManager.gd - Runtime tuning
```

### **Data Files:**
```
data/
├── sector_nodes.csv - Node types & spawn weights
├── alien_sweep_patterns.csv - Enemy attack patterns
├── resource_quality_tiers.csv - Rarity definitions
└── sector_progression.csv - Difficulty scaling
```

---

**End of Beta Documentation**
**Total Implementation:** ~2,500 lines across 13 modules + 3 autoloads
**Adherence to <300 line guideline:** ✅ All files under limit
