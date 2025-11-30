# Phase 2: Sector Exploration Implementation Guide

## Overview

**Goal**: Build the primary gameplay loop - an infinite scrolling momentum-based sector exploration system

**Design Reference**: See `/docs/sector-exploration-module.md` for complete design specifications (1,324 lines)

**Status**: 🚧 **IN PROGRESS** - Core systems complete, ready for node function implementation

**Current Progress** (Updated 2025-01-30):
- ✅ **Phase 2a Complete**: Infinite scrolling, player ship, grid background
- ✅ **Phase 2b Complete**: Simplified movement system (modular architecture)
- ✅ **Phase 2c Complete**: Boost, brake, jump, gravity assist systems
- ✅ **Phase 2d Complete**: Node spawning, orbiters, proximity detection
- ✅ **Phase 2e Complete**: Tractor beam debris collection system
- ⏳ Phase 2f: Resource collection mechanics (mining, trading)
- ⏳ Phase 2g: Alien encounter patterns (not started)
- ⏳ Phase 2h: Mothership pursuit (not started)

**Dependencies**:
- ✅ Phase 1 complete (EventBus, DataManager, GameState, ResourceManager)
- ✅ CSV databases populated (sector_nodes.csv, alien_sweep_patterns.csv, sector_progression.csv)
- ✅ Portrait UI framework established

**Deliverable**: Playable sector exploration with infinite scrolling, procedural nodes, swipe controls, and mothership pursuit

---

## 🎮 Implemented Systems Summary

### ✅ Completed Features

#### **Core Architecture (Modular Design)**
1. **sector_map.gd** (380 lines) - Main coordinator for all systems
2. **scrolling_system.gd** (88 lines) - Grid scrolling, speed management
3. **player_movement.gd** (129 lines) - Simple lateral physics
4. **boost_system.gd** (113 lines) - Speed increase with gravity multiplier
5. **brake_system.gd** (97 lines) - Speed decrease, free in gravity zones
6. **gravity_system.gd** (115 lines) - Gravity zone tracking, visual feedback
7. **jump_system.gd** (246 lines) - Charge-based teleport with cooldown
8. **node_spawner.gd** (474 lines) - Procedural generation, orbiters, tractor beam integration
9. **tractor_beam_system.gd** (167 lines) - Debris collection via tractor beam lock

#### **Movement & Controls**
- **Infinite Scrolling** - 3-tile looping grid (2340px height each)
- **Fixed Player Y** - Ship at Y=1950, lateral movement only (30-1050px)
- **Simple Lateral Physics** - Clean acceleration/deceleration, no complex bow swing
- **Swipe Controls** - Touch/mouse drag for lateral movement
- **Keyboard Controls** - A/D for left/right, Shift/S for boost/brake, Space for jump

#### **Speed Control Systems**
- **Boost (Shift)** - +0.1x/sec, costs 1 fuel/sec, multiplied by gravity zones
- **Brake (S)** - -0.2x/sec, costs 0.5 fuel/sec, FREE in gravity zones
- **Jump (Space)** - Charge-based teleport, 3 fuel + 1/sec, 10s cooldown with visual indicator
- **Speed Range** - 1.0x minimum, 10.0x maximum

#### **Gravity Assist System**
- **Green Zone Visuals** - Proximity radius outlines appear when boosting
- **Boost Multiplier** - CSV-driven (2x, 3x, 4x) multiplies boost gain
- **Free Braking** - No fuel cost when braking in gravity zones
- **Zone Detection** - Real-time tracking via gravity_system

#### **Node Systems**
- **CSV-Driven Spawning** - Weighted random, 1-3 nodes per 800px
- **Orbiting Nodes** - Moons, asteroids orbit planets (orbit=TRUE nodes)
- **Proximity Detection** - Area2D collision (popups DISABLED but system functional)
- **29+ Node Types** - All spawn cases and environmental bands

#### **Tractor Beam Collection System**
- **Debris Collection** - Asteroids collected via tractor beam (not proximity)
- **Beam Lock Range** - 100px activation range
- **Pull Duration** - 2.0 seconds to collect
- **Simultaneous Beams** - 3 max active at once
- **Visual Feedback** - Cyan tint on locked debris
- **Passive Attraction** - Disabled (0px range), potential future upgrade
- **Debug Controls** - 5 tunable parameters (range, speed, duration, count)

