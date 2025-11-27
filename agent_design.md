# Agent Design for Any-Type-7

## Overview

This document defines **3 specialized AI agents** for the Any-Type-7 project. Each agent has deep expertise in a specific domain where specialized knowledge provides significant value. For general programming tasks (autoloads, EventBus, architecture), work directly with Claude using the project constraints documented in CLAUDE.md.

### Why 3 Agents Instead of 14?

**The Problem with Over-Specialization:**
- Too many agents to remember and manage
- Unclear boundaries between agents
- Maintenance overhead
- Most tasks don't need hyper-specialized assistance

**The 3-Agent Solution:**
- **Mobile UI Specialist** - UI/UX patterns are complex and mobile-specific
- **CSV & Data Integration Specialist** - Data schemas and formulas require precision
- **Animation & Visuals Specialist** - Sprite/animation setup has lots of domain-specific knowledge

**For everything else:** Use Claude directly with CLAUDE.md constraints (300-line rule, EventBus, CSV-driven, etc.)

---

## The Three Specialized Agents

### 1. Mobile UI Specialist

**Role:** All UI/UX concerns for mobile portrait layout

**When to Use This Agent:**
- Creating new UI screens or components
- Designing touch-optimized controls
- Setting up scene hierarchies with Control nodes
- Implementing gesture handling (tap, drag, long-press, swipe)
- Ensuring safe area compliance (notches, navigation bars)
- Building responsive portrait layouts

**Expertise:**
- Portrait orientation (1080x2340, 19.5:9 aspect ratio)
- Touch-first input design
- Godot Control nodes (MarginContainer, VBoxContainer, ScrollContainer, etc.)
- Anchoring and responsive layouts
- Safe area handling
- Single-handed operation patterns
- Visual feedback for touch interactions

**Key Responsibilities:**

1. **Scene Structure Creation**
   - Generate .tscn files with proper node hierarchies
   - Configure Control node anchors for portrait orientation
   - Set up responsive layouts that adapt to different portrait aspect ratios
   - Ensure minimum touch target sizes (44x44 dp)

2. **Touch Gesture Implementation**
   - Tap: Instant selection/activation
   - Long-press: Context actions (retreat confirmation, hold to deploy)
   - Drag: Ship placement, equipment swapping, map panning
   - Swipe: Screen transitions, quick actions
   - Pinch: Zoom (sector map)

3. **Safe Area Compliance**
   - Margin containers for screen cutouts
   - Navigation bar avoidance
   - Thumb-reachable zones (bottom 40% of screen)
   - One-handed operation where possible

4. **UI Component Templates**
   - Full-screen UI container (with safe areas)
   - Scrollable lists (ship roster, upgrades, inventory)
   - Modal dialogs (confirmation, info, choices)
   - Touch buttons (large, clear, with visual feedback)
   - Draggable items (ship cards, equipment)
   - Progress indicators (wave timer, resource gathering)

**Constraints:**
- Portrait orientation only (1080x2340)
- Minimum touch target: 44x44 dp
- Safe area margins: 16dp from edges
- Thumb-reachable priority (important controls at bottom)
- Clear visual feedback for all interactions
- No landscape support

**Usage Example:**

```
User: "Create the combat tactical phase UI where players deploy ships to lanes"

Mobile UI Specialist Agent:
[Analyzes requirements]

Creating combat_tactical_ui.tscn with portrait layout:

1. MarginContainer (root, safe area margins)
   - Top margin: 44dp (status bar)
   - Bottom margin: 24dp (navigation bar)

2. VBoxContainer (main layout)
   - Combat grid (top 60%, scrollable vertically)
   - Ship roster (bottom 40%, horizontal scroll)
   - Deploy button (bottom-center, 88x44 dp)

3. Touch interactions:
   - Drag ship from roster → Drop on grid lane
   - Visual feedback: Semi-transparent ship follows finger
   - Snap-to-lane on release
   - Invalid placement: Red tint + snap back to roster
   - Valid placement: Green flash + sound

4. GDScript for touch handling:
   - _gui_input() for drag detection
   - Custom drag data with ship_id
   - Lane collision detection
   - Visual feedback states

[Generates .tscn file + combat_tactical_ui.gd script <200 lines]
```

---

### 2. CSV & Data Integration Specialist

**Role:** All data/CSV validation and integration

**When to Use This Agent:**
- Validating CSV data against schemas
- Creating DataManager query methods
- Checking combat formula implementations
- Verifying data integrity and cross-references
- Setting up CSV loading patterns
- Testing formula edge cases

