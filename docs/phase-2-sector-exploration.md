# Phase 2: Sector Exploration Implementation Guide

## Overview

**Goal**: Build the primary gameplay loop - an infinite scrolling momentum-based sector exploration system

**Design Reference**: See `/docs/sector-exploration-module.md` for complete design specifications (1,324 lines)

**Status**: 🚧 **IN PROGRESS** - Core systems implemented, testing and iteration phase

**Current Progress** (Updated 2025-01-28):
- ✅ **Phase 2a Complete**: Infinite scrolling, player ship, grid background
- ✅ **Phase 2b Complete**: Swipe controls, gravity assist, W/S speed controls
- ✅ **Phase 2c In Progress**: Node spawning, proximity detection, popup system
- ⏳ Phase 2d: Alien encounter patterns (not started)
- ⏳ Phase 2e: Mothership pursuit (not started)

**Dependencies**:
- ✅ Phase 1 complete (EventBus, DataManager, GameState, ResourceManager)
- ✅ CSV databases populated (sector_nodes.csv, alien_sweep_patterns.csv, sector_progression.csv)
- ✅ Portrait UI framework established

**Deliverable**: Playable sector exploration with infinite scrolling, procedural nodes, swipe controls, and mothership pursuit

---

## 🎮 Implemented Systems Summary

### ✅ Completed Features
1. **Infinite Scrolling Grid System** - 3-tile looping background, smooth scrolling
2. **Player Ship Control** - Fixed Y position (1950), lateral movement only (30-1050px)
3. **Heavy Momentum Physics** - Smooth acceleration/deceleration with auto-centering
4. **Swipe & Keyboard Controls** - Touch/mouse swipe + WASD testing controls
5. **Speed Control** - W/S keys adjust speed in 0.1x increments (default 2.0x)
6. **CSV-Driven Node Spawning** - Weighted random selection, 1-3 nodes per 800px
7. **Proximity Detection System** - Area2D collision, time-pausing popups
8. **Gravity Assist Integration** - CSV multipliers (0.1x, 0.2x, 0.4x) with dynamic UI
9. **Control Lockout System** - Dynamic timer (0.5s per 0.1 multiplier) + proximity unlock
10. **Mobile-Optimized UI** - Large fonts (44-72px), PNG icons, 220x100px panels
11. **Orbiting Node System** - Moons, asteroids, stations orbit planets (dynamic from orbit=TRUE CSV nodes)
12. **Jump Mechanic** ✨ **NEW** - Charge-based lateral teleport with pulsing indicator:
    - Hold SPACE to charge (3 fuel start + 1 fuel/sec)
    - Min 100px, +100px per second charge
    - Dynamic direction (always toward opposite side of center)
    - Pulsing visual indicator shows landing position
    - 360° spin animation (0.5s), then teleport
    - 10-second cooldown
13. **Global IndicatorManager** ✨ **NEW** - Unified visual feedback system for all modules

### 🎯 Fine-Tuned Adjustments
- **Default Speed**: 2.0x (was 1.0x) - Better pacing for mobile
- **Auto-Center Force**: 0.2 (was 2.0) - Allows full edge access
- **Movement Bounds**: 30-1050px (was 50-1030px) - Wider lateral range
- **Control Lockout**: Dynamic based on gravity multiplier (was fixed 1s)
- **UI Sizing**: All elements 2-3x larger for mobile visibility
- **Resource Icons**: PNG images instead of emojis

### ⏳ Remaining Work
- Resource gathering mechanics (mining nodes, resource rewards)
- Combat trigger nodes (alien colonies, artifact vaults)
- Wormhole sector exit functionality
- Alien encounter patterns (Phase 2d)
- Mothership pursuit system (Phase 2e)

---

## Architecture Overview

### ⚠️ CRITICAL IMPLEMENTATION NOTE: Movement Model

**Player Movement**: Player ship **stays in fixed position** on screen (vertically centered or bottom third)
- Player **ONLY moves side-to-side** (lateral X position: 0-1080)
- Player does **NOT move forward** - Y position is fixed
- Camera **NEVER moves**

**World Movement**: Everything else moves past the player
- **Nodes spawn above** the player (off-screen at top)
- **Nodes move downward** at `current_scroll_speed` (affected by speed multiplier)
- **Grid background scrolls downward** to create sense of motion
- Player must **intercept/touch nodes** as they pass by

**Think**: Classic vertical scrolling shooter (Galaga, 1942, Space Invaders scrolling levels)

### Key Design Principles
1. **Infinite Scrolling**: Nodes spawn at top, move downward past player, despawn at bottom
2. **Fixed Player Position**: Player stays still, world moves past them
3. **Lateral Control Only**: Player swipes left/right to position horizontally
4. **Proximity Interaction**: Nodes trigger popups when passing within range of player (time pauses)
5. **CSV-Driven**: All node types, sweep patterns, and progression defined in data files
6. **Mobile-First**: Swipe controls, touch-optimized UI, portrait orientation

