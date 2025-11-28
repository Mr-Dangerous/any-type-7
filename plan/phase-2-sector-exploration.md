# Phase 2: Sector Exploration Prototype Implementation Plan

## Overview

**Goal**: Build the primary gameplay loop - an infinite runner-style momentum system with procedural node generation

**Status**: Ready to implement (Phase 1 complete, core infrastructure operational) - **MAJOR DESIGN OVERHAUL**

**Dependencies**:
- ✅ Phase 1 complete (EventBus, DataManager, GameState, ResourceManager)
- ✅ CSV databases populated
- ✅ Portrait UI framework established

**Deliverable**: Playable sector exploration with:
- Infinite scrolling with automatic forward movement
- Procedural node generation (spawns ahead, despawns behind)
- 8 node types (Mining, Outposts, Colonies, Traders, Asteroids, Graveyards, Vaults, Wormholes)
- Swipe-based lateral steering with speed-dependent maneuverability
- Jump mechanic (horizontal dash with fuel cost + cooldown)
- Gravity assist (speed up/down control)
- Proximity-based node interaction (time pause on popup)
- Alien sweep patterns (avoidance/combat triggers)
- Pursuing mothership (spawns behind, accelerates to catch player)
- Touch-optimized mobile controls

---

## Architecture Principles (Phase 2 Specific)

1. **Infinite Scrolling System**: Procedural node generation ahead of player, despawning behind
2. **SectorManager Singleton**: Orchestrates forward movement, node spawning, mothership pursuit, alien sweeps
3. **Camera2D Auto-Following**: Camera automatically follows player ship, no manual scrolling
4. **Proximity-Based Interaction**: Nodes trigger popups when player passes within range (time pauses)
5. **Speed-Based Maneuverability**: Lateral acceleration inversely proportional to forward speed
6. **CSV-Driven Node Data**: Node properties, spawn weights, resource yields all data-driven

---

## ⚠️ MAJOR DESIGN CHANGE - OLD IMPLEMENTATION OBSOLETE ⚠️

**The design has fundamentally changed from a fixed-map tap-to-move system to an infinite scrolling momentum-based system.**

**Key Changes:**
- ❌ **REMOVED**: Fixed 5000px map, fog of war, tap-to-select nodes, timer-based mothership
- ✅ **NEW**: Infinite scrolling, procedural generation, swipe steering, proximity popups, pursuing mothership, alien sweeps

**Implementation below is OUTDATED** - Use as reference only for component structure. Refer to `/docs/sector-exploration-module.md` for current design specifications.

---

## Phase 2 Task Breakdown (REQUIRES COMPLETE REWRITE)

### Task 1: SectorManager Singleton (Infinite Scrolling Orchestration)

**Priority**: CRITICAL (foundation for all sector systems)

**File**: `scripts/autoloads/SectorManager.gd`

**Purpose**: Manage sector state, node generation, player position, and fog of war

#### Core Responsibilities
- Track current sector number and difficulty
- Generate node positions on map
- Manage fog of war (revealed/hidden nodes)
- Track player position
- Handle sector completion and transition
- Manage alien mothership timer

#### Implementation Pattern