#### **Visual Feedback**
- **IndicatorManager** - Global singleton for all visual indicators
- **Jump Indicator** - Yellow pulsing dot shows landing position
- **Cooldown Indicator** - Orange circular progress over ship (10s)
- **Gravity Zones** - Green outlines around gravity nodes when boosting
- **Mobile-Optimized UI** - Large fonts, PNG icons, 220x100px panels

### 🎯 Fine-Tuned Adjustments
- **Default Speed**: 2.0x (was 1.0x) - Better pacing for mobile
- **Auto-Center Force**: 0.2 (was 2.0) - Allows full edge access
- **Movement Bounds**: 30-1050px (was 50-1030px) - Wider lateral range
- **Control Lockout**: Dynamic based on gravity multiplier (was fixed 1s)
- **UI Sizing**: All elements 2-3x larger for mobile visibility
- **Resource Icons**: PNG images instead of emojis

### ⏳ Future Work: Phase 2f - Resource Collection
- **Mining Nodes** - Long-press interaction, resource extraction
- **Trading Nodes** - Shop interface, buy/sell mechanics
- **Outpost Nodes** - Instant resource grants
- **Combat Nodes** - Trigger transition to combat module
- **Treasure Nodes** - Loot collection, blueprint drops
- **Wormhole Nodes** - Sector transition, progression tracking

### ⏳ Future Work: Phase 2g-h
- **Phase 2g**: Alien encounter patterns (horizontal, diagonal, pincer, wave)
- **Phase 2h**: Mothership pursuit system (distance-based spawning, acceleration)
- **Polish**: Sound effects, particle effects, screen shake
- **Testing**: Mobile touch controls, performance optimization

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

## 🚀 Phase 2e: Node Functions Implementation

### Overview
Implement actual interactions with nodes when player passes through their proximity zones. Each node type will have specific behaviors (mining, trading, combat triggers, etc.).

### Architecture Approach
Create individual node interaction systems:
- **interaction_manager.gd** - Coordinator for all node interactions
- **mining_interaction.gd** - Mining node logic (long-press, resource extraction)
- **trading_interaction.gd** - Shop interface, buy/sell
- **combat_trigger.gd** - Transition to combat module
- Keep each system under 300 lines

### Node Types to Implement

#### 1. **Mining Nodes** (asteroid, comet, debris_field)
- **Interaction**: Long-press on node
- **Mechanic**: Resource extraction (metal, crystals)
- **CSV Data**: `min_resources`, `max_resources`
- **Speed Requirement**: Must be below threshold (e.g., ≤3.0x) via SpeedVisionManager
- **UI**: Mining progress bar, resource counter

#### 2. **Outpost Nodes** (outpost, colony)
- **Interaction**: Automatic on proximity
- **Mechanic**: Instant resource grant
- **One-time**: Mark as used, change visual
- **CSV Data**: Fixed rewards

#### 3. **Trading Nodes** (trader, merchant_station)
- **Interaction**: Tap to open shop
- **Mechanic**: Buy/sell interface
- **UI**: Item list, prices, confirm buttons
- **Pause**: Time pauses during shop

#### 4. **Combat Trigger Nodes** (alien_colony, artifact_vault, derelict_station)
- **Interaction**: Automatic or tap
- **Mechanic**: Transition to combat module
- **CSV Data**: `combat_chance` (0-100%)
- **Signal**: `EventBus.combat_triggered.emit(scenario_id)`

#### 5. **Treasure Nodes** (salvage, cache, vault)
- **Interaction**: Tap to loot
- **Mechanic**: Random loot table
- **Rewards**: Blueprints, relics, resources
- **Visual**: Sparkle effect, open animation

#### 6. **Wormhole Nodes** (wormhole)
- **Interaction**: Tap to confirm transition
- **Mechanic**: Save game, increment sector, respawn mothership
- **UI**: Confirmation dialog ("Leave Sector 3?")
- **Effect**: Transition to next sector

