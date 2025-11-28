# Sector Exploration Module - Complete Reference

## Overview

The **Sector Exploration Module** is the primary gameplay mode of Any-Type-7. Players pilot their Colony Ship through an infinitely scrolling space sector, navigating through procedurally generated nodes while maintaining forward momentum. The ship constantly moves forward, and players must swipe to veer left or right, balancing speed and maneuverability to reach nodes, avoid alien sweep patterns, and find a wormhole before the pursuing mothership catches them.

**Core Concept**: An infinite runner-style momentum system with procedural node generation, proximity-based encounters, swipe navigation, alien avoidance mechanics, and a pursuing mothership threat.

---

## Victory & Failure Conditions

### Victory
- Find and reach a **Wormhole** before the alien mothership catches your Colony Ship
- Successfully escape to the next sector (increasing difficulty)

### Failure
- The Alien Mothership catches your Colony Ship and destroys it
- Collision with alien sweep patterns that you cannot handle in combat

### Progression
- Each sector completed increases difficulty
- Mothership spawns closer behind the player and accelerates faster (catches up progressively sooner)
- Enemy strength scales per sector
- Alien sweep patterns become more complex and frequent

---

## Map Structure & Dimensions

### Technical Specifications
- **Map Width**: 1080 pixels (matches portrait screen width)
- **Map Height**: Infinite (procedurally generated as player moves forward)
- **Orientation**: Portrait/Vertical (mobile-optimized)
- **Scrolling**: Automatic forward movement, player controls lateral position
- **Camera**: Follows player ship, shows upcoming nodes

### Background Visuals
Three randomly selected backgrounds per sector (tiled infinitely):
- `assets/Backgrounds/starfield_background.png`
- `assets/Backgrounds/red_starfield_background.png`
- `assets/Backgrounds/light_stream_background.png`

### Node Generation
- **Procedural Generation**: Nodes spawn ahead of player as they move forward
- **Node Density**: Approximately 1 node per 200-400 pixels of vertical distance
- **Wormholes**: Spawn periodically (roughly every 3000-5000 pixels traveled)
- **Spacing**: Minimum 150px between nodes to prevent overlap

---

## The 8 Node Types

### 1. Mining Nodes
**Description**: Uninhabited planets or asteroid fields rich in resources

**Spawn Weight**: 30 (most common)

**Purpose**: Deploy miners to gather resources over time

**Resource Types**:
- **Metal**: Basic construction material
- **Crystals**: Advanced technology component
- **Fuel**: Movement and jumping
- **Wildcard**: Tier 1 item, or rarely tier 2 item

**Mechanics**:
- Instant reward for Phase 2 prototype (30-100 resources)
- Future: Deploy miners, wait for extraction, return to collect
- No combat encounters

**Implementation Status**: ✅ Core functionality ready (scripts/nodes/mining_node.gd)

---

### 2. Outpost Nodes
**Description**: Abandoned resource caches or derelict stations

**Spawn Weight**: 25 (very common)

**Purpose**: Instant resource bonuses, sometimes with enemy encounters

**Reward Structure**:
- **No Enemies (70% chance)**: 20-50 metal, 10-30 crystals
- **With Enemies (30% chance)**: 50-150 metal, 20-60 crystals (better rewards)

**Mechanics**:
- Tap to activate
- If enemies present, triggers combat encounter (Phase 3)
- If clear, instant resource grant
- One-time use per outpost

**Implementation Status**: ✅ Core functionality ready (scripts/nodes/outpost_node.gd)

---

### 3. Asteroids
**Description**: Mineable space rocks drifting through sector

**Spawn Weight**: 20 (common)

**Purpose**: Quick metal and crystal gathering

**Rewards**: 10-50 metal/crystals (smaller amounts than mining nodes), tier 1 item small chance

**Mechanics**:
- Instant collection (no mining time)
- No combat encounters
- Quick resource top-up option

**Implementation Status**: ⚠️ Placeholder (needs asteroid_node.gd)

---

### 4. Ship Graveyards
**Description**: Derelict fleets from previous battles

**Spawn Weight**: 10 (uncommon)

**Purpose**: Salvage materials, ship parts, and rare components

**Rewards**: 50-200 metal, potential blueprint unlocks

**Mechanics**:
- Salvage operation takes time
- 20% chance of enemy encounter (scavengers or automated defenses)
- Can find ship blueprints or rare upgrades
- Potential for unique equipment