**Expertise:**
- All CSV schemas (ship_stat_database, ability_database, etc.)
- 17 ship stat system
- Combat formulas (hit chance, crit, armor, DPS)
- Elemental combo system and damage calculation
- Status effect stacking rules
- DataManager query patterns
- Data caching and optimization

**Key Responsibilities:**

1. **CSV Schema Validation**
   - Verify all required columns present
   - Check data types (int, float, string)
   - Validate value ranges (armor 0-75%, hit chance 5-95%)
   - Ensure IDs are unique
   - Cross-reference validation (ship abilities exist in ability_database.csv)

2. **Combat Formula Validation**
   - Hit chance: `100% - (Evasion - Accuracy)` bounded [5%, 95%]
   - Crit chance: `Precision - Reinforced_Armor` bounded [0%, ∞]
   - Armor reduction: `Damage × (1 - Armor/100)` capped at 75% reduction
   - Combo damage: `Base × (1 + Stack_Count × 0.5)` max 3 stacks
   - DPS calculations and attack cooldowns

3. **DataManager Query Generation**
   - Create getter methods with type hints
   - Implement filtered queries (ships by class, abilities by trigger)
   - Generate lookup methods with caching
   - Add validation and error handling

4. **Data Integrity Checks**
   - Ship visuals reference valid ship IDs
   - Abilities reference valid trigger types
   - Upgrades target valid stat names
   - Blueprint requirements are achievable
   - Elemental combos use valid element types

**Constraints:**
- Must reference CSV files in `/data/`
- All formulas must match `docs/combat-formulas.md`
- Validate against documented bounds (5-95%, 75% cap, max 3 stacks)
- Type safety (int vs float conversions)
- Return empty Array/Dictionary if no results (never null)

**Key Formulas:**

```gdscript
# Hit Chance (5-95% bounds)
func calculate_hit_chance(accuracy: int, evasion: int) -> float:
    return clamp(100.0 - (evasion - accuracy), 5.0, 95.0)

# Crit Chance (0% minimum)
func calculate_crit_chance(precision: int, reinforced_armor: int) -> float:
    return max(0.0, precision - reinforced_armor)

# Armor Damage Reduction (75% max)
func apply_armor_reduction(damage: float, armor: int) -> float:
    var reduction_percent = min(armor, 75.0) / 100.0
    return damage * (1.0 - reduction_percent)

# Elemental Combo Damage
func calculate_combo_damage(base_damage: int, stack_count: int) -> int:
    return base_damage * (1.0 + stack_count * 0.5)
```

**Usage Example:**

```
User: "Validate my ship_stat_database.csv"

CSV & Data Integration Specialist Agent:
[Reads CSV and schema documentation]

Validation Report for ship_stat_database.csv:

✅ Schema: All 17 stat columns present
✅ Data Types: All values correctly typed (int/float)
✅ Unique IDs: 14 unique ship IDs, no duplicates

⚠️ Warnings:
- Row 8 (havoc_fighter): Accuracy 110 exceeds typical range (0-100)
  - Not an error (formulas handle it), but unusual

❌ Errors:
- Row 12 (shield_frigate): armor = 85
  - Exceeds 75% damage reduction cap
  - Suggestion: Reduce to 75 or document intentional overcapping

Cross-Reference Checks:
✅ All ship_ability values exist in ability_database.csv
⚠️ 3 ships reference visuals not yet in ship_visuals_database.csv
  - basic_cruiser, stealth_frigate, assault_gunship

Recommendation: Fix armor value on Row 12, add missing ship visuals
```

---

### 3. Animation & Visuals Specialist

**Role:** All sprite, animation, and visual effects

**When to Use This Agent:**
- Setting up ship sprites with hardpoints
- Creating combat animations (movement, attacks, destruction)
- Implementing particle effects (exhausts, explosions, impacts)
- Adding visual feedback (damage numbers, hit flashes, status effect indicators)
- Optimizing sprite atlases for mobile
- Configuring AnimatedSprite2D and AnimationPlayer

**Expertise:**
- Ship visuals database (hardpoint coordinates for weapons/exhausts)
- AnimatedSprite2D setup and frame timing
- AnimationPlayer for complex sequences
- Particle systems (GPUParticles2D for mobile)
- Visual effects optimization for GL Compatibility renderer
- Sprite atlas creation and batching
- Visual feedback patterns (screen shake, hit pause, color flashes)

**Key Responsibilities:**

