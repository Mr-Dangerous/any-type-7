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

## Node Types

### Gravity Assist & Mining System

**Gravity Assist Objects**: Large celestial bodies (stars, planets, moons) that provide speed control opportunities
- When approaching, player chooses: turn into object (speed up), turn away (slow down), or go straight (maintain speed)
- **Speed change based on CSV `gravity_assist_multiplier`**:
  - Stars: ±0.4x (strongest - 2.0s lockout)
  - Gas Giants: ±0.2x (moderate - 1.0s lockout)
  - Rocky/Ice Planets: ±0.1x (weakest - 0.5s lockout)
- **Dynamic control lockout**: 0.5 seconds per 0.1 multiplier + proximity-based unlock
- Ship impulse pushes toward (faster) or away from (slower) the celestial body
- Most gravity assist objects are also mineable
- **Implementation Status**: ✅ Complete (CSV-driven, dynamic lockout)

**Mineable Objects**: Nodes that can be mined for resources (metals, crystals, fuel)
- Replaces the old "mining node" system
- Various celestial bodies and spatial features can be mined
- Resource yields vary by object type
- Mining can be instant (asteroids) or timed (planets, clusters)

**Interaction Types**:
- `mining_operation` - Deploy mining equipment, wait for extraction (timed)
- `instant_collect` - Immediate resource collection (no wait)
- `salvage_operation` - Salvage materials from wrecks (timed, potential combat)
- `data_hack` - Extract digital data/blueprints (instant or puzzle)
- `instant_reward` - Immediate resource grant (one-time)
- `open_shop` - Opens trader UI
- `optional_combat` - Player choice to engage or avoid
- `puzzle_encounter` - Skill/puzzle challenge
- `sector_exit` - Transition to next sector

---

### Celestial Bodies (Gravity Assist + Mineable)

### 1. Stars (Suns)
**Description**: Massive stellar bodies with extreme gravity and exotic materials

**Spawn Weight**: 2 (very rare - as requested)

**Gravity Assist**: Yes (strongest effect)
**Mineable**: Yes (80-200 resources, fuel-rich)

**Mechanics**:
- Extremely dangerous proximity - highest risk/reward
- Rich in exotic materials and fuel
- Strongest gravity assist potential
- High energy signature visible from distance

**Implementation Status**: ⚠️ Needs implementation

---

### 2. Gas Giants
**Description**: Massive gas planets with fuel-rich atmospheres

**Spawn Weight**: 8 (uncommon)

**Gravity Assist**: Yes (strong effect)
**Mineable**: Yes (40-120 resources, fuel-focused)

**Mechanics**:
- Fuel-rich atmosphere mining
- Strong gravity assist potential
- No surface to land on - atmospheric mining only
- Visual: Large banded planet with swirling clouds

**Implementation Status**: ⚠️ Needs implementation

---

### 3. Rocky Planets
**Description**: Terrestrial planets with metal-rich crusts

**Spawn Weight**: 15 (common)

**Gravity Assist**: Yes (moderate effect)
**Mineable**: Yes (30-100 resources, metal-focused)

**Combat Chance**: 0% (resources only)

**Mechanics**:
- Metal-rich surface mining
- Moderate gravity assist
- Occasional hostile encounters
- Balanced risk/reward for common node

**Implementation Status**: ⚠️ Needs implementation

---

### 4. Ice Planets
**Description**: Frozen worlds with crystal and fuel ice deposits

**Spawn Weight**: 12 (common)

**Gravity Assist**: Yes (moderate effect)
**Mineable**: Yes (30-100 resources, crystal/fuel-focused)

**Mechanics**:
- Crystal and fuel reserves in ice
- Moderate gravity assist
- No combat encounters
- Visual: Icy blue/white planet

**Implementation Status**: ⚠️ Needs implementation

---

### 5. Moons
**Description**: Small planetary satellites for quick resource gathering

**Spawn Weight**: 18 (very common)

**Gravity Assist**: Yes (weak effect)
**Mineable**: Yes (20-60 resources)

**Mechanics**:
- Quick mining operations (smaller yields)
- Weak gravity assist (less fuel efficiency)
- Most common celestial mineable
- Low risk, low reward

**Implementation Status**: ⚠️ Needs implementation

---

### Spatial Features

### 6. Nebula Clouds
**Description**: Colorful gas clouds containing exotic particles

**Spawn Weight**: 6 (uncommon)

**Gravity Assist**: No
**Mineable**: Yes (20-80 resources, rare materials)