### Core Systems
- **SectorManager Singleton**: Orchestrates scroll speed, node spawning at top, node downward movement, alien encounter patterns
- **Fixed Player Position**: Player ship stays vertically centered/fixed, only moves horizontally
- **Swipe Controls**: Lateral steering (left/right movement only)
- **WASD controls** for testing purposes, add in WASD controls. A for left, D for right.
- **Jump Mechanic** ✅: Charge-based lateral teleport (SPACE key):
  - Hold to charge: Min 100px, +100px per second
  - Fuel cost: 3 to start + 1 per second charging
  - Dynamic direction: Always jumps toward opposite side of center (540px)
  - Visual indicator: Pulsing yellow/gold dot (via IndicatorManager)
  - Animation: 360° spin (0.5s), map stops scrolling during jump
  - Cooldown: 10 seconds after completion
- **Gravity Assist**: Scroll speed control (CSV-driven multipliers) costing 1 fuel - faster = nodes move faster
- **Proximity Popups**: Time-pausing node interaction when node passes near player
- **Alien Encounter Patterns**: Projectile formations move across/down screen, player must dodge

---

## Implementation Phases

**Philosophy**: Build incrementally and test each system before moving forward. See the ship move, then add mechanics, then add content, then add challenges.

### Phase 2a: Foundation - Player Ship & Infinite Scrolling ✅ COMPLETE

**Goal**: Get the basic infinite scrolling environment working with player ship movement

**Actual Effort**: ~4 hours

**Status**: ✅ Complete (implemented in `scenes/sector_exploration/sector_map.gd`)

**Implementation Notes**:
- Implemented as scene-based controller instead of singleton (simpler for prototyping)
- File: `scenes/sector_exploration/sector_map.gd` (~465 lines - may need refactor)
- All core functionality working

#### Task 1: Core Scrolling System ✅ COMPLETE

**File**: `scenes/sector_exploration/sector_map.gd` (implemented directly in scene controller)

**Core Responsibilities** (Phase 2a only - basic version):
- Track `scroll_distance` (cumulative distance traveled - for spawning logic)
- Track `player_lateral_position` (x-coordinate, 0-1080) - **player's only movement**
- Track `current_scroll_speed` (base speed × multiplier)
- Track `current_speed_multiplier` (starts at 1.0, will be modified in Phase 2b)
- Basic `_process()` loop for updating scroll distance
- Jump cooldown timer (will be used in Phase 2b)

**IMPORTANT**: Player ship does NOT move forward - it stays at a fixed Y position!

**Key Variables** (Phase 2a - minimal):
```gdscript
# Scrolling (world movement, not player movement)
var scroll_distance: float = 0.0  # Total distance traveled (for spawning logic)
var base_scroll_speed: float = 100.0  # pixels/second downward
var current_speed_multiplier: float = 1.0  # Modified by gravity assist
var current_scroll_speed: float = 100.0  # base_scroll_speed × multiplier

# Player position (FIXED Y, only X changes)
var player_lateral_position: float = 540.0  # X position (0-1080), center = 540
const PLAYER_Y_POSITION: float = 1950.0  # Fixed Y position (bottom third of 2340px screen)

# Other
var jump_cooldown_remaining: float = 0.0
```

**Critical `_process()` Loop** (Phase 2a - basic):
```gdscript
func _process(delta: float) -> void:
    # Update scroll distance (virtual forward movement)
    current_scroll_speed = base_scroll_speed * current_speed_multiplier
    scroll_distance += current_scroll_speed * delta

    # Update jump cooldown
    if jump_cooldown_remaining > 0:
        jump_cooldown_remaining -= delta

    # Emit updates
    EventBus.scroll_speed_updated.emit(current_scroll_speed, scroll_distance)
    EventBus.player_position_updated.emit(player_lateral_position, PLAYER_Y_POSITION)
```

**Note**: Nodes will spawn at top and move downward in later phases

**Success Criteria** (Phase 2a):
- [x] ✅ Scrolling system functional (scene-based implementation)
- [x] ✅ Forward distance tracking implemented
- [x] ✅ Player lateral position tracked (0-1080 with 30px margins)
- [x] ✅ Basic `_process()` loop working
- [x] ⚠️ File size: 465 lines (exceeds 200 target - refactor recommended)

**Reference**: `/docs/sector-exploration-module.md` lines 805-890 (SectorManager spec)

---

#### Task 2: Grid Background & Infinite Scrolling

**File**: `scenes/sector_map.tscn` + `scripts/sector_map.gd` (~120 lines for Phase 2a)