**Implementation Status**: ⚠️ Placeholder (needs graveyard_node.gd)

---

### 5. Trader Ships
**Description**: Merchant vessels offering goods and services

**Spawn Weight**: 8 (uncommon)

**Purpose**: Purchase upgrades, blueprints, and equipment

**Shop Inventory**:
- an assortment of Tier 1 and Tier 2 items
- Bluepritns
- Fleet upgrades

**Costs**: Metal and Crystals (Fuel not sold)

**Mechanics**:
- Opens shop UI (Phase 4)
- Inventory randomized per trader
- Prices scale with sector difficulty
- No combat

**Implementation Status**: ⚠️ Placeholder (needs trader_node.gd + shop UI)

---

### 6. Alien Colonies
**Description**: Hostile alien installations with valuable resources

**Spawn Weight**: 5 (rare)

**Purpose**: High-risk encounters with great rewards

**Encounter Behavior**:
- **Proximity Detection**: Popup appears when ship passes within range
- **Combat Option**: Player can choose to engage or avoid
- **Rewards**: Large resource caches (200+ metal, 100+ crystals), rare blueprints, unique equipment

**Mechanics**:
- Can be avoided by steering around them
- Engaging triggers combat encounter
- One-time interaction per colony
- No enemy spawning (that mechanic removed)

**Implementation Status**: ⚠️ Placeholder (needs colony_node.gd + encounter system)

---

### 7. Artifact Vaults
**Description**: Ancient alien installations containing powerful technology

**Spawn Weight**: 2 (very rare)

**Purpose**: Obtain powerful unique upgrades (legendary tier)

**Rewards**:
- Unique upgrades (one-of-a-kind effects)
- Legendary equipment
- Permanent ship modifications

**Mechanics**:
- 40% chance of combat encounter (guardians)
- Puzzle or skill challenge (future feature)
- One-time unlock per vault
- Rewards not available elsewhere

**Implementation Status**: ⚠️ Placeholder (needs vault_node.gd + encounter system)

---

### 8. Wormholes (Exit Nodes)
**Description**: Portals to the next sector

**Spawn Weight**: Medium frequency (appears every 3000-5000 pixels of travel)

**Purpose**: Sector completion and progression

**Discovery**:
- Visible when within camera view
- Spawns procedurally as player moves forward
- Position varies horizontally across map width

**Activation**:
- Triggers when ship passes within proximity range
- Saves game state
- Increments sector number
- Spawns mothership closer in next sector

**Mechanics**:
- Time pauses when proximity popup appears
- Confirmation prompt before leaving
- Point of no return
- Multiple wormholes may exist, player only needs to reach one

**Implementation Status**: ⚠️ Placeholder (needs wormhole_node.gd + transition logic)

---

## Node Visibility System

### Core Mechanics
- **Camera View**: Nodes visible when within camera viewport
- **Procedural Spawning**: Nodes generate ahead of player as they move forward
- **Despawning**: Nodes behind player (outside camera view) are removed from memory
- **No Fog of War**: All nodes within camera range are immediately visible

### Visibility Rules
- Nodes spawn 2000-3000 pixels ahead of player position
- Nodes within camera viewport are fully visible
- Nodes more than 500 pixels behind player are despawned
- Activated nodes are marked visually but remain visible until despawned

### Visual Representation
- **Visible nodes**: Fully visible with icon and label
- **Activated nodes**: Dimmed or marked as completed (visual indicator)
- **Upcoming nodes**: Fade in as they enter camera view

### Implementation
- Tracked by `SectorManager.active_nodes` array (nodes currently in world)
- EventBus signal: `node_spawned(node_id, node_type)` on generation
- EventBus signal: `node_despawned(node_id)` when removed
- Scene visibility based on camera bounds

---

## Movement & Speed Mechanics

### Core Movement System

#### Automatic Forward Movement
**Cost**: 0 fuel (automatic)

**Behavior**:
- Player ship constantly moves forward at current speed
- Base speed starts at a comfortable pace (configurable, e.g., 100 pixels/second)
- Speed controlled exclusively through gravity assists
- No manual acceleration/deceleration

**Mechanic**: Ship is always in motion, player cannot stop

---

#### Lateral Navigation (Swipe Controls)
**Cost**: 0 fuel (free)