```gdscript
extends Node

# ============================================================
# SECTOR STATE
# ============================================================

var current_sector: int = 1
var sector_start_time: float = 0.0
var mothership_arrival_time: float = 300.0  # 5 minutes base
var current_background: String = ""  # Path to current sector background

# ============================================================
# MAP CONFIGURATION
# ============================================================

const MAP_WIDTH: int = 1080  # Match screen width
const MAP_HEIGHT: int = 5000  # Scrollable height
const MAP_LOOPS_VERTICALLY: bool = true

# Background textures (randomly selected per sector)
const BACKGROUNDS: Array[String] = [
    "res://assets/Backgrounds/starfield_background.png",
    "res://assets/Backgrounds/red_starfield_background.png",
    "res://assets/Backgrounds/light_stream_background.png"
]

# ============================================================
# NODE TRACKING
# ============================================================

var all_nodes: Array[Dictionary] = []  # All nodes in sector
var revealed_nodes: Array[String] = []  # Node IDs player can see
var activated_nodes: Array[String] = []  # Nodes player has visited
var exit_node_id: String = ""

# ============================================================
# PLAYER POSITION
# ============================================================

var player_position: Vector2 = Vector2(540, 2500)  # Center start
var current_speed_multiplier: float = 1.0  # Gravity assist bonus

# ============================================================
# INITIALIZATION
# ============================================================

func _ready() -> void:
    print("[SectorManager] Initialized")
    EventBus.sector_entered.connect(_on_sector_entered)

func start_sector(sector_number: int) -> void:
    current_sector = sector_number
    sector_start_time = Time.get_ticks_msec() / 1000.0
    mothership_arrival_time = _calculate_mothership_time(sector_number)

    # Randomly select background for this sector
    current_background = BACKGROUNDS[randi() % BACKGROUNDS.size()]

    _generate_sector_nodes()
    _reveal_starting_area()

    EventBus.sector_entered.emit(sector_number)
    print("[SectorManager] Sector %d started - Mothership arrives in %.1fs" % [sector_number, mothership_arrival_time])
    print("[SectorManager] Background: %s" % current_background)

# ============================================================
# NODE GENERATION
# ============================================================

func _generate_sector_nodes() -> void:
    all_nodes.clear()
    revealed_nodes.clear()
    activated_nodes.clear()

    # Generate 30-50 nodes across map
    var node_count := randi_range(30, 50)

    for i in range(node_count):
        var node_data := _create_random_node(i)
        all_nodes.append(node_data)

    # Guarantee one exit node
    var exit_node := _create_exit_node(node_count)
    all_nodes.append(exit_node)
    exit_node_id = exit_node.node_id

    print("[SectorManager] Generated %d nodes (including exit)" % all_nodes.size())

func _create_random_node(index: int) -> Dictionary:
    var node_types := ["mining", "outpost", "asteroid", "graveyard", "trader", "colony", "vault"]
    var weights := [30, 25, 20, 10, 8, 5, 2]  # Spawn probability

    var node_type := _weighted_random(node_types, weights)
    var position := Vector2(
        randf_range(100, MAP_WIDTH - 100),
        randf_range(100, MAP_HEIGHT - 100)
    )

    return {
        "node_id": "node_%d" % index,
        "node_type": node_type,
        "position": position,
        "is_revealed": false,
        "is_activated": false
    }

func _create_exit_node(index: int) -> Dictionary:
    var position := Vector2(
        randf_range(200, MAP_WIDTH - 200),
        randf_range(1000, MAP_HEIGHT - 1000)
    )

    return {
        "node_id": "exit_node",
        "node_type": "exit",
        "position": position,
        "is_revealed": false,
        "is_activated": false
    }

func _weighted_random(options: Array, weights: Array) -> String:
    var total_weight := 0
    for w in weights:
        total_weight += w

    var rand := randf() * total_weight
    var cumulative := 0

    for i in range(options.size()):
        cumulative += weights[i]
        if rand <= cumulative:
            return options[i]

    return options[0]

# ============================================================
# FOG OF WAR
# ============================================================

func _reveal_starting_area() -> void:
    var reveal_radius := 300.0

    for node in all_nodes:
        var distance := player_position.distance_to(node.position)
        if distance <= reveal_radius:
            reveal_node(node.node_id)

func reveal_node(node_id: String) -> void:
    if not revealed_nodes.has(node_id):
        revealed_nodes.append(node_id)

        var node := get_node_data(node_id)
        EventBus.node_discovered.emit(node_id, node.get("node_type", "unknown"))

func reveal_area_around(position: Vector2, radius: float) -> void:
    for node in all_nodes:
        var distance := position.distance_to(node.position)
        if distance <= radius:
            reveal_node(node.node_id)

# ============================================================
# NODE QUERIES
# ============================================================

func get_node_data(node_id: String) -> Dictionary:
    for node in all_nodes:
        if node.node_id == node_id:
            return node
    return {}

func get_revealed_nodes() -> Array[Dictionary]:
    var results: Array[Dictionary] = []
    for node_id in revealed_nodes:
        results.append(get_node_data(node_id))
    return results

func is_node_revealed(node_id: String) -> bool:
    return revealed_nodes.has(node_id)

func activate_node(node_id: String) -> void:
    if not activated_nodes.has(node_id):
        activated_nodes.append(node_id)
        EventBus.node_activated.emit(node_id)

# ============================================================
# PLAYER MOVEMENT
# ============================================================

func move_player_to(target_position: Vector2) -> void:
    player_position = target_position
    reveal_area_around(player_position, 300.0)

func jump_to_position(target_position: Vector2) -> bool:
    var fuel_cost := 10

    if not ResourceManager.spend_resources({"fuel": fuel_cost}, "jump"):
        return false

    player_position = target_position
    current_speed_multiplier = 1.0  # Reset gravity assist
    reveal_area_around(player_position, 400.0)  # Larger reveal on jump

    print("[SectorManager] Jumped to %s - Fuel spent: %d" % [target_position, fuel_cost])
    return true

func apply_gravity_assist() -> bool:
    var fuel_cost := 1

    if not ResourceManager.spend_resources({"fuel": fuel_cost}, "gravity_assist"):
        return false

    current_speed_multiplier += 0.2  # +20% speed permanently until next jump
    print("[SectorManager] Gravity assist applied - Speed: %.1fx" % current_speed_multiplier)
    return true

# ============================================================
# MOTHERSHIP TIMER
# ============================================================

func _calculate_mothership_time(sector_num: int) -> float:
    # Mothership arrives sooner each sector
    var base_time := 300.0  # 5 minutes
    var reduction_per_sector := 15.0  # -15s per sector
    var minimum_time := 60.0  # Never less than 1 minute

    return max(base_time - (sector_num * reduction_per_sector), minimum_time)

func get_time_until_mothership() -> float:
    var current_time := Time.get_ticks_msec() / 1000.0
    var elapsed := current_time - sector_start_time
    return max(mothership_arrival_time - elapsed, 0.0)

func is_mothership_arrived() -> bool:
    return get_time_until_mothership() <= 0.0
```