**Scene Structure** (Phase 2a - minimal):
```
Control (sector_map.gd) [1080x2340]
├── Node2D (MapContainer)
│   ├── Node2D (GridBackground)
│   │   └── Multiple Sprite2D tiles that move downward
│   ├── Node2D (NodesLayer)
│   │   └── [Nodes spawn here and move downward - Phase 2c]
│   └── Sprite2D (PlayerShip)
│       ├── Position: (540, 1950) - FIXED Y, only X changes
│       └── Texture: res://assets/ships/havoc_fighter.png
└── CanvasLayer (UIOverlay)
    └── VBoxContainer
        ├── Label (Speed: 1.0x)
        └── Label (Distance: 0)
```

**Core Responsibilities** (Phase 2a):
- **Grid background scrolls downward** at `current_scroll_speed`
- Grid wraps/tiles infinitely (when tile goes off bottom, reposition at top)
- **Player ship stays at FIXED position**: `(player_lateral_position, 1950)`
- **No camera movement** - camera is static, locked to Control node
- Update speed and distance UI labels
- Player ship sprite rotates slightly when moving left/right (visual polish)

**Grid Scrolling Implementation**:
```gdscript
# In sector_map.gd _process()
func _process(delta: float) -> void:
    # Move grid tiles downward
    for tile in grid_tiles:
        tile.position.y += SectorManager.current_scroll_speed * delta

        # Wrap tile when it goes off bottom
        if tile.position.y > 2340:  # Screen height
            tile.position.y -= grid_tile_height * grid_tiles.size()
```

**Camera**:
- No Camera2D node needed (or Camera2D with no follow)
- Everything stays in viewport bounds
- World moves, camera doesn't

**Success Criteria** (Phase 2a):
- [x] ✅ Grid background displays and tiles infinitely (3-tile scrolling system)
- [x] ✅ No visible seams in background
- [x] ✅ Player ship visible at correct position (540, 1950)
- [x] ✅ Speed and distance UI update correctly
- [x] ✅ Portrait orientation (1080x2340)
- [x] ✅ Resource display with PNG icons (fuel, metal, crystals, speed)
- [x] ✅ **TEST PASSED: Ship scrolls through grid smoothly**

---

### Phase 2b: Swipe Controls & Gravity Assist ✅ COMPLETE

**Goal**: Add lateral steering and speed control - make the ship feel responsive

**Actual Effort**: ~3 hours

**Status**: ✅ Complete with fine-tuning iterations

**Why Second**: Ship movement foundation is complete, now add player control

#### Task 3: Swipe Lateral Steering ✅ COMPLETE

**File**: Implemented in `scenes/sector_exploration/sector_map.gd` (lines 94-197)

**Implementation**:
- Detect swipe gestures (left/right) anywhere on screen
- Apply lateral acceleration: `accel = BASE_ACCEL / (1 + speed_multiplier * 0.5)`
- Update `SectorManager.player_lateral_position`
- Auto-center when no input (gradual return to x=540)
- Visual feedback: Ship rotates slightly toward movement direction

**Success Criteria** (Phase 2b):
- [x] ✅ Swipe detection works (mouse and touch)
- [x] ✅ WASD controls added (A/D for lateral, W/S for speed)
- [x] ✅ Ship auto-centers with reduced force (0.2 instead of 2.0)
- [x] ✅ Smooth lateral movement with momentum physics
- [x] ✅ Movement bounds: 30px to 1050px (allows edge access)
- [x] ✅ **TEST PASSED: Responsive steering with good feel**

**Fine-Tuned Physics Constants**:
- `BASE_ACCELERATION: 800.0` - Lateral acceleration
- `VELOCITY_DAMPING: 0.92` - 8% decay per frame
- `AUTO_CENTER_FORCE: 0.2` - **Reduced from 2.0** for better edge access
- `MAX_LATERAL_VELOCITY: 400.0` - Speed cap
- Movement bounds: `30.0 to 1050.0` - **Adjusted from 50-1030** for wider range

---

#### Task 4: Gravity Assist (Speed Control)

**File**: Enhancement to `scripts/sector_map.gd` + `SectorManager.gd` (~40 lines)

**UI**: Two buttons (or single button with popup):
- "Speed Up (+20%)" button
- "Slow Down (-20%)" button

**Implementation**:
- Button tap validates fuel: `ResourceManager.can_spend({"fuel": 1})`
- Execute: `SectorManager.current_speed_multiplier += 0.2` or `-= 0.2`
- Spend 1 fuel
- Update UI speed display
- Speed persists until next gravity assist use

**Success Criteria** (Phase 2b):
- [x] ✅ W/S keyboard controls for speed (W = faster, S = slower)
- [x] ✅ Speed changes in 0.1x increments per press
- [x] ✅ Minimum speed: 0.1x (prevents stopping)
- [x] ✅ **Default speed: 2.0x** (changed from 1.0x for better pacing)
- [x] ✅ UI displays current speed multiplier
- [x] ✅ **TEST PASSED: Speed control responsive and visible**