1. **Ship Sprite Setup**
   - Load sprites from `assets/ships/`
   - Parse `ship_visuals_database.csv` for hardpoint coordinates
   - Position weapon hardpoints (weapon_point_x, weapon_point_y)
   - Position exhaust hardpoints (exhaust_point_x, exhaust_point_y)
   - Set sprite center point (center_point_x, center_point_y)
   - Configure tint colors (primary_color, secondary_color, accent_color)

2. **Combat Animations**
   - Ship movement along lanes (smooth interpolation)
   - Attack animations (muzzle flash, recoil)
   - Hit reactions (flash white, screen shake)
   - Destruction sequences (explosion, debris)
   - Shield impact effects (bubble distortion)
   - Ability activation (charge-up, release)

3. **Particle Systems**
   - Exhaust trails (load from `assets/exhausts/`, reference exhaust_file in CSV)
   - Projectiles (load from `assets/projectiles/`)
   - Explosions (debris, fire, smoke)
   - Status effect indicators (burn = flames, freeze = ice shards, static = sparks)
   - Impact effects (shield hit, armor hit, hull hit)

4. **Visual Feedback**
   - Damage numbers (float up, fade out)
   - Combo indicators (element icons, multiplier text)
   - Status effect stacks (icon + counter)
   - Ability cooldown overlay (radial progress)
   - Lane highlighting (deployment, enemy spawn)

5. **Mobile Optimization**
   - Use GPUParticles2D (not CPUParticles2D)
   - Limit particle counts (max 50 per system)
   - Sprite atlases for ship/projectile batching
   - Optimize for GL Compatibility renderer
   - Avoid expensive shaders (prefer simple color modulation)

**Constraints:**
- Must reference `ship_visuals_database.csv` for hardpoint data
- Optimize for GL Compatibility (mobile) renderer
- Particle count limits (performance)
- Use sprite atlases where possible
- Frame timing at 60 FPS target

**Ship Visuals Database Schema:**

```csv
ship_id, ship_file, exhaust_file, weapon_point_x, weapon_point_y,
exhaust_point_x, exhaust_point_y, center_point_x, center_point_y,
primary_color, secondary_color, accent_color, scale
```

**Usage Example:**

```
User: "Set up the basic_interceptor ship sprite with its exhaust and weapon hardpoints"

Animation & Visuals Specialist Agent:
[Reads ship_visuals_database.csv for basic_interceptor]

Creating ship sprite setup for basic_interceptor:

1. Sprite Configuration:
   - Sprite: assets/ships/basic_interceptor.png
   - Center point: (32, 24) - from CSV center_point_x/y
   - Scale: 1.0
   - Primary color: #4A9EFF (blue)

2. Weapon Hardpoint:
   - Position: (40, 24) - from CSV weapon_point_x/y
   - Node: Marker2D named "WeaponPoint"
   - Purpose: Projectile spawn position

3. Exhaust Hardpoint:
   - Position: (-8, 24) - from CSV exhaust_point_x/y
   - Node: Marker2D named "ExhaustPoint"
   - Exhaust sprite: assets/exhausts/s_blue_single_exhaust/
   - AnimatedSprite2D: 4 frames at 12 FPS (looping)

4. Scene Structure:
   - Ship (Node2D)
     - Sprite (Sprite2D) - ship visual
     - WeaponPoint (Marker2D)
     - ExhaustPoint (Marker2D)
       - ExhaustSprite (AnimatedSprite2D)
     - CollisionShape (for selection)

[Generates basic_interceptor.tscn + setup script]

5. Animation States:
   - idle: Exhaust loop + gentle bob
   - moving: Faster exhaust + tilt forward slightly
   - attacking: Muzzle flash at WeaponPoint + recoil
   - hit: Flash white (0.1s)
   - destroyed: Explosion particle + fade out
```

---

## Project Constraints (For General Claude Assistance)

When working with Claude directly (not using specialized agents), these constraints are always enforced:

### Architecture Rules

1. **300-Line Rule** (CRITICAL)
   - Maximum 300 lines per .gd file
   - If approaching limit, refactor into smaller components
   - Extract data to CSV files
   - Use helper functions in utility scripts

2. **EventBus Signal Pattern**
   - All cross-system communication via EventBus signals
   - No direct script dependencies between managers
   - Format: `{system}_{event}_{detail}`
   - Example: `EventBus.combat_ship_destroyed.emit(ship_id)`

3. **Singleton Autoload Pattern**
   - All managers are autoload singletons
   - Single responsibility per manager
   - Named in PascalCase (EventBus, DataManager, CombatManager)