**Success Criteria**:
- Generates 30-50 random nodes per sector
- Fog of war reveals nodes within radius
- Tracks player position and movement
- Handles fuel-based jumping and gravity assist
- Mothership timer counts down
- Under 300 lines

**Configuration**: Add to Autoload
- Path: `res://scripts/autoloads/SectorManager.gd`
- Name: `SectorManager`

---

### Task 2: Sector Map Scene (Visual Map & Camera)

**Priority**: CRITICAL

**File**: `scenes/sector_map.tscn` + `scripts/sector_map.gd`

**Purpose**: Visual representation of sector with scrolling camera and node rendering

#### Scene Structure

```
Control (sector_map.gd) [1080x2340]
├── Camera2D (MapCamera)
│   └── [Script handles touch drag scrolling]
├── Node2D (MapContainer)
│   ├── Sprite2D (Background - randomly selected starfield)
│   │   └── Texture: One of 3 backgrounds from assets/Backgrounds/
│   ├── Node2D (NodesLayer)
│   │   └── [Dynamically spawned node instances]
│   └── Sprite2D (PlayerShip)
│       └── Texture: res://assets/ships/havoc_fighter.png
└── CanvasLayer (UI Overlay)
    └── MarginContainer
        └── VBoxContainer
            ├── HBoxContainer (Resource Display)
            │   ├── Label ("Metal: 100")
            │   ├── Label ("Crystals: 50")
            │   └── Label ("Fuel: 100")
            ├── Label (Mothership Timer: "4:35")
            └── HBoxContainer (Action Buttons)
                ├── Button ("Jump")
                └── Button ("Gravity Assist")
```

#### Script Pattern