**Implementation Notes**:
- Keyboard controls added for development testing (W/S for speed, A/D for lateral)
- Default base speed multiplier set to 2.0x instead of 1.0x
- Speed changes persist until modified again

---

#### Task 5: Jump Mechanic (Optional for Phase 2b)

**File**: Enhancement to `scripts/sector_map.gd` + `SectorManager.gd` (~40 lines)

**UI**: Jump button (bottom-right) shows fuel cost + cooldown timer

**Note**: Jump can be added later when dodging becomes necessary (Phase 2d with alien patterns)

**Implementation**:
- Button tap opens directional input (swipe left/right to choose direction)
- Validate: `ResourceManager.can_spend({"fuel": 10})` AND `jump_cooldown_remaining <= 0`
- Execute: Instant 200-300px lateral movement
- Start cooldown: 10-15 seconds
- Does NOT affect forward speed

**Success Criteria** (if implemented in Phase 2b):
- [ ] Jump costs 10 fuel + cooldown
- [ ] Button grays out when unavailable
- [ ] Directional input works
- [ ] Cooldown timer displays correctly

**Recommendation**: Skip jump for now, add in Phase 2d when alien patterns require it

---

### Phase 2c: Node System - Build Foundation Incrementally 🚧 IN PROGRESS

**Goal**: Add nodes one by one, testing each before moving to the next

**Current Effort**: ~5 hours so far

**Status**: 🚧 Core systems complete, node variety in progress

**Why Third**: Movement feels good, now add content to interact with

**Strategy**: Start simple (test nodes), add complexity gradually (planets with gravity assist), finish with special nodes (wormholes, colonies)

#### Task 6: Node Spawning System (Add to SectorManager)

**File**: Enhancement to `SectorManager.gd` (~80 lines added)

**New Variables**:
```gdscript
var active_nodes: Array[Dictionary] = []
var last_spawn_distance: float = 0.0
var node_id_counter: int = 0
const NODE_SPAWN_INTERVAL: float = 400.0  # Spawn node every 400px of scrolling
```

**New Functions**:
```gdscript
func spawn_node_at_top() -> void  # Spawns node off-screen at top
func despawn_nodes_off_bottom() -> void  # Removes nodes that passed bottom
func create_node(node_type: String, x_position: float) -> Dictionary
```

**_process() additions**:
```gdscript
# Spawn nodes periodically
if scroll_distance - last_spawn_distance >= NODE_SPAWN_INTERVAL:
    spawn_node_at_top()
    last_spawn_distance = scroll_distance

# Move all active nodes downward
for node in active_nodes:
    node.visual_instance.position.y += current_scroll_speed * delta

# Despawn nodes that went off bottom
despawn_nodes_off_bottom()
```

**Node Spawn Logic**:
- Nodes spawn at `y = -100` (just above screen top)
- Random `x` position based on node type and proximity requirements
- Node data stored in `active_nodes` array with reference to visual instance

**Success Criteria**:
- [x] ✅ Nodes spawn above screen (y = -500)
- [x] ✅ Nodes move downward at `current_scroll_speed`
- [x] ✅ Nodes despawn when y > 2500
- [x] ✅ `active_nodes` array tracks spawned nodes
- [x] ✅ EventBus signals emit on spawn/despawn
- [x] ✅ CSV-driven spawning (1-3 nodes per spawn interval)
- [x] ✅ Weighted random selection from sector_nodes.csv
- [x] ✅ **TEST PASSED: Nodes spawn and scroll correctly**

**Implementation Details**:
- Spawn interval: 800px of scrolling
- Spawn positions: left (30px), center (150-930px), right (1050px)
- CSV integration: Reads spawn_weight, spawn_case, proximity_radius, gravity_assist_multiplier

---

#### Task 7: BaseNode Component

**File**: `scenes/nodes/base_node.tscn` + `scripts/nodes/base_node.gd` (~120 lines)

**Scene Structure**:
```
Area2D (base_node.gd)
├── CollisionShape2D (proximity detection radius)
├── Sprite2D (node icon)
└── Label (node type name)
```

**Core Functionality**:
- **Downward movement**: Node moves at `SectorManager.current_scroll_speed` (handled by SectorManager)
- **Proximity detection**: Check distance to player position each frame as node passes
- Trigger popup when node is within 150-200px of player ship (both X and Y distance)
- **Pause game time**: `get_tree().paused = true` when popup visible (stops scrolling)
- Resume time when popup dismissed (resume scrolling)
- Mark as activated if player interacts
- Node continues moving downward after interaction (unless time paused)

**Success Criteria**:
- [x] ✅ Proximity detection works (Area2D with proximity radius)
- [x] ✅ Time pauses when popup appears (`get_tree().paused = true`)
- [x] ✅ Popup shows node info and gravity assist options
- [x] ✅ Time resumes on dismiss
- [x] ✅ Gravity assist multiplier displayed from CSV
- [x] ✅ Dynamic button text shows actual multiplier values
- [x] ✅ **TEST PASSED: Proximity system functional**