**Mechanics**:
- Exotic particles and rare materials
- **Special Effect**: Reduces ship speed while inside (visual obscuration)
- No gravity well
- Beautiful visual effect opportunity

**Implementation Status**: ⚠️ Needs implementation

---

### 7. Asteroids
**Description**: Mineable space rocks drifting through sector

**Spawn Weight**: 20 (common)

**Gravity Assist**: No
**Mineable**: Yes (10-50 resources)

**Mechanics**:
- Instant collection (no mining time)
- No combat encounters
- Quick resource top-up option
- Most common mineable object

**Implementation Status**: ⚠️ Needs implementation

---

### 8. Asteroid Clusters
**Description**: Dense asteroid fields with navigation hazards

**Spawn Weight**: 10 (uncommon)

**Gravity Assist**: No
**Mineable**: Yes (40-120 resources)

**Combat Chance**: 0% (resources only)

**Mechanics**:
- Higher resource yield than single asteroids
- Navigation hazards (visual obstacle course)
- Occasional hostile encounters
- Requires more time to mine effectively

**Implementation Status**: ⚠️ Needs implementation

---

### Structures & Installations

### 9. Outpost Nodes
**Description**: Abandoned resource caches or derelict stations

**Spawn Weight**: 25 (very common)

**Gravity Assist**: No
**Mineable**: No

**Reward Structure**:
- 20-50 metal, 10-30 crystals (instant reward, no combat)

**Combat Chance**: 0% (resources only)

**Mechanics**:
- Proximity popup on approach
- Instant resource grant (no combat)
- One-time use per outpost
- Fast, safe resource gathering

**Implementation Status**: ✅ Core functionality ready (scripts/nodes/outpost_node.gd)

---

### 10. Derelict Stations
**Description**: Abandoned orbital facilities containing tech and blueprints

**Spawn Weight**: 10 (uncommon)

**Gravity Assist**: No
**Mineable**: Yes (50-180 resources, tech-focused)

**Combat Chance**: 0% (resources only)

**Mechanics**:
- Salvage tech components and blueprint fragments
- Similar to graveyards but space station theme
- Higher chance of rare technological finds
- May contain unique station modules

**Implementation Status**: ⚠️ Needs implementation

---

### 11. Ship Graveyards
**Description**: Derelict fleets from previous battles

**Spawn Weight**: 10 (uncommon)

**Gravity Assist**: No
**Mineable**: Yes (50-200 resources, ship parts)

**Combat Chance**: 0% (resources only)

**Mechanics**:
- Salvage materials, ship parts, and rare components
- Can find ship blueprints or rare upgrades
- Potential for unique equipment
- Salvage operation takes time

**Implementation Status**: ⚠️ Needs implementation

---

### 12. Satellite Arrays
**Description**: Orbital satellite networks with valuable navigation data

**Spawn Weight**: 6 (uncommon)

**Gravity Assist**: No
**Mineable**: No

**Combat Chance**: 0% (data only)

**Mechanics**:
- Hack for blueprints and navigation data
- No physical resources, but valuable intel
- May reveal hidden nodes or wormhole locations
- Tech challenge rather than mining operation

**Implementation Status**: ⚠️ Needs implementation

---

### Special Encounters

### 13. Trader Ships
**Description**: Merchant vessels offering goods and services

**Spawn Weight**: 8 (uncommon)

**Gravity Assist**: No
**Mineable**: No

**Combat Chance**: 0% (friendly)

**Shop Inventory**:
- Assortment of Tier 1 and Tier 2 items
- Blueprints
- Fleet upgrades

**Costs**: Metal and Crystals (Fuel not sold)

**Mechanics**:
- Opens shop UI
- Inventory randomized per trader
- Prices scale with sector difficulty
- No combat

**Implementation Status**: ⚠️ Needs implementation (trader_node.gd + shop UI)

---

### 14. Alien Colonies
**Description**: Hostile alien installations with valuable resources

**Spawn Weight**: 5 (rare)

**Gravity Assist**: No
**Mineable**: No

**Combat Chance**: 100% (guaranteed if engaged)

**Encounter Behavior**:
- **Proximity Detection**: Popup appears when ship passes within range
- **Combat Option**: Player can choose to engage or avoid
- **Rewards**: Large resource caches (200-500 resources), rare blueprints, unique equipment

**Mechanics**:
- Can be avoided by steering around them
- Engaging triggers combat encounter
- One-time interaction per colony
- High-risk, high-reward