**Behavior**:
- Swipe left or right to make ship veer in that direction
- Acceleration lag: Higher speed = slower lateral response
- Ship gradually moves toward swiped direction
- Release swipe to stop lateral movement (ship centers itself)

**Maneuverability Formula**: `Lateral_Acceleration = Base_Accel / (1 + Speed_Multiplier * 0.5)`

**Use Case**: Navigate to nodes, avoid alien sweeps, position for encounters

---

#### Jump (Horizontal Dash)
**Cost**: 10 fuel + Cooldown timer

**Behavior**:
- Quick horizontal movement in left or right direction
- Does NOT affect forward speed (no longer slows down)
- Distance: Approximately 200-300 pixels horizontally
- Cooldown: 10-15 seconds after use
- Visual: Quick dash/blink animation

**Use Case**:
- Emergency dodge for alien sweeps
- Quickly reach nodes that would otherwise be missed
- Escape dangerous situations

**Validation**: `ResourceManager.spend_resources({"fuel": 10}, "jump")` AND cooldown check

---

#### Gravity Assist
**Cost**: 1 fuel per use

**Behavior**:
- Can **increase** speed: +20% forward speed (1.0× → 1.2× → 1.4×...)
- Can **decrease** speed: -20% forward speed (useful for deploying miners or collecting rewards)
- Player chooses direction (speed up or slow down) when activating
- Speed persists until next gravity assist adjustment
- Available near gravitationally significant objects (planets, asteroids, etc.)

**Use Cases**:
- **Speed Up**: Outrun mothership, cover distance quickly
- **Slow Down**: Deploy miners, carefully navigate complex node clusters, collect rewards

**Strategic Consideration**: Faster = harder to maneuver, slower = easier to catch nodes but mothership catches up

---

## Player Starting Conditions

### Initial Position
- **Coordinates**: `Vector2(540, 1170)` - Center of screen width, bottom third of viewport
- **Forward Speed**: 100 pixels/second (base speed, 1.0× multiplier)
- **Lateral Position**: Centered (x = 540)
- **Starting Fleet**: Ships defined by `GameState.owned_ships`

### Starting Resources
(Defined in `ResourceManager.gd`)
- **Metal**: 100
- **Crystals**: 50
- **Fuel**: 100

### Starter Ships
(Defined in `GameState.gd`)
- `basic_fighter`
- `basic_interceptor`

### Mothership Spawn
- **Initial Distance**: 5000-8000 pixels behind player (configurable per sector)
- **Initial Speed**: 80% of player base speed (gradually accelerates)
- **Spawn Delay**: Spawns immediately when sector starts (sector 1+)

---

## Alien Mothership Chase Mechanic

### Core Concept
The alien mothership spawns behind the player and pursues them through the sector, gradually accelerating to catch up. This creates escalating pressure and encourages finding wormholes before being overtaken.

### Spawn & Pursuit Formula
```gdscript
# Mothership spawns behind player
mothership_spawn_distance = max(8000.0 - (sector_number * 500.0), 3000.0)

# Mothership accelerates over time
mothership_speed = player_base_speed * 0.8 + (time_elapsed * acceleration_rate)
acceleration_rate = 0.5 + (sector_number * 0.1)  # Faster acceleration each sector
```

**Base Spawn Distance**: 8000 pixels behind player (sector 1)
**Reduction**: -500 pixels per sector
**Minimum Distance**: 3000 pixels (sector 11+)

### Progression
| Sector | Spawn Distance | Initial Speed | Accel Rate |
|--------|----------------|---------------|------------|
| 1 | 8000px | 80px/s | 0.6 px/s² |
| 3 | 7000px | 80px/s | 0.8 px/s² |
| 5 | 6000px | 80px/s | 1.0 px/s² |
| 10 | 3500px | 80px/s | 1.5 px/s² |
| 11+ | 3000px | 80px/s | 1.6+ px/s² |

### Visual Indicators
- **Distance Display**: Shows distance in pixels or as percentage (e.g., "Mothership: 4500px" or "75% behind")
- **Warning State**: Display turns red when mothership is within 2000 pixels
- **Visual**: Mothership visible in background when close enough (within 1500 pixels)
- **UI Position**: Top of screen overlay (always visible)

### When Mothership Catches Player
- **Instant Failure**: If mothership reaches player position
- **Game Over**: Run ends, player returns to hangar
- **No Combat Option**: Mothership cannot be fought (removed from design)