```gdscript
extends Control

@onready var camera: Camera2D = $MapCamera
@onready var nodes_layer: Node2D = $MapContainer/NodesLayer
@onready var player_ship: Sprite2D = $MapContainer/PlayerShip
@onready var timer_label: Label = $UIOverlay/MarginContainer/VBoxContainer/TimerLabel

# ============================================================
# CAMERA SCROLLING
# ============================================================

var camera_drag_active: bool = false
var camera_drag_start: Vector2 = Vector2.ZERO

@onready var background: Sprite2D = $MapContainer/Background

func _ready() -> void:
    SectorManager.start_sector(GameState.current_sector)
    _set_random_background()
    _spawn_all_nodes()
    _update_player_position()

    EventBus.node_discovered.connect(_on_node_discovered)

# ============================================================
# BACKGROUND SETUP
# ============================================================

func _set_random_background() -> void:
    var bg_texture := load(SectorManager.current_background) as Texture2D
    background.texture = bg_texture

    # Scale background to fill map area
    if bg_texture:
        var texture_size := bg_texture.get_size()
        var scale_x := SectorManager.MAP_WIDTH / texture_size.x
        var scale_y := SectorManager.MAP_HEIGHT / texture_size.y
        background.scale = Vector2(scale_x, scale_y)
        background.position = Vector2(SectorManager.MAP_WIDTH / 2, SectorManager.MAP_HEIGHT / 2)

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            camera_drag_active = true
            camera_drag_start = event.position
        else:
            camera_drag_active = false

    elif event is InputEventScreenDrag and camera_drag_active:
        var drag_delta := event.position - camera_drag_start
        camera.position -= drag_delta
        camera_drag_start = event.position

        # Clamp camera to map bounds
        camera.position.y = clamp(camera.position.y, 0, SectorManager.MAP_HEIGHT)

# ============================================================
# NODE SPAWNING
# ============================================================

func _spawn_all_nodes() -> void:
    for node_data in SectorManager.all_nodes:
        _spawn_node(node_data)

func _spawn_node(node_data: Dictionary) -> void:
    var node_scene := _get_node_scene(node_data.node_type)
    var node_instance := node_scene.instantiate()

    node_instance.position = node_data.position
    node_instance.set_meta("node_id", node_data.node_id)
    node_instance.visible = SectorManager.is_node_revealed(node_data.node_id)

    nodes_layer.add_child(node_instance)

func _get_node_scene(node_type: String) -> PackedScene:
    match node_type:
        "mining": return preload("res://scenes/nodes/mining_node.tscn")
        "outpost": return preload("res://scenes/nodes/outpost_node.tscn")
        "asteroid": return preload("res://scenes/nodes/asteroid_node.tscn")
        "graveyard": return preload("res://scenes/nodes/graveyard_node.tscn")
        "trader": return preload("res://scenes/nodes/trader_node.tscn")
        "colony": return preload("res://scenes/nodes/colony_node.tscn")
        "vault": return preload("res://scenes/nodes/vault_node.tscn")
        "exit": return preload("res://scenes/nodes/exit_node.tscn")
        _: return preload("res://scenes/nodes/mining_node.tscn")

# ============================================================
# FOG OF WAR
# ============================================================

func _on_node_discovered(node_id: String, _node_type: String) -> void:
    # Make node visible when discovered
    for node in nodes_layer.get_children():
        if node.get_meta("node_id") == node_id:
            node.visible = true
            break

# ============================================================
# PLAYER POSITION
# ============================================================

func _update_player_position() -> void:
    player_ship.position = SectorManager.player_position

func _process(_delta: float) -> void:
    _update_timer_display()

func _update_timer_display() -> void:
    var time_left := SectorManager.get_time_until_mothership()
    var minutes := int(time_left / 60)
    var seconds := int(time_left) % 60
    timer_label.text = "Mothership: %d:%02d" % [minutes, seconds]

    if time_left <= 30.0:
        timer_label.add_theme_color_override("font_color", Color.RED)
```

**Success Criteria**:
- Vertical scrolling with touch drag
- Spawns all nodes at correct positions
- Fog of war hides/reveals nodes
- Mothership timer counts down
- Under 250 lines

---

### Task 3: Base Node Component

**Priority**: HIGH (needed by all node types)

**File**: `scenes/nodes/base_node.tscn` + `scripts/nodes/base_node.gd`

**Purpose**: Reusable base component for all node types

#### Scene Structure