**Implemented Features**:
- Popup UI: 960x1200px panel (mobile-optimized)
- Font sizes: 72px title, 48px body, 40-52px buttons
- Gravity assist buttons show CSV multiplier (e.g., "Faster +0.4x")
- Node activation prevents re-triggering (marked as activated)

**Reference**: `/docs/sector-exploration-module.md` lines 700-724 (Proximity system)

---

#### Task 8: Implement Nodes Incrementally

**Strategy**: Implement and test each node type before moving to the next

**Recommended Order**:

**Week 1 Foundation (Simple Nodes)**:
1. **Asteroid** (instant collect) - Simplest, good first test
   - Spawns at top, moves downward
   - No proximity popup, just collision detection with player ship
   - Instant resource grant: 10-50 metal/crystals when player touches it
   - Good for testing spawning/despawning/scrolling
   - **TEST**: See asteroids spawn at top, scroll down, collect when touching player

2. **Outpost** (instant reward) - Test proximity popup
   - Spawns at top, moves downward
   - Proximity popup appears when node passes within 150-200px of player: "Scavenge Outpost"
   - Grant 20-50 metal, 10-30 crystals
   - First node with time pause (scrolling stops when popup visible)
   - **TEST**: Popup appears as node passes near player, time pauses, resources granted, scrolling resumes

3. **Wormhole** (exit node) - Test sector progression
   - Proximity popup: "Enter Wormhole"
   - Triggers sector transition
   - **TEST**: Can complete a sector

**Week 2 Complexity (Gravity Assist Nodes)**:
4. **Moon** (weak gravity assist + mining)
   - Proximity popup with 3 options: Turn Into (speed up), Turn Away (slow down), Mine Resources
   - Tests gravity assist integration with nodes
   - **TEST**: Gravity assist works from node popup

5. **Rocky Planet** (moderate gravity assist + metal mining)
6. **Ice Planet** (moderate gravity assist + crystal mining)
7. **Gas Giant** (strong gravity assist + fuel mining)

**Week 3 Special (Advanced Nodes)**:
8. **Alien Colony** (optional combat trigger)
   - Proximity popup: "Engage" or "Avoid"
   - If engaged, triggers combat (Phase 3 integration)
   - **TEST**: Can choose to engage or avoid

9. **Artifact Vault** (40% combat chance, legendary rewards)
10. **Trader** (shop UI - placeholder for Phase 4)
11-16. Remaining nodes as needed

**Success Criteria per node**:
- [x] ✅ Test nodes spawning with CSV data
- [x] ✅ Spawns above screen (y = -500)
- [x] ✅ Moves downward at `current_scroll_speed`
- [x] ✅ Proximity detection works (using CSV proximity_radius)
- [x] ✅ Time pauses on popup (scrolling stops)
- [x] ✅ Gravity assist integration (CSV-driven multipliers)
- [x] ✅ Control lockout system (dynamic timer based on multiplier)
- [ ] ⏳ Resource gathering (placeholder values)
- [x] ✅ Node despawns when y > 2500
- [x] ✅ **TEST PASSED: Can interact with nodes as they pass**

**Completed Node Features**:
- ✅ Gravity assist with CSV multipliers (0.1x, 0.2x, 0.4x)
- ✅ Dynamic control lockout (0.5s per 0.1 multiplier)
- ✅ Proximity-based unlock with 1.5s failsafe timer
- ✅ Visual feedback (activated nodes turn green)
- ✅ Impulse physics (ship pushed toward/away from node)

**Node Types Implemented**:
- [x] ✅ Test nodes (all CSV types spawn correctly)
- [ ] ⏳ Resource gathering mechanics (next priority)
- [ ] ⏳ Combat trigger nodes
- [ ] ⏳ Wormhole (sector exit)

**Reference**: `/docs/sector-exploration-module.md` lines 80-455 (All node types)

---

### Phase 2d: Alien Encounter Patterns (Bullet-Hell System)

**Goal**: Add periodic projectile patterns that create challenge and trigger combat

**Estimated Effort**: 4-5 hours

**Why Fourth**: Core gameplay loop working, now add the primary combat trigger mechanism

**Note**: This is where Jump mechanic becomes important for dodging

#### Task 9: Jump Mechanic (NOW CRITICAL)

**File**: Enhancement to `scripts/sector_map.gd` + `SectorManager.gd` (~40 lines)

**Why Now**: Needed for dodging alien projectile patterns

**UI**: Jump button (bottom-right) shows fuel cost + cooldown timer

**Implementation**:
- Button tap opens directional input (swipe left/right to choose direction)
- Validate: `ResourceManager.can_spend({"fuel": 10})` AND `jump_cooldown_remaining <= 0`
- Execute: Instant 200-300px lateral movement
- Start cooldown: 10-15 seconds