### Implementation
```gdscript
# In SectorManager.gd
var mothership_position: float = -8000.0  # Negative = behind player
var mothership_speed: float = 80.0
var mothership_acceleration: float = 0.6

func _process(delta: float) -> void:
    # Update mothership position
    mothership_speed += mothership_acceleration * delta
    mothership_position += mothership_speed * delta

    # Check if caught
    if mothership_position >= player_forward_position:
        _mothership_caught_player()

func get_mothership_distance() -> float:
    return player_forward_position - mothership_position

func is_mothership_close() -> bool:
    return get_mothership_distance() <= 2000.0
```

---

## Alien Sweep System

### Core Concept
Instead of patrolling enemies, aliens periodically **sweep across the map** in various patterns that the player must avoid or fight through.

### Sweep Patterns

#### 1. Horizontal Sweep
- **Pattern**: Aliens move horizontally across screen from left or right
- **Speed**: Moderate (slightly faster than player base speed)
- **Width**: 200-400 pixels tall
- **Frequency**: Every 60-90 seconds

#### 2. Diagonal Sweep
- **Pattern**: Aliens move diagonally across screen
- **Speed**: Fast (1.5× player base speed)
- **Width**: 300-500 pixels diagonal band
- **Frequency**: Every 90-120 seconds

#### 3. Pincer Sweep
- **Pattern**: Aliens sweep from both left AND right simultaneously
- **Speed**: Moderate
- **Gap**: 200-300 pixels safe zone in center
- **Frequency**: Every 120-180 seconds (rare, difficult)

#### 4. Wave Sweep
- **Pattern**: Multiple small groups in wave formation
- **Speed**: Slow to moderate
- **Gaps**: 150-200 pixels between groups (navigable)
- **Frequency**: Every 90-120 seconds

### Sweep Mechanics
- **Collision Detection**: If player ship overlaps alien sweep hitbox
- **Combat Trigger**: Collision triggers combat encounter
- **Avoidance**: Player can steer around sweeps using lateral movement or jump
- **Warning**: Visual indicator appears 3-5 seconds before sweep enters screen
- **Scaling**: Frequency and complexity increase with sector number

### Visual Design
- **Warning Zone**: Red/yellow overlay showing sweep path before arrival
- **Aliens**: Visual representation of alien ships/entities in formation
- **Audio Cue**: Sound effect when sweep approaches

### Combat Triggers
- **Alien Sweep Contact**: Collision with sweep pattern
- **Outpost with enemies**: 30% chance
- **Graveyard scavengers**: 20% chance
- **Colony assault**: Player choice
- **Vault guardians**: 40% chance

---

## Touch Controls & Input

### Lateral Steering (Primary Control)
- **Gesture**: Swipe left or right anywhere on screen
- **Behavior**: Ship veers in swiped direction with acceleration lag
- **Visual Feedback**: Ship rotates slightly toward movement direction
- **Release**: Ship gradually returns to centered lateral position
- **Speed Impact**: Faster speed = slower lateral response (harder to maneuver)

### Proximity Node Popup
- **Trigger**: Ship passes within interaction radius of node (150-200 pixels)
- **Behavior**: **Time pauses completely** when popup appears
- **Options Display**: Shows node-specific options (e.g., "Mine Resources", "Engage", "Ignore")
- **Selection**: Tap option to activate, or tap "Continue" to dismiss
- **Resume**: Time resumes when popup is dismissed

### Jump Button (Emergency Dash)
- **Location**: UI overlay (bottom-right)
- **Activation**: Tap button, then swipe left or right to choose direction
- **Validation**: Grays out if fuel < 10 OR on cooldown
- **Visual**: Shows cooldown timer (e.g., "Jump: 8s")
- **Cost Display**: "10 Fuel" label

### Gravity Assist Button
- **Location**: UI overlay (bottom-left)
- **Activation**: Tap button to open speed adjustment menu
- **Options**: "Speed Up (+20%)" or "Slow Down (-20%)"
- **Requirement**: Must be near gravitationally significant body (visual indicator)
- **Feedback**: Shows current speed multiplier (e.g., "Speed: 1.4×")
- **Cost Display**: "1 Fuel" label

---

## UI Overlay Elements