```
Area2D (base_node.gd)
├── CollisionShape2D (TouchArea)
├── Sprite2D (NodeIcon)
└── Label (NodeLabel)
```

#### Script Pattern

```gdscript
extends Area2D
class_name BaseNode

@export var node_type: String = "unknown"
@export var icon_texture: Texture2D

@onready var icon: Sprite2D = $NodeIcon
@onready var label: Label = $NodeLabel

var node_id: String = ""
var is_activated: bool = false

func _ready() -> void:
    input_event.connect(_on_input_event)

    if icon_texture:
        icon.texture = icon_texture

    label.text = node_type.capitalize()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
    if event is InputEventScreenTouch and event.pressed:
        _on_node_tapped()

func _on_node_tapped() -> void:
    if not is_activated:
        activate_node()

func activate_node() -> void:
    is_activated = true
    SectorManager.activate_node(node_id)
    print("[BaseNode] Activated: ", node_id)
```

**Success Criteria**:
- Detects touch input
- Emits activation signal
- Displays icon and label
- Under 100 lines

---

### Task 4: Specific Node Implementations

**Priority**: MEDIUM (one by one)

Create 8 node type scenes inheriting from BaseNode:

#### 4.1 Mining Node
**File**: `scenes/nodes/mining_node.tscn` + `scripts/nodes/mining_node.gd`

```gdscript
extends BaseNode

var resource_type: String = "metal"  # metal, crystals, fuel, wildcard
var resource_amount: int = 50

func _ready() -> void:
    super._ready()
    node_type = "mining"
    _randomize_resource()

func _randomize_resource() -> void:
    var types := ["metal", "crystals", "fuel"]
    resource_type = types[randi() % types.size()]
    resource_amount = randi_range(30, 100)

func activate_node() -> void:
    super.activate_node()
    _deploy_miners()

func _deploy_miners() -> void:
    # TODO: Open mining UI (Phase 4)
    # For now, instant reward
    match resource_type:
        "metal": ResourceManager.add_metal(resource_amount, "mining")
        "crystals": ResourceManager.add_crystals(resource_amount, "mining")
        "fuel": ResourceManager.add_fuel(resource_amount, "mining")

    print("[MiningNode] Mined %d %s" % [resource_amount, resource_type])
```

#### 4.2 Outpost Node
**File**: `scenes/nodes/outpost_node.tscn` + `scripts/nodes/outpost_node.gd`

```gdscript
extends BaseNode

var has_enemies: bool = false
var reward_metal: int = 0
var reward_crystals: int = 0

func _ready() -> void:
    super._ready()
    node_type = "outpost"
    _generate_outpost()

func _generate_outpost() -> void:
    has_enemies = randf() < 0.3  # 30% chance of enemies

    if has_enemies:
        reward_metal = randi_range(50, 150)
        reward_crystals = randi_range(20, 60)
    else:
        reward_metal = randi_range(20, 50)
        reward_crystals = randi_range(10, 30)

func activate_node() -> void:
    super.activate_node()

    if has_enemies:
        _trigger_combat()
    else:
        _grant_reward()

func _grant_reward() -> void:
    ResourceManager.add_metal(reward_metal, "outpost")
    ResourceManager.add_crystals(reward_crystals, "outpost")
    print("[Outpost] Scavenged: %d metal, %d crystals" % [reward_metal, reward_crystals])

func _trigger_combat() -> void:
    # TODO: Launch combat (Phase 3)
    print("[Outpost] Enemy encounter! (Combat not implemented yet)")
```

#### 4.3-4.8 Other Nodes
Create similar implementations for:
- `asteroid_node.gd` - Quick metal/crystal gathering
- `graveyard_node.gd` - Salvage materials and ship parts
- `trader_node.gd` - Shop encounter (placeholder for Phase 4)
- `colony_node.gd` - Enemy spawner (placeholder for Phase 3)
- `vault_node.gd` - Powerful upgrades (placeholder for Phase 4)
- `exit_node.gd` - Sector exit portal

**Success Criteria per node**:
- Extends BaseNode
- Has unique behavior on activation
- Integrates with ResourceManager
- Under 150 lines each

---

### Task 5: Touch Controls & Movement