### Implementation Tasks

#### Task 1: Interaction Manager Setup
```gdscript
# interaction_manager.gd
- Track active interactions
- Route node activations to appropriate handlers
- Manage interaction UI overlays
- Coordinate with SpeedVisionManager for speed checks
```

#### Task 2: Mining System
- Create mining UI (progress bar, resource display)
- Implement long-press detection (touch/mouse)
- Extract resources based on CSV data
- Add to ResourceManager on completion
- Visual feedback (particle effects, node depletion)

#### Task 3: Trading System
- Create shop UI scene
- Load trader inventory from CSV
- Implement buy/sell logic
- Update ResourceManager on transactions
- Pause game during shop

#### Task 4: Combat Triggers
- Implement combat transition flow
- Emit EventBus signals with scenario data
- (Combat module implementation is Phase 3)

#### Task 5: Loot System
- Create loot table system
- Random blueprint/relic drops
- Loot collection UI
- Add to GameState inventory

#### Task 6: Wormhole Transitions
- Confirmation dialog UI
- Save game state
- Increment sector in GameState
- Respawn system (clear nodes, reset distance)
- Update mothership spawn distance

### EventBus Signals (Node Interactions)

```gdscript
# Mining
signal mining_started(node_id: String)
signal mining_progress(node_id: String, progress: float)
signal mining_completed(node_id: String, resources: Dictionary)
signal mining_cancelled(node_id: String)

# Trading
signal trading_opened(node_id: String, trader_data: Dictionary)
signal trading_closed(node_id: String)
signal item_purchased(item_id: String, cost: Dictionary)
signal item_sold(item_id: String, value: Dictionary)

# Combat
signal combat_triggered(node_id: String, scenario_id: String)

# Loot
signal loot_collected(node_id: String, items: Array)

# Wormhole
signal wormhole_entered(current_sector: int, next_sector: int)
signal sector_transition_complete(new_sector: int)
```

### Testing Checklist

- [ ] Mining nodes grant correct resources
- [ ] Speed restriction prevents fast mining
- [ ] Long-press vs tap correctly differentiated
- [ ] Trading UI shows correct prices
- [ ] Purchases/sales update ResourceManager
- [ ] Combat triggers emit correct signals
- [ ] Loot tables generate appropriate rewards
- [ ] Wormhole transitions save game state
- [ ] Sector increments correctly
- [ ] All interactions work on touch devices

---

## 🎁 Phase 2f: Resource Collection System Implementation

### Overview

Implement the **multi-layered resource collection system** that transforms sector navigation into strategic risk-reward gameplay. Resources are collected automatically on proximity pass with dynamic yields based on speed, positioning, streaks, and node quality.

**Design Reference**: `/docs/sector-exploration-module.md` lines 463-952 (Resource Collection System)

**Status**: ⏳ **NOT STARTED** - Design complete, awaiting implementation

### Core Mechanics Summary

**Auto-Collection System:**
- Resources collected automatically when player passes within proximity radius
- No manual tapping required (mobile-optimized)
- Visual feedback: Floating text, trail animation to HUD, audio ping

**Dynamic Multiplier System:**
1. **Speed Multiplier** - 1.0x at speed 1, up to 3.25x at speed 10
2. **Position Multiplier** - 1.0x at center (540px), 1.5x at edges (0px/1080px)
3. **Streak Multiplier** - +10% per streak level (max 5 stacks = +50%)
4. **Quality Tier Multiplier** - 0.5x (poor) to 3.0x (jackpot)

**Final Formula:**
```gdscript
final_resources = base_amount × quality × speed × position × streak
```

---

### Implementation Tasks

#### Task 1: CSV Database Updates

**File**: `/data/sector_nodes.csv`

**Add Columns:**
- `metal_min` / `metal_max` - Metal resource range
- `crystals_min` / `crystals_max` - Crystal resource range
- `fuel_min` / `fuel_max` - Fuel resource range
- `collection_type` - "instant", "mining", "combat", "salvage", "none"
- `mining_fuel_cost` - Fuel cost to deploy miners (0 if not mining)
- `mining_duration` - Seconds to complete mining operation