### Resource Display (Top-Left)
```
Metal: 100
Crystals: 50
Fuel: 100
```

### Mothership Distance (Top-Center)
```
Mothership: 4500px
```
(Turns red when ≤2000 pixels)

### Speed Display (Top-Right)
```
Speed: 1.4×
```
Shows current speed multiplier

### Action Buttons
- **Jump Button** (Bottom-Right): "Jump (10 Fuel) [Cooldown: 8s]"
- **Gravity Assist Button** (Bottom-Left): "Speed Adjust (1 Fuel)"

### Proximity Node Popup (Center, automatic)
```
[Node Type Icon]
Node Type Name
---
[Action 1] [Action 2] [Continue]
```
(Time pauses while popup is visible)

---

## EventBus Signals (Sector Exploration)

### Sector Lifecycle
```gdscript
signal sector_entered(sector_number: int)
signal sector_exited()
signal wormhole_reached()
```

### Node Generation & Interaction
```gdscript
signal node_spawned(node_id: String, node_type: String, position: Vector2)
signal node_despawned(node_id: String)
signal node_proximity_entered(node_id: String, node_type: String)
signal node_activated(node_id: String)
```

### Movement & Speed
```gdscript
signal player_position_updated(forward_distance: float, lateral_position: float)
signal speed_changed(new_multiplier: float)
signal jump_executed(direction: String, fuel_cost: int)  # "left" or "right"
signal jump_cooldown_started(cooldown_duration: float)
signal gravity_assist_activated(speed_change: String, new_multiplier: float)  # "increase" or "decrease"
```

### Mothership
```gdscript
signal mothership_distance_updated(distance: float)
signal mothership_warning(distance: float)  # At 3000px, 2000px, 1000px
signal mothership_caught_player()
```

### Alien Sweeps
```gdscript
signal alien_sweep_approaching(sweep_type: String, arrival_time: float)
signal alien_sweep_entered(sweep_id: String)
signal alien_sweep_collision(sweep_id: String)
```

---

## SectorManager Singleton

### Autoload Configuration
- **Path**: `res://scripts/autoloads/SectorManager.gd`
- **Autoload Name**: `SectorManager`
- **Dependencies**: EventBus, ResourceManager, GameState

### Core Responsibilities
1. **Sector State Management**: Track current sector, difficulty, forward distance traveled
2. **Procedural Node Generation**: Spawn nodes ahead of player, despawn nodes behind
3. **Player Movement**: Track forward distance and lateral position, handle speed changes
4. **Mothership Pursuit**: Track mothership position, speed, and acceleration
5. **Alien Sweep System**: Generate and manage sweep patterns
6. **Jump Cooldown**: Track jump ability cooldown timer
7. **Background Selection**: Randomly choose sector background and tile infinitely

### Key Functions

#### Sector Control
```gdscript
func start_sector(sector_number: int) -> void
func exit_sector() -> void
func get_forward_distance_traveled() -> float
```

#### Node Management (Procedural)
```gdscript
func spawn_nodes_ahead(forward_position: float) -> void
func despawn_nodes_behind(forward_position: float) -> void
func get_node_data(node_id: String) -> Dictionary
func get_active_nodes() -> Array[Dictionary]
func activate_node(node_id: String) -> void
func check_node_proximity(player_position: Vector2) -> String  # Returns node_id or ""
```

#### Player Movement & Speed
```gdscript
func update_player_forward_movement(delta: float) -> void
func set_lateral_position(x_position: float) -> void
func execute_jump(direction: String) -> bool  # "left" or "right"
func apply_gravity_assist(speed_change: String) -> bool  # "increase" or "decrease"
func get_current_speed() -> float
func is_jump_ready() -> bool
```

#### Mothership Tracking
```gdscript
func update_mothership_position(delta: float) -> void
func get_mothership_distance() -> float
func is_mothership_close() -> bool
func check_mothership_caught() -> bool
```

#### Alien Sweep System
```gdscript
func spawn_alien_sweep(sweep_type: String) -> void
func update_active_sweeps(delta: float) -> void
func check_sweep_collision(player_position: Vector2) -> bool
```

### Data Structures

#### Node Dictionary Format
```gdscript
{
    "node_id": "node_42",
    "node_type": "mining",  # or "outpost", "asteroid", etc.
    "position": Vector2(640, 8500),  # x = lateral, y = forward distance
    "spawn_distance": 8500.0,  # Forward distance when spawned
    "is_activated": false
}
```