**Priority**: HIGH

**File**: Enhancement to `scripts/sector_map.gd`

#### Movement System

```gdscript
# Add to sector_map.gd

var selected_node_id: String = ""

func _on_node_tapped(node_id: String) -> void:
    if selected_node_id.is_empty():
        selected_node_id = node_id
        _show_movement_options(node_id)

func _show_movement_options(node_id: String) -> void:
    # TODO: Show UI popup with options:
    # - Move (normal movement)
    # - Jump (10 fuel)
    # - Cancel
    pass

func _on_move_to_node_pressed() -> void:
    if selected_node_id.is_empty():
        return

    var target_node := SectorManager.get_node_data(selected_node_id)
    SectorManager.move_player_to(target_node.position)
    _update_player_position()
    selected_node_id = ""

func _on_jump_to_node_pressed() -> void:
    if selected_node_id.is_empty():
        return

    var target_node := SectorManager.get_node_data(selected_node_id)
    if SectorManager.jump_to_position(target_node.position):
        _update_player_position()
        _refresh_fog_of_war()

    selected_node_id = ""
```

**Success Criteria**:
- Tap node to select
- Show movement UI
- Move or jump to selected node
- Update fog of war on movement

---

### Task 6: Node Data CSV (Future Expansion)

**Priority**: LOW (optional enhancement)

**File**: `data/sector_nodes.csv`

**Purpose**: Make node properties data-driven

#### CSV Structure

```csv
node_type,base_spawn_weight,reveal_radius,min_resources,max_resources,combat_chance
mining,30,0,30,100,0.0
outpost,25,0,20,150,0.3
asteroid,20,0,10,50,0.0
graveyard,10,0,50,200,0.2
trader,8,0,0,0,0.0
colony,5,200,0,0,1.0
vault,2,0,0,0,0.4
exit,1,0,0,0,0.0
```

**Success Criteria**:
- Loaded by DataManager
- SectorManager uses CSV for spawn weights
- Node behaviors reference CSV data

---

## Testing & Validation

### Phase 2 Acceptance Criteria

1. **Map Generation**
   - ✓ Generates 30-50 nodes per sector
   - ✓ One exit node guaranteed
   - ✓ Nodes positioned across 1080x5000 map
   - ✓ No overlapping nodes

2. **Camera & Scrolling**
   - ✓ Touch drag scrolls map vertically
   - ✓ Camera bounded to map limits
   - ✓ Smooth scrolling (no jitter)
   - ✓ Portrait orientation maintained

3. **Fog of War**
   - ✓ Only revealed nodes visible
   - ✓ Starting area revealed (300px radius)
   - ✓ New nodes revealed on movement
   - ✓ Jump reveals larger area (400px)

4. **Node Interactions**
   - ✓ Tap node to activate
   - ✓ Mining nodes grant resources
   - ✓ Outposts grant instant rewards
   - ✓ Exit node triggers sector transition (placeholder)

5. **Movement System**
   - ✓ Jump costs 10 fuel
   - ✓ Gravity assist costs 1 fuel, increases speed
   - ✓ Player position updates visually
   - ✓ Movement reveals fog of war

6. **Mothership Timer**
   - ✓ Timer counts down
   - ✓ Timer displayed in UI
   - ✓ Timer turns red at 30s
   - ✓ Mothership arrival time decreases per sector

7. **Resource Integration**
   - ✓ Resource display updates
   - ✓ EventBus signals fire on resource change
   - ✓ Fuel spending works
   - ✓ Cannot jump without fuel

8. **File Size Compliance**
   - ✓ SectorManager under 300 lines
   - ✓ sector_map.gd under 300 lines
   - ✓ All node scripts under 150 lines

### Manual Testing Checklist

```
[ ] Launch sector map scene
[ ] Verify 30+ nodes spawn
[ ] Drag to scroll map
[ ] Confirm only nearby nodes visible
[ ] Tap mining node - receive resources
[ ] Tap outpost node - receive reward
[ ] Jump to distant node - spend 10 fuel
[ ] Use gravity assist - spend 1 fuel
[ ] Watch mothership timer count down
[ ] Find exit node
[ ] Verify resource counts update
[ ] Check console for errors
```