**Success Criteria**:
- [ ] Jump costs 10 fuel + cooldown
- [ ] Button grays out when unavailable
- [ ] Directional input works
- [ ] Cooldown timer displays
- [ ] **TEST: Can jump to dodge obstacles**

---

#### Task 10: Encounter Pattern System

**File**: New `scripts/autoloads/EncounterPatternManager.gd` (~200 lines)

**Why Separate File**: Keeps SectorManager under 300 lines, focused responsibility

**Implementation**:
- Timer-based spawning (60-180s intervals, from CSV)
- Choose random pattern (horizontal wave, diagonal cross, pincer, spiral)
- **Phase 1 - Warning** (3-5s countdown):
  - Display pattern name and trajectory overlay
  - Show countdown timer
  - Play warning audio
- **Phase 2 - Projectile Pattern** (5-15s):
  - Spawn alien ships as projectiles flying across screen in formation
  - Track `combat_difficulty` counter (starts at 0)
  - On collision: `combat_difficulty += 1` + visual/audio feedback
  - Display hit counter to player
  - Update projectile positions in `_process()`
- **Phase 3 - Combat Trigger** (automatic):
  - When all projectiles have passed, trigger combat
  - Pass `combat_difficulty` to combat system for difficulty scaling
  - 0 hits = base difficulty, 1-2 = +1 elite, 3-4 = +2 elites, 5-6 = +3 elites, 7+ = boss

**Recommended Implementation Order**:
1. **Warning System** - Get warning display working first
2. **Single Horizontal Pattern** - Implement simplest pattern
3. **Hit Detection** - Track combat_difficulty accumulation
4. **Combat Trigger** - Trigger combat after pattern (stub for now)
5. **Additional Patterns** - Add diagonal, pincer, spiral

**Success Criteria**:
- [ ] Warning phase displays correctly with countdown (3-5s)
- [ ] Projectiles spawn in formations
- [ ] Collision detection accumulates combat_difficulty
- [ ] Hit counter displays to player ("Hits: 3")
- [ ] Combat triggers after pattern completes (stub for Phase 3)
- [ ] Player can dodge with steering + jump
- [ ] At least 2 patterns work (horizontal + diagonal)
- [ ] **TEST: Can dodge patterns perfectly (0 hits) or fail and accumulate hits**

**Reference**: `/docs/sector-exploration-module.md` lines 647-730 (Alien Encounter System)

---

### Phase 2e: Mothership Pursuit System

**Goal**: Add the pursuing mothership threat - creates urgency

**Estimated Effort**: 2-3 hours

**Why Fifth**: Combat triggers working, now add time pressure

#### Task 11: Mothership Pursuit System

**File**: Enhancement to `SectorManager.gd` (~80 lines added)

**New Variables**:
```gdscript
var mothership_position: float = -8000.0  # Negative = behind player
var mothership_speed: float = 80.0
var mothership_acceleration: float = 0.6
```

**_process() additions**:
```gdscript
# Update mothership
mothership_speed += mothership_acceleration * delta
mothership_position += mothership_speed * delta

# Check if caught
if mothership_position >= player_forward_distance:
    _game_over_mothership_caught()

# Emit distance updates
EventBus.mothership_distance_updated.emit(get_mothership_distance())
```

**UI Elements**:
- Top-center label: "Mothership: 4500px"
- Turns red when ≤2000px
- Warning sound at 3000px, 2000px, 1000px
- (Optional) Visual mothership sprite in background when close

**Success Criteria**:
- [ ] Mothership spawns behind player at correct distance
- [ ] Accelerates over time (gets faster)
- [ ] Distance display updates in real-time
- [ ] Display turns red at ≤2000px
- [ ] Game over triggers when caught
- [ ] Warning sounds play at thresholds
- [ ] **TEST: Mothership catches player if they idle too long**

**Reference**: `/docs/sector-exploration-module.md` lines 584-645 (Mothership spec)

---

## CSV Data Integration

All node types, sweep patterns, and progression data are defined in CSV files:

### sector_nodes.csv
- 16 node types with spawn weights, proximity radius, resources, combat chances
- Loaded by `DataManager.get_node_config(node_type)`

### alien_sweep_patterns.csv
- 10 sweep patterns with speeds, widths, sector requirements
- Loaded by `DataManager.get_sweep_pattern(pattern_id)`

### sector_progression.csv
- 20 sectors with mothership distances, speeds, wormhole frequency
- Loaded by `DataManager.get_sector_progression(sector_number)`

**Reference**: `/docs/sector-exploration-module.md` lines 994-1078 (CSV spec)

---

## Testing Checklist

### Core Infinite Scrolling
- [ ] Player ship moves forward automatically
- [ ] Camera follows player smoothly
- [ ] Background tiles infinitely without seams
- [ ] No console errors during movement