#### Alien Sweep Dictionary Format
```gdscript
{
    "sweep_id": "sweep_12",
    "sweep_type": "horizontal",  # or "diagonal", "pincer", "wave"
    "position": Vector2(0, 10000),
    "speed": 120.0,
    "direction": "right"  # or "left", "diagonal_left", etc.
}
```

### Implementation Status
⚠️ **NEEDS MAJOR REWRITE** - Existing SectorManager.gd uses old fixed-map design, requires complete overhaul for infinite scrolling

---

## Scene Structure

### Main Scene: sector_map.tscn
```
Control (sector_map.gd) [1080x2340]
├── Camera2D (MapCamera)
│   └── [Handles touch-drag scrolling]
├── Node2D (MapContainer)
│   ├── Sprite2D (Background)
│   │   └── Texture: Randomly selected from 3 backgrounds
│   ├── Node2D (NodesLayer)
│   │   └── [Dynamically spawned node instances]
│   └── Sprite2D (PlayerShip)
│       └── Texture: res://assets/ships/havoc_fighter.png
└── CanvasLayer (UIOverlay)
    └── MarginContainer
        └── VBoxContainer
            ├── HBoxContainer (ResourceDisplay)
            │   ├── Label (Metal)
            │   ├── Label (Crystals)
            │   └── Label (Fuel)
            ├── Label (MothershipTimer)
            └── HBoxContainer (ActionButtons)
                ├── Button (Jump)
                └── Button (GravityAssist)
```

### Base Node Component: base_node.tscn
```
Area2D (base_node.gd)
├── CollisionShape2D (TouchArea)
│   └── Shape: CircleShape2D or RectangleShape2D
├── Sprite2D (NodeIcon)
│   └── Texture: Node-type-specific icon
└── Label (NodeLabel)
    └── Text: Node type name
```

### Node Inheritance Hierarchy
```
BaseNode (base_node.gd)
├── MiningNode (mining_node.gd)
├── OutpostNode (outpost_node.gd)
├── AsteroidNode (asteroid_node.gd)
├── GraveyardNode (graveyard_node.gd)
├── TraderNode (trader_node.gd)
├── ColonyNode (colony_node.gd)
├── VaultNode (vault_node.gd)
└── ExitNode (exit_node.gd)
```

---

## File Size Compliance

### Target: All files under 300 lines

| File | Estimated Lines | Status |
|------|-----------------|--------|
| SectorManager.gd | ~280 | ⚠️ Close to limit |
| sector_map.gd | ~250 | ✅ Safe |
| base_node.gd | ~100 | ✅ Safe |
| mining_node.gd | ~80 | ✅ Safe |
| outpost_node.gd | ~90 | ✅ Safe |
| asteroid_node.gd | ~70 | ✅ Safe |
| graveyard_node.gd | ~80 | ✅ Safe |
| trader_node.gd | ~100 | ✅ Safe |
| colony_node.gd | ~120 | ✅ Safe |
| vault_node.gd | ~90 | ✅ Safe |
| exit_node.gd | ~60 | ✅ Safe |

**Total**: ~1,220 lines across 11 files (average 111 lines/file)

---

## CSV-Driven Node Data (Future Enhancement)

### Proposed: sector_nodes.csv

```csv
node_type,base_spawn_weight,reveal_radius,min_resources,max_resources,combat_chance,description
mining,30,0,30,100,0.0,"Resource extraction sites"
outpost,25,0,20,150,0.3,"Abandoned stations with loot"
asteroid,20,0,10,50,0.0,"Quick mineral collection"
graveyard,10,0,50,200,0.2,"Salvage derelict ships"
trader,8,0,0,0,0.0,"Purchase upgrades and equipment"
colony,5,200,0,0,1.0,"Enemy spawners (dangerous)"
vault,2,0,0,0,0.4,"Ancient alien technology"
exit,1,0,0,0,0.0,"Portal to next sector"
```

### Benefits
- Balance spawn weights without code changes
- Tune resource yields per node type
- Adjust combat probabilities
- Easy difficulty scaling

### Implementation
- Load via `DataManager.load_database("res://data/sector_nodes.csv", ...)`
- Reference in `SectorManager._weighted_random()` for spawning
- Use min/max values in node reward calculations

---