---

## Next Steps After Phase 2

Once Phase 2 is complete and validated:

1. **Phase 3 Prep**: Begin combat system prototype
   - Combat grid (15×25)
   - Ship deployment
   - Wave spawning from CSV

2. **Expand Node Types**: Add missing functionality
   - Trader shop UI
   - Colony enemy patrols
   - Vault encounter system

3. **Polish Sector Visuals**: Enhance map aesthetics
   - Animated background (parallax stars)
   - Node type icons
   - Player ship sprite
   - Jump/movement animations

---

## ✅ NEW IMPLEMENTATION APPROACH (Updated Design)

### High-Level Implementation Order

#### 1. Core Infinite Scrolling (Week 1)
- **SectorManager Rewrite**:
  - Track `player_forward_distance` (cumulative distance traveled)
  - Track `player_lateral_position` (x-coordinate, 0-1080)
  - Track `current_speed_multiplier` (affects forward movement)
  - Implement `_process(delta)` to update forward distance each frame

- **Procedural Node Spawning**:
  - Spawn nodes when `player_forward_distance + 3000 > furthest_spawned_node`
  - Despawn nodes when `player_forward_distance - 500 > node.spawn_distance`
  - Track `active_nodes` array (currently in world)

- **Camera System**:
  - Camera locked to player ship horizontally
  - Camera auto-scrolls vertically based on forward movement
  - No touch-drag scrolling (removed)

#### 2. Player Controls & Movement (Week 1-2)
- **Swipe Steering**:
  - Detect swipe gestures (left/right)
  - Apply lateral acceleration: `accel = BASE_ACCEL / (1 + speed_multiplier * 0.5)`
  - Smoothly move `player_lateral_position` toward swipe direction
  - Auto-center when no input

- **Jump Mechanic**:
  - Button + directional swipe input
  - Instant horizontal movement (200-300px)
  - Fuel cost (10) + cooldown timer (10-15s)
  - Does NOT affect forward speed

- **Gravity Assist**:
  - Button opens speed adjustment UI
  - Options: "Speed Up (+20%)" or "Slow Down (-20%)"
  - Costs 1 fuel per use
  - Persists until next gravity assist

#### 3. Proximity & Node Interaction (Week 2)
- **Proximity Detection**:
  - Check distance between player position and all active nodes
  - Trigger popup when distance < 150-200px
  - **Pause game time** when popup visible (`get_tree().paused = true`)
  - Resume time when popup dismissed

- **Node Popups**:
  - Display node-specific action buttons
  - Player taps action or "Continue"
  - Node marks as activated if action taken

#### 4. Mothership Pursuit System (Week 2-3)
- **Mothership Spawn**:
  - Spawns at `player_forward_distance - spawn_distance` (8000px sector 1, decreases per sector)
  - Initial speed: 80% of player base speed
  - Acceleration rate: increases per sector

- **Pursuit Loop** (`_process`):
  - Update mothership position each frame
  - Check if `mothership_position >= player_forward_distance` (caught)
  - Update UI distance display
  - Trigger game over if caught

#### 5. Alien Sweep System (Week 3-4)
- **Sweep Generation**:
  - Timer-based spawning (60-180s intervals)
  - Choose random pattern (horizontal, diagonal, pincer, wave)
  - Spawn ahead of player at `player_forward_distance + 2500`

- **Sweep Movement**:
  - Each sweep has position, speed, direction
  - Update position in `_process`
  - Check collision with player ship
  - Trigger combat encounter on collision

### Key Architectural Changes

**SectorManager.gd Core Variables:**
```gdscript
var player_forward_distance: float = 0.0  # Cumulative distance traveled
var player_lateral_position: float = 540.0  # X-coordinate (0-1080)
var current_speed_multiplier: float = 1.0
var base_forward_speed: float = 100.0  # pixels/second

var mothership_position: float = -8000.0  # Negative = behind player
var mothership_speed: float = 80.0
var mothership_acceleration: float = 0.6

var active_nodes: Array[Dictionary] = []
var furthest_spawned_distance: float = 0.0

var jump_cooldown_remaining: float = 0.0
```