**Create New File**: `/data/resource_quality_tiers.csv`

```csv
tier_name,spawn_weight,multiplier,aura_color_hex,particle_effect,audio_pitch
poor,15,0.5,#696969,none,0.8
standard,50,1.0,#FFFFFF,none,1.0
rich,25,1.5,#00BFFF,pulse,1.2
abundant,8,2.0,#9370DB,pulse_fast,1.4
jackpot,2,3.0,#FFD700,sparkles,1.6
```

**Success Criteria:**
- [ ] sector_nodes.csv has resource columns populated for all 29+ node types
- [ ] resource_quality_tiers.csv created with 5 tiers
- [ ] DataManager.gd loads both CSV files correctly
- [ ] Query functions: `get_node_resource_data()`, `get_quality_tier_data()`

---

#### Task 2: Quality Tier System

**File**: New `scripts/systems/resource_quality_system.gd` (~80 lines)

**Responsibilities:**
- Roll quality tier when node spawns (weighted random from CSV)
- Return tier data (name, multiplier, color, particle effect, audio pitch)
- Apply quality-based visual effects to nodes

**Functions:**
```gdscript
func roll_quality_tier() -> Dictionary
func get_tier_color(tier_name: String) -> Color
func get_tier_multiplier(tier_name: String) -> float
```

**Success Criteria:**
- [ ] Quality tier rolls on node spawn
- [ ] 2% jackpot, 8% abundant, 25% rich, 50% standard, 15% poor (CSV weights)
- [ ] Tier data cached per node instance
- [ ] EventBus signal: `quality_tier_rolled(node_id, tier_name, multiplier)`

---

#### Task 3: Resource Calculation System

**File**: New `scripts/systems/resource_calculator.gd` (~120 lines)

**Responsibilities:**
- Calculate final resource amounts using master formula
- Track player streak counter
- Calculate speed/position/streak multipliers
- Return final resource dictionary

**Master Formula Implementation:**
```gdscript
func calculate_resource_reward(
    node_data: Dictionary,
    player_speed: float,
    lateral_x: float,
    streak: int,
    quality_multiplier: float
) -> Dictionary:
    # 1. Base amount from CSV
    var base_metal := randf_range(node_data.metal_min, node_data.metal_max)
    var base_crystals := randf_range(node_data.crystals_min, node_data.crystals_max)
    var base_fuel := randf_range(node_data.fuel_min, node_data.fuel_max)

    # 2. Speed multiplier
    var speed_mult := 1.0 + (player_speed - 1.0) * 0.25

    # 3. Position multiplier
    var center := 540.0
    var distance_from_center := abs(lateral_x - center)
    var position_mult := 1.0 + (distance_from_center / 540.0) * 0.5

    # 4. Streak multiplier
    var streak_mult := 1.0 + min(streak, 5) * 0.1

    # 5. Final calculation
    return {
        "metal": int(base_metal * quality_multiplier * speed_mult * position_mult * streak_mult),
        "crystals": int(base_crystals * quality_multiplier * speed_mult * position_mult * streak_mult),
        "fuel": int(base_fuel * quality_multiplier * speed_mult * position_mult * streak_mult)
    }
```

**Success Criteria:**
- [ ] Formula matches design spec exactly
- [ ] Speed multiplier: 1.0x at speed 1, 3.25x at speed 10
- [ ] Position multiplier: 1.0x at center, 1.5x at edges
- [ ] Streak multiplier: 1.0x to 1.5x (caps at 5)
- [ ] All multipliers stack correctly

---

#### Task 4: Collection Streak System

**File**: Add to `scripts/autoloads/GameState.gd` (~40 lines)

**New Variables:**
```gdscript
var collection_streak: int = 0
var streak_active: bool = false
var last_collectable_node_passed: bool = true
```

**Functions:**
```gdscript
func increment_streak() -> void
func break_streak() -> void
func get_streak_multiplier() -> float
func check_streak_risk(node_in_range: bool) -> void
```

**Streak Rules:**
- Increment when collecting any collectable node
- Break when missing a collectable node in proximity range
- Persist between sectors
- Reset on combat or death