## Integration with Other Modules

### → Combat Module (Phase 3)
- **Trigger**: Node activation with enemies (outpost, colony, vault, graveyard)
- **Flow**: Sector Map → Situation Room → Combat → Return to Sector Map
- **Rewards**: Resources added to ResourceManager after combat victory
- **Failure**: Return to sector map, node still active (can retry)

### → Hangar Module (Phase 4)
- **Trigger**: Trader node activation, or pre-combat preparation
- **Flow**: Sector Map → Hangar/Shop UI → Sector Map
- **Purchases**: Spend Metal/Crystals on upgrades, equipment, ships
- **Loadout**: Configure ships before combat encounters

### → Save/Load System
- **Save Data**:
  - Current sector number
  - Player position
  - Revealed nodes array
  - Activated nodes array
  - Mothership timer state
  - Resource counts (via ResourceManager)
  - Fleet composition (via GameState)

---

## Testing & Validation Checklist

### Procedural Node Generation
- [ ] Nodes spawn ahead of player (2000-3000px forward)
- [ ] Nodes despawn behind player (500px behind)
- [ ] No overlapping nodes (minimum spacing 150px)
- [ ] Wormholes spawn every 3000-5000 pixels
- [ ] Node density feels appropriate (1 per 200-400px)

### Player Movement & Controls
- [ ] Ship constantly moves forward at current speed
- [ ] Swipe left/right veers ship with acceleration lag
- [ ] Higher speed = slower lateral response (maneuverability formula works)
- [ ] Ship centers laterally when no input
- [ ] Forward distance tracked accurately

### Jump Mechanic
- [ ] Jump costs 10 fuel AND has cooldown
- [ ] Cannot jump without fuel OR while on cooldown
- [ ] Jump moves ship 200-300px horizontally
- [ ] Jump does NOT affect forward speed
- [ ] Cooldown timer displays correctly (10-15s)

### Gravity Assist
- [ ] Gravity assist costs 1 fuel
- [ ] Can increase speed (+20%)
- [ ] Can decrease speed (-20%)
- [ ] Speed multiplier persists until next gravity assist
- [ ] Only available near gravitational objects

### Proximity Node Interaction
- [ ] Popup appears when within 150-200px of node
- [ ] **Time pauses completely** when popup visible
- [ ] Node-specific options display correctly
- [ ] "Continue" option dismisses popup
- [ ] Time resumes when popup dismissed

### Mothership Pursuit
- [ ] Mothership spawns behind player at calculated distance
- [ ] Mothership accelerates over time
- [ ] Distance display updates in UI
- [ ] Display turns red at ≤2000 pixels
- [ ] Game over when mothership catches player
- [ ] Spawn distance decreases with sector number

### Alien Sweep System
- [ ] Sweeps spawn at appropriate intervals
- [ ] Warning appears 3-5 seconds before sweep
- [ ] Collision detection works correctly
- [ ] Collision triggers combat encounter
- [ ] Player can avoid sweeps with steering/jump
- [ ] Sweep patterns vary (horizontal, diagonal, pincer, wave)

### Infinite Scrolling
- [ ] Background tiles infinitely upward
- [ ] No visible seams in background
- [ ] Camera follows player ship smoothly
- [ ] No jitter or stuttering during movement
- [ ] Portrait orientation maintained (1080x2340)

### Resource Integration
- [ ] Resource display updates on change
- [ ] EventBus signals fire on resource gain/spend
- [ ] Mining nodes grant 30-100 resources
- [ ] Outposts grant variable rewards
- [ ] Fuel spending validated (cannot overspend)

### Console & Debugging
- [ ] No errors in console
- [ ] SectorManager logs sector start
- [ ] Node spawning/despawning logged
- [ ] Mothership distance logged
- [ ] Speed changes logged
- [ ] Alien sweep spawns logged

---

## Common Implementation Pitfalls

1. **Don't forget procedural spawning** - Nodes must spawn ahead and despawn behind
2. **Don't pause time incorrectly** - Only node proximity popups pause time, not other systems
3. **Don't skip fuel AND cooldown validation** - Jump requires both fuel and no active cooldown
4. **Don't exceed 300 lines** - Break SectorManager into multiple autoloads if needed (e.g., AlienSweepManager)
5. **Don't test on desktop only** - Swipe controls are fundamentally different from mouse
6. **Don't forget speed affects maneuverability** - Lateral acceleration must decrease with speed
7. **Don't render off-screen nodes** - Only render nodes within camera view + small margin
8. **Don't forget to emit signals** - EventBus integration required for decoupling
9. **Don't use direct script references** - All cross-system communication via EventBus
10. **Don't let mothership spawn too close** - Balance challenge appropriately per sector