**Implementation Status**: ⚠️ Needs implementation (colony_node.gd + encounter system)

---

### 15. Artifact Vaults
**Description**: Ancient alien installations containing powerful technology

**Spawn Weight**: 2 (very rare)

**Gravity Assist**: No
**Mineable**: No

**Combat Chance**: 40% (ancient guardians)

**Rewards**:
- Unique upgrades (one-of-a-kind effects)
- Legendary equipment
- Permanent ship modifications

**Mechanics**:
- Combat encounter possible (guardians)
- Puzzle or skill challenge (future feature)
- One-time unlock per vault
- Rewards not available elsewhere

**Implementation Status**: ⚠️ Needs implementation (vault_node.gd + encounter system)

---

### 16. Wormholes (Exit Nodes)
**Description**: Portals to the next sector

**Spawn Weight**: 0 (special spawning rules - appears every 3000-5000 pixels of travel)

**Gravity Assist**: No
**Mineable**: No

**Combat Chance**: 0%

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

**Implementation Status**: ⚠️ Needs implementation (wormhole_node.gd + transition logic)

---

## Node Type Summary Table

| Node Type | Spawn Weight | Gravity Assist | Mineable | Combat % | Primary Resources |
|-----------|--------------|----------------|----------|----------|-------------------|
| **Celestial Bodies** |
| Star | 2 | ✅ Strong | ✅ | 0% | Fuel, Exotic Materials (80-200) |
| Gas Giant | 8 | ✅ Strong | ✅ | 0% | Fuel-focused (40-120) |
| Rocky Planet | 15 | ✅ Moderate | ✅ | 0% | Metal-focused (30-100) |
| Ice Planet | 12 | ✅ Moderate | ✅ | 0% | Crystals, Fuel (30-100) |
| Moon | 18 | ✅ Weak | ✅ | 0% | Mixed (20-60) |
| **Spatial Features** |
| Nebula | 6 | ❌ | ✅ | 0% | Rare Materials (20-80) |
| Asteroid | 20 | ❌ | ✅ | 0% | Metal, Crystals (10-50) |
| Asteroid Cluster | 10 | ❌ | ✅ | 0% | Mixed (40-120) |
| **Structures** |
| Outpost | 25 | ❌ | ❌ | 0% | Mixed (20-50) |
| Derelict Station | 10 | ❌ | ✅ | 0% | Tech, Blueprints (50-180) |
| Graveyard | 10 | ❌ | ✅ | 0% | Ship Parts (50-200) |
| Satellite Array | 6 | ❌ | ❌ | 0% | Data, Blueprints |
| **Special Encounters** |
| Trader | 8 | ❌ | ❌ | 0% | Shop (Purchase Items) |
| Alien Colony | 5 | ❌ | ❌ | 100%* | High Rewards (200-500) |
| Artifact Vault | 2 | ❌ | ❌ | 40% | Legendary Items |
| Wormhole | 0** | ❌ | ❌ | 0% | Sector Exit |

*Alien Colony combat is optional - player chooses to engage or avoid
**Wormhole spawn controlled by distance traveled (3000-5000px), not random weight

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
- Swipe left or right to make ship veer in that direction (or A/D keys for testing)
- Heavy momentum physics with drift feel
- Ship gradually auto-centers with weak spring force (allows full edge access)
- Release swipe to let momentum carry ship (drifts with damping)

**Implemented Physics** (sector_map.gd):
- `BASE_ACCELERATION: 800.0` - Lateral acceleration
- `VELOCITY_DAMPING: 0.92` - 8% velocity loss per frame (drift feel)
- `AUTO_CENTER_FORCE: 0.2` - **Reduced from 2.0** for edge access
- `MAX_LATERAL_VELOCITY: 400.0` - Speed cap
- **Movement bounds**: 30px to 1050px (allows near-edge positioning)

**Use Case**: Navigate to nodes, avoid alien sweeps, position for encounters

**Implementation Status**: ✅ Complete with fine-tuned physics

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



**Behavior** (✅ Implemented):
- Speed change based on **CSV `gravity_assist_multiplier`** per node type:
  - Stars: ±0.4x (strongest effect)
  - Gas Giants: ±0.2x (moderate effect)
  - Rocky/Ice Planets: ±0.1x (weak effect)