**Success Criteria:**
- [ ] Streak increments on collection
- [ ] Streak breaks when missing nodes
- [ ] Streak persists between sectors
- [ ] EventBus signals: `collection_streak_increased()`, `collection_streak_broken()`
- [ ] Streak warning when about to break

---

#### Task 5: Visual Feedback System

**File**: Enhance `scripts/autoloads/IndicatorManager.gd` (~80 lines added)

**New Systems:**

**A) Resource Aura System**
- Glowing circle around node matching quality tier color
- Pulsing animation for rich/abundant/jackpot tiers
- Particle effects (sparkles) for jackpot nodes

**B) Collection Animation**
```gdscript
func play_collection_animation(node_pos: Vector2, resources: Dictionary, quality_tier: Dictionary):
    # 1. Flash node aura white
    # 2. Spawn floating "+X Metal" text
    # 3. Spawn trail particles from node to HUD
    # 4. Animate HUD counter scale/glow
    # 5. Play audio ping (pitch varies by tier)
```

**C) Node Aura Rendering**
```gdscript
func apply_resource_aura(node: Node2D, quality_tier: Dictionary, resources: Dictionary):
    var aura := Sprite2D.new()
    aura.modulate = quality_tier.color
    aura.scale = Vector2(1.0, 1.0) * quality_tier.multiplier

    # Pulsing tween
    var tween := create_tween().set_loops()
    tween.tween_property(aura, "scale", Vector2(1.2, 1.2), 0.5)
    tween.tween_property(aura, "scale", Vector2(1.0, 1.0), 0.5)

    node.add_child(aura)
```

**Success Criteria:**
- [ ] Quality auras visible on all collectable nodes
- [ ] Colors match tier (gray/white/blue/purple/gold)
- [ ] Pulsing animation for rich+ tiers
- [ ] Jackpot nodes have sparkle particles
- [ ] Collection animation plays on proximity pass
- [ ] Floating text shows resource amounts
- [ ] Trail animation from node to HUD
- [ ] Audio pitch varies by tier quality

---

#### Task 6: UI Components

**File**: Update `scenes/sector_exploration/sector_map.tscn` + UI scripts

**New UI Elements:**

**A) Enhanced Resource Display (Top-Center)**
```
┌─────────────────────────────────┐
│  ⚙️150  💎85  ⛽45  │  x3 🔥  │
│  +25↑  +10↑  +5↑   │  1.8x   │
└─────────────────────────────────┘
```

**Components:**
- Resource counters with animated "+X" gains (fade after 1.5s)
- Streak indicator (fire emoji + count, only visible when streak > 0)
- Combined multiplier display (speed × position × streak × quality)

**B) Streak HUD (Bottom-Right)**
```
┌──────────────┐
│  STREAK x5   │
│  ⭐⭐⭐⭐⭐  │
│  +50% Bonus  │
└──────────────┘
```

**Success Criteria:**
- [ ] Resource counters update on collection
- [ ] "+X" floating gains appear and fade
- [ ] Streak HUD only visible when streak > 0
- [ ] Multiplier display shows total multiplier
- [ ] All text large enough for mobile (48-72px)
- [ ] PNG icons for resources

---

#### Task 7: Auto-Collection System

**File**: Add to `scenes/sector_exploration/sector_map.gd` (~60 lines)

**Implementation:**
- Monitor proximity detection for all collectable nodes
- When player passes within proximity radius, trigger collection
- Calculate resources using ResourceCalculator
- Add resources to ResourceManager
- Play collection animation
- Update streak counter

**Proximity Collection Logic:**
```gdscript
func _on_node_proximity_entered(node_id: String, node_type: String) -> void:
    var node_data := DataManager.get_node_config(node_type)

    # Check if node is collectable
    if node_data.collection_type in ["instant", "mining"]:
        # Calculate resources
        var quality_tier := node.quality_tier_data
        var resources := ResourceCalculator.calculate_resource_reward(
            node_data,
            current_speed_multiplier,
            player_lateral_position,
            GameState.collection_streak,
            quality_tier.multiplier
        )

        # Collect resources
        ResourceManager.add_metal(resources.metal, "node_collection")
        ResourceManager.add_crystals(resources.crystals, "node_collection")
        ResourceManager.add_fuel(resources.fuel, "node_collection")

        # Update streak
        GameState.increment_streak()

        # Play animation
        IndicatorManager.play_collection_animation(node.position, resources, quality_tier)

        # Emit signal
        EventBus.resource_node_collected.emit(node_id, resources, {
            "speed": speed_multiplier,
            "position": position_multiplier,
            "streak": streak_multiplier,
            "quality": quality_tier.multiplier
        })
```