---

## Implementation Phases

### Phase 2a: Core Infinite Scrolling System (CRITICAL)
1. SectorManager singleton (procedural generation, forward movement tracking, mothership pursuit)
2. sector_map scene (automatic forward scrolling, camera following player)
3. Infinite background tiling system
4. Player ship positioning (lateral + forward distance)

### Phase 2b: Movement & Controls (CRITICAL)
1. Swipe lateral steering with acceleration lag
2. Speed-based maneuverability formula
3. Jump implementation (horizontal dash, fuel + cooldown)
4. Gravity assist implementation (speed up/down, 1 fuel)

### Phase 2c: Procedural Node System (HIGH)
1. BaseNode component (proximity detection, time pause on popup)
2. Node spawning ahead of player (2000-3000px)
3. Node despawning behind player (500px)
4. Wormhole nodes (periodic spawning)

### Phase 2d: Mothership & Alien Sweeps (HIGH)
1. Mothership spawn and pursuit mechanics
2. Mothership distance tracking and UI
3. Alien sweep pattern generation
4. Sweep collision detection

### Phase 2d: Remaining Nodes (MEDIUM)
1. Asteroid node
2. Graveyard node
3. Trader node (shop placeholder)
4. Colony node (enemy placeholder)
5. Vault node (encounter placeholder)

### Phase 2e: Polish & Testing (LOW)
1. Node icons and visual variety
2. Movement animations
3. Parallax background effects
4. Sound effects (node discovery, activation, etc.)

---

## Performance Considerations

### Mobile Optimization
- **Node Culling**: Only render nodes within camera view + margin
- **Texture Atlases**: Combine node icons into single texture
- **Instance Reuse**: Pool node instances, don't instantiate every frame
- **Reduced Draw Calls**: Batch similar nodes with MultiMesh (future)

### Memory Management
- **Node Limit**: Cap at 50 nodes per sector (prevents memory bloat)
- **Asset Preloading**: Preload node scenes at game start
- **Background Streaming**: Load background textures on-demand per sector

### Frame Rate Targets
- **Minimum**: 30 FPS on mid-range Android devices
- **Target**: 60 FPS on modern devices
- **GL Compatibility**: Renderer optimized for mobile GPUs

---

## Future Enhancements (Post-Phase 2)

### Vertical Looping
- Map wraps at top/bottom (currently disabled)
- Player can loop from y=5000 back to y=0
- Seamless transition (no visible seam)

### Enemy Patrols
- Alien Colony spawns roaming enemies
- Enemies pursue player if detected (proximity or sensor range)
- Combat triggers if caught
- Visual indicators for enemy positions (radar or minimap)

### Dynamic Events
- Random encounters while traveling (ambushes, distress signals)
- Temporary nodes (disappear after timer)
- Sector-specific events (asteroid storms, ion clouds)

### Advanced Movement
- Autopilot (automatic pathfinding to selected node)
- Momentum-based physics (drift, acceleration curves)
- Speed upgrades (mothership engine upgrades)

### Minimap
- Small overview map (top-right corner)
- Shows revealed area, player position, exit node if discovered
- Tap to quick-jump to location

### Node Interactions
- Mining nodes: Deploy miners, return later to collect
- Outposts: Salvage over time (risk vs. reward)
- Trader: Haggle mini-game for better prices
- Vault: Puzzle or hacking mini-game

---

## Conclusion

The **Sector Exploration Module** is the heart of Any-Type-7's gameplay loop. It combines procedural generation, strategic decision-making (jump vs. explore), resource management (fuel economy), and time pressure (mothership chase) into a cohesive mobile-optimized experience.

By following the data-driven architecture (SectorManager singleton, CSV-driven node properties) and maintaining strict file size limits (<300 lines), the module stays modular, maintainable, and scalable for future enhancements.

**Implementation Status**: SectorManager autoload complete, ready for scene and node implementation (Phase 2b-2e).

**Next Steps**: Begin sector_map.tscn creation and base node component implementation.