**Critical _process Loop:**
```gdscript
func _process(delta: float) -> void:
    # Update forward movement
    player_forward_distance += base_forward_speed * current_speed_multiplier * delta

    # Update mothership
    mothership_speed += mothership_acceleration * delta
    mothership_position += mothership_speed * delta

    # Check mothership caught player
    if mothership_position >= player_forward_distance:
        _game_over_mothership_caught()

    # Spawn nodes ahead
    if player_forward_distance + 3000 > furthest_spawned_distance:
        spawn_nodes_ahead(player_forward_distance + 3000)

    # Despawn nodes behind
    despawn_nodes_behind(player_forward_distance - 500)

    # Check proximity to active nodes
    var nearby_node = check_node_proximity()
    if nearby_node and not get_tree().paused:
        show_node_popup(nearby_node)
        get_tree().paused = true

    # Update jump cooldown
    if jump_cooldown_remaining > 0:
        jump_cooldown_remaining -= delta
```

---

## File Size Estimates (New Design)

- **SectorManager.gd**: ~350 lines (may need to split into AlienSweepManager)
- **sector_map.gd**: ~200 lines (simpler, no manual scrolling)
- **base_node.gd**: ~80 lines (proximity-based, simpler)
- **Node types**: ~60-80 lines each × 8 = ~560 lines
- **AlienSweepManager.gd** (if split): ~150 lines

**Total**: ~1,340 lines across 11-12 files (average 111 lines/file)

---

## NEW Completion Checklist (Updated Design)

### Core Infrastructure
- [ ] SectorManager.gd completely rewritten for infinite scrolling
- [ ] Autoload registered in project settings
- [ ] EventBus signals added (node_spawned, node_despawned, mothership_distance_updated, etc.)
- [ ] Forward distance tracking implemented
- [ ] Lateral position tracking implemented

### Infinite Scrolling System
- [ ] sector_map.tscn created with auto-following camera
- [ ] Background tiles infinitely (no seams)
- [ ] Nodes spawn ahead of player (2000-3000px)
- [ ] Nodes despawn behind player (500px)
- [ ] Camera follows player ship smoothly

### Player Controls
- [ ] Swipe left/right steering implemented
- [ ] Speed-based maneuverability formula works
- [ ] Ship auto-centers when no input
- [ ] Jump button + directional input
- [ ] Jump cooldown timer functional
- [ ] Gravity assist speed up/down menu

### Proximity Node System
- [ ] base_node.gd implements proximity detection
- [ ] Popup appears when within range
- [ ] **Time pauses** when popup visible
- [ ] Node-specific actions work
- [ ] "Continue" dismisses popup
- [ ] All 8 node type scenes created

### Mothership Pursuit
- [ ] Mothership spawns behind player at calculated distance
- [ ] Mothership accelerates over time
- [ ] Distance UI displays and updates
- [ ] Warning indicator at 2000px
- [ ] Game over when caught

### Alien Sweep System
- [ ] Sweep patterns generate (horizontal, diagonal, pincer, wave)
- [ ] Sweeps spawn on timer
- [ ] Warning appears 3-5s before sweep
- [ ] Collision detection works
- [ ] Combat triggers on collision

### Testing & Validation
- [ ] All tests from /docs/sector-exploration-module.md checklist pass
- [ ] No console errors
- [ ] Swipe controls responsive on mobile
- [ ] Speed affects maneuverability correctly
- [ ] Time pause works correctly
- [ ] Mothership pursuit feels challenging but fair

### Optional Enhancements
- [ ] sector_nodes.csv created (data-driven nodes)
- [ ] Alien sweep patterns from CSV
- [ ] Visual polish (sweep warnings, mothership visual)
- [ ] Audio cues (sweep approaching, mothership warning)

---

**Phase 2 Complete When**: All core checkboxes above are marked ✓ and the sector map is playable with resource gathering and movement.

**Estimated Effort**: 6-8 hours for experienced Godot developer

**Next Phase**: Phase 3 - Combat System Prototype (15×25 grid autobattler)