- Speed persists until next gravity assist adjustment
- Available near gravitationally significant objects (CSV `gravity_assist: yes`)
- Three choices in proximity popup: **Faster** (+multiplier), **Slower** (-multiplier), **Same** (no change)
- **Dynamic control lockout**: 0.5 seconds per 0.1 multiplier (0.1x→0.5s, 0.2x→1.0s, 0.4x→2.0s)
- Ship impulse: Pushed toward node (faster) or away from node (slower)
- Lockout ends when: (1) proximity exit OR (2) timer expires (whichever first)
- **Default speed**: 2.0x (changed from 1.0x for better pacing)
- **Development controls**: W/S keys adjust speed in 0.1x increments

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

## Alien Encounter System (Projectile Patterns)

### Core Concept
Aliens periodically launch **encounter patterns** - formations of ships that fly across the map like projectiles in coordinated patterns. These function as bullet-hell sequences where the player must dodge incoming alien ships. Each collision accumulates combat difficulty points, and after the pattern completes, combat is triggered with scaled difficulty.

### Encounter Flow

**Phase 1: Warning (3-5 seconds)**
- Visual indicator shows incoming pattern type and trajectory
- Pattern name displayed (e.g., "HORIZONTAL WAVE INCOMING")
- Countdown timer: "3... 2... 1..."
- Audio warning siren

**Phase 2: Projectile Pattern (5-15 seconds)**
- Alien ships fly across screen as projectiles in coordinated formation
- Player dodges using lateral steering and jump
- Each collision adds +1 `combat_difficulty` point
- Visual/audio feedback on each hit
- Hit counter displays: "Hits: 3"

**Phase 3: Combat Trigger (automatic after pattern ends)**
- Combat begins when all alien ships have passed
- Difficulty scales based on `combat_difficulty` points
- **Cannot be avoided** - combat always triggers after encounter

### Combat Difficulty Scaling

| Hits Taken | Combat Modifier |
|------------|-----------------|
| 0 | Base difficulty (standard enemy spawns) |
| 1-2 | +1 elite enemy |
| 3-4 | +2 elite enemies |
| 5-6 | +3 elite enemies |
| 7+ | +1 boss enemy + 2 elites |

### Encounter Patterns

#### 1. Horizontal Wave
- **Formation**: 3-5 rows of ships with gaps
- **Speed**: Moderate (slightly faster than player base speed)
- **Duration**: 8-10 seconds
- **Gap Size**: 150-200 pixels (navigable with timing)
- **Frequency**: Every 60-90 seconds

#### 2. Diagonal Cross
- **Formation**: Two diagonal lines crossing in center
- **Speed**: Fast (1.5× player base speed)
- **Duration**: 6-8 seconds
- **Gap Size**: 200-250 pixels at center intersection
- **Frequency**: Every 90-120 seconds

#### 3. Pincer Formation
- **Formation**: Mirror formations converging from sides
- **Speed**: Moderate
- **Duration**: 10-12 seconds
- **Gap Size**: 200-300 pixels safe zone (narrows over time)
- **Frequency**: Every 120-180 seconds

#### 4. Spiral Wave
- **Formation**: Ships spiral inward from edges
- **Speed**: Slow to moderate
- **Duration**: 12-15 seconds
- **Gap Size**: 150-200 pixels between spiral arms
- **Frequency**: Every 90-120 seconds

### Player Strategies
- **Perfect Dodge**: Avoid all ships for base difficulty (hardest, best outcome)
- **Accept Light Damage**: Take 1-2 hits for slight difficulty increase (manageable)
- **Emergency Jump**: Use jump ability to reposition during pattern
- **Speed Control**: Slow down with gravity assist for better maneuverability

### Scaling with Sector Progression
- **Frequency**: Encounters occur more often in higher sectors
- **Pattern Speed**: Ship speeds increase 10% per sector
- **Formation Density**: Tighter formations, smaller gaps in later sectors
- **Warning Time**: Decreases from 5s (sector 1) to 3s (sector 10+)

### Combat Triggers Summary
**Encounter-based combat** (scaled difficulty):
- **Alien Projectile Patterns**: Triggers after pattern completes (difficulty = hits taken)

**Node-based combat** (fixed difficulty):
- **Alien Colony**: 100% combat if player engages (player choice, high difficulty)
- **Artifact Vault**: 40% combat chance (boss encounter)

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
- **gravity Assisst options for large objects** Instead of having a continue button, you can choose to speed up, slow down or stay the same speed. However, this locks your movement in one direction for one second when resuming. 

### Jump Button (Emergency Dash)
- **Location**: UI overlay (bottom-right)
- **Activation**: Tap button, then swipe left or right to choose direction
- **Validation**: Grays out if fuel < 10 OR on cooldown
- **Visual**: Shows cooldown timer (e.g., "Jump: 8s")
- **Cost Display**: "10 Fuel" label


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