**Success Criteria:**
- [ ] Collection triggers on proximity pass (no manual tapping)
- [ ] Resources calculated correctly with all multipliers
- [ ] ResourceManager updated immediately
- [ ] Streak increments on collection
- [ ] Collection animation plays
- [ ] EventBus signal emitted with multiplier data

---

#### Task 8: Mining Speed Restrictions

**File**: Integration with existing mining system

**Restrictions:**
- Speed 1-2: Can mine all nodes
- Speed 3-4: Can only mine planets (not asteroids/clusters)
- Speed 5+: Cannot mine (instant collection only)

**Implementation:**
```gdscript
func can_mine_node(node_type: String, current_speed: float) -> bool:
    var node_data := DataManager.get_node_config(node_type)

    if node_data.collection_type != "mining":
        return false

    # Check speed restrictions
    if current_speed >= 5.0:
        return false  # Too fast for any mining

    if current_speed >= 3.0:
        # Can only mine planets at medium speed
        return node_type in ["star", "gas_giant", "rocky_planet", "ice_planet", "moon"]

    return true  # Can mine everything at low speed
```

**Success Criteria:**
- [ ] Mining disabled at speed 5+
- [ ] Asteroid/cluster mining disabled at speed 3-4
- [ ] Planet mining allowed at speed 3-4
- [ ] All mining allowed at speed 1-2
- [ ] UI shows restriction message when too fast
- [ ] EventBus signal: `mining_speed_restriction_active()`

---

#### Task 9: Integration with Existing Systems

**A) Jump Mechanic Integration**

**Landing Bonus:**
- Landing near high-value nodes gives 1.2x collection bonus for 3 seconds
- Highlight resource-rich nodes in jump range during charge
- Show estimated resource gain preview

**B) Gravity Assist Integration**

**Speed Preview:**
- Show how speed change affects resource collection multipliers
- Display warning when speeding up will disable mining
- Show benefit of slowing down for mining access

**C) Mothership Pursuit Pressure**

**Quality Tier Shift:**
```gdscript
func get_quality_spawn_weights(mothership_distance: float) -> Dictionary:
    var base_weights := {
        "poor": 15,
        "standard": 50,
        "rich": 25,
        "abundant": 8,
        "jackpot": 2
    }

    # Increase rare spawns as mothership gets closer
    if mothership_distance < 500:
        base_weights.jackpot = 10  # 5x normal
        base_weights.abundant = 20  # 2.5x normal
    elif mothership_distance < 1000:
        base_weights.jackpot = 6
        base_weights.abundant = 16
    elif mothership_distance < 2000:
        base_weights.jackpot = 4
        base_weights.abundant = 12

    return base_weights
```

**D) Alien Sweep Integration**

**Dodge Bonus:**
- Narrow dodge (< 50px) gives 1.3x multiplier on next collection
- 5 consecutive dodges + collections = 2.0x multiplier for 10 seconds
- Visual feedback: Golden glow around ship after dodge

**Success Criteria:**
- [ ] Jump landing bonus works
- [ ] Jump charge shows resource preview
- [ ] Gravity assist shows speed impact on resources
- [ ] Mothership distance affects quality spawn rates
- [ ] Alien dodge bonus applies correctly
- [ ] All integrations have visual feedback

---

#### Task 10: Balancing & Tuning

**File**: CSV updates based on playtesting

**Resource Income Targets (Per Sector):**