### Procedural Generation
- [ ] Nodes spawn ahead (2000-3000px)
- [ ] Nodes despawn behind (500px)
- [ ] No overlapping nodes
- [ ] Wormholes spawn periodically
- [ ] Node density feels appropriate

### Movement Controls
- [ ] Swipe left/right steers ship
- [ ] Faster speed = harder to maneuver
- [ ] Ship auto-centers when no input
- [ ] Jump costs fuel + cooldown
- [ ] Gravity assist changes speed

### Proximity & Interaction
- [ ] Popup appears within proximity range
- [ ] **Time pauses** when popup visible
- [ ] Node options display correctly
- [ ] "Continue" dismisses popup
- [ ] Time resumes on dismiss

### Mothership Pursuit
- [ ] Mothership spawns behind player
- [ ] Distance display updates
- [ ] Warning at 2000px
- [ ] Game over when caught
- [ ] Spawn distance decreases per sector

### Alien Encounter Patterns
- [ ] Warning phase displays (3-5s countdown)
- [ ] Projectile patterns spawn correctly
- [ ] Collision accumulates combat_difficulty
- [ ] Hit counter displays to player
- [ ] Combat triggers after pattern completes
- [ ] Difficulty scales based on hits taken (0, 1-2, 3-4, 5-6, 7+)
- [ ] Player can dodge with steering/jump
- [ ] Patterns vary correctly (horizontal, diagonal, pincer, spiral)

### Resource Integration
- [ ] Resources update on collection
- [ ] Fuel spending validated
- [ ] EventBus signals fire correctly
- [ ] Cannot overspend fuel

**Complete Testing Checklist**: `/docs/sector-exploration-module.md` lines 1108-1183

---

## File Size Compliance

All scripts must stay under 300 lines:

| File | Target | Status |
|------|--------|--------|
| SectorManager.gd | ~280 | ⚠️ Close to limit - may need AlienSweepManager split |
| sector_map.gd | ~200 | ✅ Safe |
| base_node.gd | ~120 | ✅ Safe |
| Node types (×16) | ~70-100 each | ✅ Safe |
| AlienSweepManager.gd | ~150 (if split) | ✅ Safe |

**Total Estimated**: ~2,000 lines across 20 files (avg 100 lines/file)

---

## EventBus Signals (Add to EventBus.gd)

```gdscript
# Sector Lifecycle
signal sector_entered(sector_number: int)
signal sector_exited()
signal wormhole_reached()

# Node Generation & Interaction
signal node_spawned(node_id: String, node_type: String, position: Vector2)
signal node_despawned(node_id: String)
signal node_proximity_entered(node_id: String, node_type: String)
signal node_activated(node_id: String)

# Movement & Speed
signal player_position_updated(forward_distance: float, lateral_position: float)
signal speed_changed(new_multiplier: float)
signal jump_executed(direction: String, fuel_cost: int)
signal jump_cooldown_started(cooldown_duration: float)
signal gravity_assist_activated(speed_change: String, new_multiplier: float)

# Mothership
signal mothership_distance_updated(distance: float)
signal mothership_warning(distance: float)
signal mothership_caught_player()

# Alien Encounter Patterns
signal encounter_pattern_warning(pattern_type: String, countdown: float)
signal encounter_pattern_started(pattern_id: String)
signal encounter_hit_taken(combat_difficulty: int)  # Emitted on each collision
signal encounter_pattern_completed(final_combat_difficulty: int)  # Triggers combat
```

**Reference**: `/docs/sector-exploration-module.md` lines 763-801

---

## Common Implementation Pitfalls

1. ❌ **Don't forget procedural spawning** - Nodes must spawn ahead and despawn behind
2. ❌ **Don't pause time incorrectly** - Only proximity popups pause, not other systems
3. ❌ **Don't skip fuel AND cooldown validation** - Jump requires both
4. ❌ **Don't exceed 300 lines** - Split SectorManager if needed
5. ❌ **Don't test desktop only** - Swipe controls differ from mouse
6. ❌ **Don't forget speed affects maneuverability** - Critical formula
7. ❌ **Don't render off-screen nodes** - Only camera view + margin
8. ❌ **Don't use direct script references** - All communication via EventBus
9. ❌ **Don't let mothership spawn too close** - Balance per sector
10. ❌ **Don't forget to emit EventBus signals** - Required for decoupling

---

## Integration with Other Modules

### → Combat Module (Phase 3)
- **Trigger**: Alien encounter pattern completion (scaled difficulty), alien colony (optional), artifact vault (40% chance)
- **Flow**: Sector Map → Situation Room → Combat → Return to Sector Map
- **Rewards**: Resources added after combat victory
- **Failure**: Return to sector map, can retry

### → Hangar Module (Phase 4)
- **Trigger**: Trader node activation or pre-combat prep
- **Flow**: Sector Map → Hangar/Shop UI → Sector Map
- **Purchases**: Spend Metal/Crystals on upgrades/equipment