### Alien Encounter Patterns
```gdscript
signal encounter_pattern_warning(pattern_type: String, countdown: float)
signal encounter_pattern_started(pattern_id: String)
signal encounter_hit_taken(combat_difficulty: int)  # Emitted on each collision
signal encounter_pattern_completed(final_combat_difficulty: int)  # Triggers combat
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
├── Celestial Bodies (Gravity Assist + Mineable)
│   ├── StarNode (star_node.gd)
│   ├── GasGiantNode (gas_giant_node.gd)
│   ├── RockyPlanetNode (rocky_planet_node.gd)
│   ├── IcePlanetNode (ice_planet_node.gd)
│   └── MoonNode (moon_node.gd)
├── Spatial Features
│   ├── NebulaNode (nebula_node.gd)
│   ├── AsteroidNode (asteroid_node.gd)
│   └── AsteroidClusterNode (asteroid_cluster_node.gd)
├── Structures & Installations
│   ├── OutpostNode (outpost_node.gd)
│   ├── DerelictStationNode (derelict_station_node.gd)
│   ├── GraveyardNode (graveyard_node.gd)
│   └── SatelliteArrayNode (satellite_array_node.gd)
├── Special Encounters
│   ├── TraderNode (trader_node.gd)
│   ├── ColonyNode (colony_node.gd)
│   └── VaultNode (vault_node.gd)
└── Exit Node
    └── WormholeNode (wormhole_node.gd)
```

---

## File Size Compliance

### Target: All files under 300 lines

| File | Estimated Lines | Status |
|------|-----------------|--------|
| SectorManager.gd | ~280 | ⚠️ Close to limit |
| sector_map.gd | ~250 | ✅ Safe |
| base_node.gd | ~120 | ✅ Safe (gravity assist logic added) |
| **Celestial Bodies** | | |
| star_node.gd | ~80 | ✅ Safe |
| gas_giant_node.gd | ~80 | ✅ Safe |
| rocky_planet_node.gd | ~80 | ✅ Safe |
| ice_planet_node.gd | ~80 | ✅ Safe |
| moon_node.gd | ~70 | ✅ Safe |
| **Spatial Features** | | |
| nebula_node.gd | ~90 | ✅ Safe (speed modifier) |
| asteroid_node.gd | ~70 | ✅ Safe |
| asteroid_cluster_node.gd | ~90 | ✅ Safe |
| **Structures** | | |
| outpost_node.gd | ~90 | ✅ Safe |
| derelict_station_node.gd | ~85 | ✅ Safe |
| graveyard_node.gd | ~80 | ✅ Safe |
| satellite_array_node.gd | ~95 | ✅ Safe (data hack system) |
| **Special Encounters** | | |
| trader_node.gd | ~100 | ✅ Safe |
| colony_node.gd | ~120 | ✅ Safe |
| vault_node.gd | ~90 | ✅ Safe |
| wormhole_node.gd | ~70 | ✅ Safe |

**Total**: ~2,000 lines across 20 files (average 100 lines/file)

---

## CSV-Driven Sector Data ✅

### sector_nodes.csv (UPDATED)

Defines all node type properties for procedural generation:

**Columns:**
- `node_type` - Unique identifier (star, gas_giant, rocky_planet, ice_planet, moon, nebula, asteroid, asteroid_cluster, outpost, derelict_station, graveyard, satellite_array, trader, colony, vault, wormhole)
- `spawn_weight` - Relative probability of spawning (higher = more common)
- `proximity_radius` - Distance in pixels that triggers interaction popup
- `min_resources` / `max_resources` - Resource reward range
- `combat_chance` - Probability of combat encounter (0.0-1.0)
- `interaction_type` - Type of interaction (mining_operation, instant_reward, open_shop, salvage_operation, data_hack, etc.)
- `fuel_cost` - Fuel cost to interact (currently 0 for all)
- `gravity_assist` - Whether node provides gravity assist (yes/no)
- `mineable` - Whether node can be mined for resources (yes/no)
- `description` - Human-readable description

**Status:** ✅ Populated with 16 node types

**Key Changes:**
- Removed "mining" as a dedicated node type
- Added gravity_assist and mineable columns
- Added celestial bodies: star, gas_giant, rocky_planet, ice_planet, moon
- Added spatial features: nebula, asteroid_cluster
- Added installations: derelict_station, satellite_array
- Most gravity assist objects are also mineable