| Strategy | Speed | Position | Streak | Metal | Crystals | Fuel |
|----------|-------|----------|--------|-------|----------|------|
| Safe Farmer | 1-2 | Center | 0-2 | 200-400 | 100-200 | 150-250 |
| Edge Runner | 5-6 | Edges | 3-5 | 600-1000 | 400-700 | 300-500 |
| Greed Specialist | 9-10 | Edges | 5 | 1500-2500 | 1000-1800 | 600-900 |

**Tuning Knobs (CSV):**
- Node base resource values (metal_min/max, etc.)
- Quality tier spawn weights
- Speed multiplier coefficient (currently 0.25)
- Position multiplier max (currently 0.5 = 1.5x at edges)
- Streak cap and bonus (currently 5 max, 10% per level)
- Mining fuel costs and durations

**Analytics Tracking:**
```gdscript
signal resource_collection_analytics(
    sector: int,
    total_collected: Dictionary,
    avg_multiplier: float,
    streak_max: int,
    speed_avg: float
)
```

**Success Criteria:**
- [ ] Safe play yields 200-400 metal per sector
- [ ] Risky play yields 600-1000 metal per sector
- [ ] Expert play yields 1500-2500 metal per sector
- [ ] Fuel economy balanced (net positive at all speeds)
- [ ] Quality tier distribution feels rewarding
- [ ] Streak system encourages skillful play
- [ ] Analytics data collected for balancing

---

### EventBus Signals (Resource Collection)

**Add to EventBus.gd:**

```gdscript
# ============================================================
# RESOURCE COLLECTION SIGNALS
# ============================================================

# Basic collection events
signal resource_node_collected(node_id: String, resources: Dictionary, multipliers: Dictionary)
signal mining_operation_started(node_id: String, fuel_cost: int, duration: float)
signal mining_operation_completed(node_id: String, resources: Dictionary)
signal mining_operation_failed(node_id: String, reason: String)

# Quality tier events
signal quality_tier_rolled(node_id: String, tier_name: String, multiplier: float)
signal jackpot_node_spawned(node_id: String, position: Vector2)

# Streak system events
signal collection_streak_started()
signal collection_streak_increased(streak_count: int, bonus_multiplier: float)
signal collection_streak_broken(final_streak: int)
signal collection_streak_warning(node_id: String)

# Multiplier events
signal collection_multiplier_calculated(speed_mult: float, position_mult: float, streak_mult: float, quality_mult: float, total_mult: float)
signal high_value_collection(total_value: int, multiplier: float)

# Speed-based collection restrictions
signal instant_collection_available(node_id: String)
signal mining_speed_restriction_active(node_id: String, max_speed: int, current_speed: int)

# Analytics
signal resource_collection_analytics(sector: int, total_collected: Dictionary, avg_multiplier: float, streak_max: int, speed_avg: float)
```

---

### File Size Compliance

All new files must stay under 300 lines:

| File | Target Lines | Purpose |
|------|--------------|---------|
| resource_quality_system.gd | ~80 | Quality tier rolling |
| resource_calculator.gd | ~120 | Multiplier calculations |
| GameState.gd additions | +40 | Streak tracking |
| IndicatorManager.gd additions | +80 | Visual feedback |
| sector_map.gd additions | +60 | Auto-collection logic |

**Total Addition**: ~380 lines across 5 files

---

### Testing Checklist

**Quality Tier System:**
- [ ] Tiers roll with correct spawn weights (2% jackpot, 50% standard, etc.)
- [ ] Aura colors match tier (gray/white/blue/purple/gold)
- [ ] Pulsing animation works for rich/abundant/jackpot
- [ ] Jackpot nodes have sparkle particles
- [ ] Audio pitch varies by tier

**Resource Calculation:**
- [ ] Speed multiplier: 1.0x at speed 1, 3.25x at speed 10
- [ ] Position multiplier: 1.0x at center, 1.5x at edges
- [ ] Streak multiplier: +10% per level (max 5 = +50%)
- [ ] Quality multiplier: 0.5x to 3.0x
- [ ] All multipliers stack correctly
- [ ] Formula matches design spec exactly

**Streak System:**
- [ ] Streak increments on collection
- [ ] Streak breaks when missing collectable nodes
- [ ] Streak persists between sectors
- [ ] Streak resets on combat/death
- [ ] Streak warning appears when about to break
- [ ] Streak HUD shows correct count and bonus