### → Save/Load System
**Save Data**:
- Current sector, player position (forward/lateral)
- Active nodes, activated nodes
- Mothership state
- Resources, fleet composition

---

## Completion Criteria

Phase 2 is complete when:

- ✅ Infinite scrolling works smoothly (automatic forward movement)
- ✅ Swipe controls functional (speed affects maneuverability)
- ✅ Jump and gravity assist work (fuel + cooldown validation)
- ✅ Proximity popups appear and **pause time**
- ✅ At least 8 node types implemented (including wormhole)
- ✅ Mothership pursuit operational (spawns behind, accelerates, catches player)
- ✅ Alien encounter pattern system functional (warning, projectiles, hit accumulation, scaled combat)
- ✅ All systems integrate via EventBus (no direct references)
- ✅ All scripts under 300 lines
- ✅ No console errors
- ✅ Resource gathering works
- ✅ Wormhole advances to next sector

**Next Phase**: Phase 3 - Combat System (15×25 grid autobattler)

**Estimated Total Effort**: 15-20 hours for experienced Godot developer

---

## Quick Start Implementation Order (NEW - Incremental Approach)

**Week 1: Foundation**
1. **Day 1**: SectorManager (basic) + grid background + player ship (Phase 2a)
   - **TEST**: Ship moves forward through grid
2. **Day 2**: Swipe steering + gravity assist buttons (Phase 2b)
   - **TEST**: Can steer left/right, speed up/slow down
3. **Day 3**: Node spawning system + BaseNode component (Phase 2c start)
   - **TEST**: Nodes spawn and despawn correctly

**Week 2: Content**
4. **Day 4**: Asteroid + Outpost + Wormhole nodes (Phase 2c)
   - **TEST**: Can collect resources, proximity popups work, can exit sector
5. **Day 5**: Moon + Planet nodes with gravity assist integration (Phase 2c)
   - **TEST**: Gravity assist from nodes works
6. **Day 6**: Alien Colony + more nodes (Phase 2c)
   - **TEST**: Full node variety working

**Week 3: Challenge**
7. **Day 7**: Jump mechanic + warning system (Phase 2d start)
   - **TEST**: Can jump to dodge
8. **Day 8**: First alien encounter pattern (horizontal wave) (Phase 2d)
   - **TEST**: Pattern spawns, can dodge, combat triggers
9. **Day 9**: Additional patterns + hit accumulation (Phase 2d)
   - **TEST**: Different patterns work, difficulty scales
10. **Day 10**: Mothership pursuit system (Phase 2e)
    - **TEST**: Mothership catches player if idle

**Week 4: Polish**
11. **Day 11-12**: Testing, bug fixes, balancing
12. **Day 13-14**: Ready for Phase 3 (Combat System)

---

---

## 📁 Current File Structure

**Implemented Files**:
- `scenes/sector_exploration/sector_map.tscn` - Main scene (1080x2340 Control node)
- `scenes/sector_exploration/sector_map.gd` - **465 lines** ⚠️ (needs refactor to <300)
- `scenes/sector_exploration/node_popup.tscn` - Proximity interaction UI (960x1200 panel)
- `scenes/sector_exploration/node_popup.gd` - **99 lines** ✅
- `scenes/sector_exploration/test_node.tscn` - Generic node scene
- `scenes/sector_exploration/test_node.gd` - **120 lines** ✅
- `scenes/sector_exploration/grid_tile.gd` - Background tile helper
- `data/sector_nodes.csv` - 8 node types with spawn weights, gravity multipliers
- `assets/Icons/` - fuel_icon.png, metal_small_icon.png, crystal_small_icon.png

**EventBus Signals Added**:
- `node_spawned(node_id, node_type, position)`
- `node_despawned(node_id)`
- `node_proximity_entered(node_id, node_type)`
- `node_proximity_exited(node_id)`
- `node_activated(node_id)`
- `gravity_assist_applied(choice, node_position, multiplier)`

---

## 🎯 Next Immediate Priorities

### Priority 1: Resource Integration
- Connect ResourceManager to node interactions
- Implement mining node resource rewards
- Add fuel costs for gravity assist (currently free)
- Display resource changes in UI

### Priority 2: File Size Compliance
- **Refactor sector_map.gd** (currently 465 lines → target <300)
- Extract node spawning to separate manager
- Extract gravity assist logic to helper

### Priority 3: Node Variety
- Implement resource gathering nodes (asteroid, outpost)
- Add wormhole sector exit functionality
- Create combat trigger nodes (alien colony, artifact vault)

### Priority 4: Phase 2d - Alien Patterns
- Jump mechanic implementation
- Encounter warning system
- Bullet pattern spawning

---

**For complete design specifications, formulas, and detailed mechanics, always reference `/docs/sector-exploration-module.md`**