### alien_sweep_patterns.csv (CREATED)

Defines alien sweep behaviors for the new avoidance/combat system:

**Columns:**
- `pattern_id` - Unique identifier for sweep pattern
- `pattern_type` - Category: horizontal, diagonal, pincer, wave
- `base_speed` - Movement speed in pixels/second
- `width_px` - Width of sweep hitbox
- `gap_px` - Gap size (for pincer/wave patterns)
- `warning_time_sec` - Advance warning time before sweep enters screen
- `min_sector` - First sector this pattern can appear
- `spawn_weight` - Relative spawn probability
- `visual_asset` - Path to formation sprite
- `description` - Human-readable description

**Status:** ✅ Populated with 10 patterns (scales from sector 1-7)

### sector_progression.csv (CREATED)

Defines difficulty scaling and mothership pursuit per sector:

**Columns:**
- `sector_number` - Sector index (1-20)
- `mothership_spawn_distance` - How far behind player mothership spawns
- `mothership_base_speed` - Initial mothership speed
- `mothership_accel_rate` - Mothership acceleration per second
- `wormhole_min_distance` / `wormhole_max_distance` - Distance range for wormhole spawning
- `sweep_frequency_min` / `sweep_frequency_max` - Seconds between alien sweeps
- `node_density_multiplier` - Multiplier for node spawn rate
- `resource_multiplier` - Multiplier for resource rewards

**Status:** ✅ Populated with progression curve for 20 sectors

### Benefits
- **Balance without code changes** - Tune spawn rates, speeds, and rewards via CSV
- **Data-driven difficulty** - Sector progression defined in spreadsheet
- **Easy iteration** - Designers can adjust values and test immediately
- **Clear documentation** - CSV serves as game design specification

### Implementation
```gdscript
# In DataManager.gd
var sector_nodes_data := {}
var alien_sweeps_data := {}
var sector_progression_data := {}

func _ready():
    load_csv_database("res://data/sector_nodes.csv", sector_nodes_data)
    load_csv_database("res://data/alien_sweep_patterns.csv", alien_sweeps_data)
    load_csv_database("res://data/sector_progression.csv", sector_progression_data)

# In SectorManager.gd
var node_config = DataManager.get_node_config("mining")
var sweep_config = DataManager.get_sweep_pattern("sweep_h_left")
var progression = DataManager.get_sector_progression(current_sector)
```

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
- [ ] Mineable nodes grant resources (varies by type)
- [ ] Gravity assist objects grant mining + speed control
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

### Phase 2d: Celestial Body Nodes (HIGH)
1. Star node (rare, gravity assist + mineable)
2. Gas giant node (gravity assist + fuel mining)
3. Rocky planet node (gravity assist + metal mining)
4. Ice planet node (gravity assist + crystal mining)
5. Moon node (weak gravity assist + quick mining)

### Phase 2e: Spatial Feature Nodes (MEDIUM)
1. Nebula node (speed modifier + rare materials)
2. Asteroid node (instant collect)
3. Asteroid cluster node (rich mining + hazards)

### Phase 2f: Structure & Installation Nodes (MEDIUM)
1. Derelict station node (salvage tech)
2. Graveyard node (salvage ships)
3. Satellite array node (data hacking)

### Phase 2g: Special Encounter Nodes (MEDIUM)
1. Trader node (shop placeholder)
2. Colony node (combat placeholder)
3. Vault node (puzzle placeholder)

### Phase 2h: Polish & Testing (LOW)
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
- Celestial bodies: Deploy mining equipment to planets, return later to collect
- Gravity assist mastery: Skill-based timing mini-game for bonus speed/fuel
- Outposts: Salvage over time (risk vs. reward)
- Trader: Haggle mini-game for better prices
- Vault: Puzzle or hacking mini-game
- Nebulas: Navigation challenge mini-game (visibility reduced)

---

## Conclusion

The **Sector Exploration Module** is the heart of Any-Type-7's gameplay loop. It combines procedural generation, strategic decision-making (jump vs. explore), resource management (fuel economy), and time pressure (mothership chase) into a cohesive mobile-optimized experience.

By following the data-driven architecture (SectorManager singleton, CSV-driven node properties) and maintaining strict file size limits (<300 lines), the module stays modular, maintainable, and scalable for future enhancements.

**Implementation Status**: SectorManager autoload complete, ready for scene and node implementation (Phase 2b-2e).

**Next Steps**: Begin sector_map.tscn creation and base node component implementation.