**Auto-Collection:**
- [ ] Resources collected on proximity pass (no tapping)
- [ ] Collection triggers at correct distance
- [ ] ResourceManager updates immediately
- [ ] Collection animation plays
- [ ] Floating text shows correct amounts
- [ ] Trail animation flies to HUD
- [ ] Audio ping plays with correct pitch

**Mining Restrictions:**
- [ ] Mining disabled at speed 5+
- [ ] Asteroid/cluster mining disabled at speed 3-4
- [ ] Planet mining allowed at speed 3-4
- [ ] All mining allowed at speed 1-2
- [ ] UI shows restriction warnings

**Visual Feedback:**
- [ ] Resource auras visible on all nodes
- [ ] Quality colors correct
- [ ] Collection animation smooth
- [ ] HUD updates responsive
- [ ] Streak HUD only visible when active
- [ ] Multiplier display shows total

**Integration:**
- [ ] Jump landing bonus works
- [ ] Jump charge shows resource preview
- [ ] Gravity assist shows resource impact
- [ ] Mothership distance affects quality spawns
- [ ] Alien dodge bonus applies
- [ ] All integrations have visual feedback

**Balancing:**
- [ ] Safe play yields 200-400 metal/sector
- [ ] Risky play yields 600-1000 metal/sector
- [ ] Expert play yields 1500-2500 metal/sector
- [ ] Fuel economy net positive
- [ ] Quality distribution feels rewarding
- [ ] Streak system encourages skill

---

### Implementation Order

**Week 1: Foundation**
1. CSV updates (sector_nodes.csv + resource_quality_tiers.csv)
2. Quality tier system (rolling, data access)
3. Resource calculator (master formula)
4. Streak tracking (GameState additions)

**Week 2: Visuals**
5. Resource aura system (IndicatorManager)
6. Collection animation (floating text, trails, audio)
7. UI components (enhanced resource display, streak HUD)
8. Visual feedback polish

**Week 3: Integration**
9. Auto-collection logic (proximity triggers)
10. Mining speed restrictions
11. Jump/gravity/mothership/sweep integrations
12. EventBus signal wiring

**Week 4: Balance & Polish**
13. Playtesting with analytics
14. CSV tuning (resource values, quality weights)
15. Bug fixes and edge cases
16. Final polish and optimization

---

### Completion Criteria

Phase 2f is complete when:

- [ ] All CSV databases updated with resource columns
- [ ] Quality tier system rolls and applies correctly
- [ ] Resource calculation formula matches design spec
- [ ] Streak system tracks and persists correctly
- [ ] Visual feedback complete (auras, animations, UI)
- [ ] Auto-collection triggers on proximity pass
- [ ] Mining speed restrictions enforced
- [ ] All system integrations working (jump, gravity, mothership, sweeps)
- [ ] Resource income meets balance targets
- [ ] All EventBus signals implemented
- [ ] All scripts under 300 lines
- [ ] No console errors
- [ ] Mobile UI responsive and clear
- [ ] Analytics data collected for tuning

**Next Phase**: Phase 3 - Combat System (15×25 grid autobattler)

**Estimated Effort**: 15-20 hours for resource collection system implementation

**Reference**: `/docs/sector-exploration-module.md` lines 463-952 (Complete resource system spec)

---

## 🎯 Next Immediate Priorities

### Priority 1: Interaction Manager Foundation (Current)
- Create interaction_manager.gd coordinator
- Set up EventBus signals for node interactions
- Implement basic tap/long-press detection system
- Create interaction UI overlay system

### Priority 2: Mining System Implementation
- Mining node long-press interaction
- Resource extraction mechanics
- Speed restriction integration (SpeedVisionManager)
- Visual feedback and progress display

### Priority 3: Simple Node Types
- Outpost instant rewards
- Treasure loot collection
- Visual feedback systems

### Priority 4: Complex Systems
- Trading shop interface
- Combat trigger transitions
- Wormhole sector progression

---

**For complete design specifications, formulas, and detailed mechanics, always reference `/docs/sector-exploration-module.md`**