4. **CSV-Driven Data**
   - Never hardcode game data in scripts
   - All content in `/data/*.csv` files
   - Load via DataManager
   - Cache for performance

5. **Mobile-First Design**
   - Portrait orientation only (1080x2340)
   - Touch-first input (tap, drag, long-press)
   - Optimize for GL Compatibility renderer
   - Battery efficiency (limit updates, batch operations)

6. **GDScript Best Practices**
   - Type hints on all parameters and return values
   - Docstrings for public methods
   - `class_name` declarations for autoloads
   - Signal definitions at top of file

---

## When to Use Which Agent

### Use **Mobile UI Specialist** when:
- Creating or modifying UI screens
- Implementing touch controls
- Setting up scene hierarchies
- Designing responsive portrait layouts
- Adding gesture handling
- Ensuring safe area compliance

### Use **CSV & Data Integration Specialist** when:
- Validating CSV data
- Creating DataManager queries
- Implementing combat formulas
- Checking data integrity
- Cross-referencing data
- Testing formula edge cases

### Use **Animation & Visuals Specialist** when:
- Setting up ship sprites
- Creating combat animations
- Implementing particle effects
- Adding visual feedback
- Positioning hardpoints
- Optimizing for mobile rendering

### Use **Claude Directly** when:
- Creating autoload singletons
- Implementing EventBus signals
- Writing game logic (managers, systems)
- Refactoring code to meet 300-line limit
- General programming tasks
- Architectural decisions

---

## Agent Invocation Patterns

### Sequential Workflow

For tasks requiring multiple agents in order:

```
User: "Create the ship deployment system for combat"

1. [Mobile UI Specialist] - Create tactical deployment UI scene
   → Generates combat_deployment.tscn with lane grid + ship roster

2. [CSV & Data Integration Specialist] - Add ship data queries
   → Generates DataManager methods: get_available_ships(), get_ship_stats()

3. [Animation & Visuals Specialist] - Add ship visuals to deployment
   → Sets up ship sprites with preview animations

4. [Claude Direct] - Implement deployment logic
   → Creates DeploymentManager.gd with EventBus integration (<300 lines)
```

### Parallel Agent Use

Some agents can work simultaneously on different aspects:

```
User: "Set up the basic combat grid"

[Mobile UI Specialist] - Create grid scene layout
[Animation & Visuals Specialist] - Set up lane visual indicators

→ Both can work independently, results integrate later
```

### Combined Workflows

Real-world example combining all agents:

```
User: "Implement the combat system for Phase 3"

Phase 3.1 - Grid Setup:
  [Mobile UI Specialist] → Create 15×25 grid UI
  [Claude Direct] → Create CombatGrid.gd manager

Phase 3.2 - Ship System:
  [CSV & Data Integration] → Validate ship_stat_database.csv
  [Animation & Visuals] → Set up all 14 ship sprites
  [Claude Direct] → Create Ship.gd component (<300 lines)

Phase 3.3 - Combat Logic:
  [CSV & Data Integration] → Implement combat formulas
  [Claude Direct] → Create CombatManager.gd (<300 lines)
  [Claude Direct] → Create DamageCalculator.gd (<300 lines)

Phase 3.4 - Visual Feedback:
  [Animation & Visuals] → Add attack/hit/destruction animations
  [Mobile UI Specialist] → Add combat HUD (wave timer, retreat button)
```

---

## Usage Tips

1. **Be Specific**: When invoking an agent, clearly state what you need
   - Good: "Validate ship_stat_database.csv and check all formulas"
   - Bad: "Check my data"

2. **Reference Files**: Mention specific files or CSVs
   - Good: "Set up basic_interceptor sprite from ship_visuals_database.csv"
   - Bad: "Add the ship"

3. **Specify Constraints**: Remind agents of specific constraints if needed
   - "Create UI scene for portrait 1080x2340, safe area margins"

4. **Sequential Tasks**: Break complex tasks into steps
   - First agent → Second agent → Claude direct

5. **Iterate**: Agents can refine their output based on feedback
   - Agent provides solution → You give feedback → Agent revises

---

## Conclusion

This 3-agent system provides **focused expertise** where it matters most:
- **Mobile UI Specialist** handles the complex world of touch-optimized portrait layouts
- **CSV & Data Integration Specialist** ensures data integrity and formula accuracy
- **Animation & Visuals Specialist** brings the game to life with sprites and effects

For everything else, work directly with Claude using the well-documented project constraints in CLAUDE.md. This balance keeps things **simple, practical, and maintainable** while providing deep expertise where you need it most.

Ready to build! 🚀
