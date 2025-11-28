# Animation Plan for Any-Type-7

This document defines animation patterns, visual effects, and hardpoint systems for the game's visual presentation.

## Unorganized notes

This section details notes left by the user since the last time you used this file.  They can be sorted when appropriate.

### Gravity Assisst

When the player performs a gravity assist, it is accompanied by an animation of the gravity assist. When the actual gravity ssist occurs, there will be different animations depending on speed. 
- First gravity assist: the ship will orbit and then slingshot around the planet in a visually pleasing camera based .  The point is 
- further gravity assists simply place a  visuall speed effect aroudn the ship 


---

## Projectile Hardpoint System

### Overview

Ships fire projectiles from hardpoints based on their `projectile_count` stat. The hardpoint selection system ensures **visual symmetry** by using different hardpoint sets for odd vs even projectile counts.

### Hardpoint Naming Convention

Ships have two sets of projectile hardpoints:
- **Odd Row Hardpoints**: `odd_row_projectile_1`, `odd_row_projectile_2`, `odd_row_projectile_3`
- **Even Row Hardpoints**: `even_row_projectile_1`, `even_row_projectile_2`

**Design Principle:**
- Odd-numbered projectile counts include a **center projectile** (from odd_row_projectile_1)
- Even-numbered projectile counts use **symmetrical pairs** (from even_row hardpoints)
- This maintains visual balance regardless of projectile count

---

### Projectile Count → Hardpoint Mapping

| Projectile Count | Hardpoints Used | Visual Layout |
|------------------|-----------------|---------------|
| **1** | `odd_row_projectile_1` | Single center projectile |
| **2** | `even_row_projectile_1`<br>`even_row_projectile_2` | Symmetrical pair (left/right) |
| **3** | `odd_row_projectile_1`<br>`even_row_projectile_1`<br>`even_row_projectile_2` | Center + symmetrical pair |
| **4** | `odd_row_projectile_1`<br>`odd_row_projectile_2`<br>`even_row_projectile_1`<br>`even_row_projectile_2` | Two symmetrical pairs |
| **5** | `odd_row_projectile_1`<br>`odd_row_projectile_2`<br>`odd_row_projectile_3`<br>`even_row_projectile_1`<br>`even_row_projectile_2` | Three center + one pair |

---

### Visual Diagrams

#### 1 Projectile (Center Shot)
```
        Ship Front
            |
            *  ← odd_row_projectile_1
            |
```

#### 2 Projectiles (Symmetrical Pair)
```
        Ship Front
           / \
          *   *  ← even_row_projectile_1, even_row_projectile_2
         /     \
```

#### 3 Projectiles (Center + Pair)
```
        Ship Front
         / | \
        *  *  *  ← even_row_1, odd_row_1, even_row_2
       /   |   \
```

#### 4 Projectiles (Two Pairs)
```
        Ship Front
       / /   \ \
      * *     * *  ← even_row_1, odd_row_1, odd_row_2, even_row_2
     / /       \ \
```

#### 5 Projectiles (Three Center + Pair)
```
        Ship Front
     / / |  | \ \
    * * *  *  * *  ← even_row_1, even_row_2, odd_row_1, odd_row_2, odd_row_3
   / / |    | \ \
```

---

### Implementation Logic

**GDScript Example:**

```gdscript
# Ship.gd - Projectile spawn logic

func spawn_projectiles() -> void:
    var projectile_count = stats.projectile_count
    var hardpoints = get_active_hardpoints(projectile_count)

    for hardpoint in hardpoints:
        spawn_projectile_at(hardpoint)

func get_active_hardpoints(count: int) -> Array[Marker2D]:
    var hardpoints: Array[Marker2D] = []

    match count:
        1:
            hardpoints.append($Hardpoints/OddRow1)
        2:
            hardpoints.append($Hardpoints/EvenRow1)
            hardpoints.append($Hardpoints/EvenRow2)
        3:
            hardpoints.append($Hardpoints/OddRow1)
            hardpoints.append($Hardpoints/EvenRow1)
            hardpoints.append($Hardpoints/EvenRow2)
        4:
            hardpoints.append($Hardpoints/OddRow1)
            hardpoints.append($Hardpoints/OddRow2)
            hardpoints.append($Hardpoints/EvenRow1)
            hardpoints.append($Hardpoints/EvenRow2)
        5:
            hardpoints.append($Hardpoints/OddRow1)
            hardpoints.append($Hardpoints/OddRow2)
            hardpoints.append($Hardpoints/OddRow3)
            hardpoints.append($Hardpoints/EvenRow1)
            hardpoints.append($Hardpoints/EvenRow2)

    return hardpoints
```

---

### Ship Scene Structure

All ship scenes should include these hardpoint nodes:

```
Ship (Node2D)
├── Sprite (Sprite2D)
├── Hardpoints (Node2D)
│   ├── OddRow1 (Marker2D)
│   ├── OddRow2 (Marker2D)
│   ├── OddRow3 (Marker2D)
│   ├── EvenRow1 (Marker2D)
│   └── EvenRow2 (Marker2D)
├── ExhaustPoint (Marker2D)
│   └── ExhaustSprite (AnimatedSprite2D)
│       └── ExhaustController.gd (controls thrust level)
└── CollisionShape (CollisionShape2D)
```

**Hardpoint Positioning Guidelines:**
- **OddRow1**: Center line, furthest forward (primary weapon)
- **OddRow2**: Center line, mid position
- **OddRow3**: Center line, rearmost position
- **EvenRow1**: Left side, symmetrical to EvenRow2
- **EvenRow2**: Right side, symmetrical to EvenRow1

---

### CSV Integration

The `ship_visuals_database.csv` should include columns for all hardpoint coordinates:

```csv
ship_id, ship_file,
odd_row_projectile_1_x, odd_row_projectile_1_y,
odd_row_projectile_2_x, odd_row_projectile_2_y,
odd_row_projectile_3_x, odd_row_projectile_3_y,
even_row_projectile_1_x, even_row_projectile_1_y,
even_row_projectile_2_x, even_row_projectile_2_y,
exhaust_point_x, exhaust_point_y,
center_point_x, center_point_y
```

**Example Row:**
```csv
basic_interceptor, basic_interceptor.png,
40, 24,    # odd_row_projectile_1 (center, front)
36, 24,    # odd_row_projectile_2 (center, mid)
32, 24,    # odd_row_projectile_3 (center, rear)
38, 20,    # even_row_projectile_1 (left)
38, 28,    # even_row_projectile_2 (right)
-8, 24,    # exhaust_point
32, 24     # center_point
```

---

## Combat Animation Sequences

### Ship Attack Animation

1. **Wind-up** (0.1s)
   - Slight scale increase (1.0 → 1.05)
   - Tint to weapon color

2. **Fire** (0.05s)
   - Muzzle flash at active hardpoints
   - Recoil (move back 2-4 pixels)
   - Spawn projectiles from hardpoints
   - Play weapon sound

3. **Recovery** (0.15s)
   - Return to idle position
   - Scale back to normal (1.05 → 1.0)
   - Tint fade out

**Total Duration:** ~0.3s (matches attack speed calculation)

---

### Projectile Animation

1. **Spawn**
   - Fade in (0s → 0.05s)
   - Small scale pulse (0.8 → 1.0)
   - Initial velocity from ship forward direction

2. **Travel**
   - Constant forward movement
   - Rotation to match direction
   - Trail effect (particle or AnimatedSprite2D)

3. **Impact**
   - On hit: Impact particle + damage number
   - On miss: Fade out at max range
   - Despawn immediately after impact

---

### Ship Hit Reaction

**Shield Hit:**
1. Shield bubble flash (0.1s)
2. Ripple effect at impact point
3. No ship movement

**Hull Hit:**
1. Flash white (0.08s)
2. Knockback (2-4 pixels back)
3. Damage number floats up
4. Screen shake (if player ship, intensity based on damage)

**Critical Hit:**
1. Flash yellow/orange (0.1s)
2. Larger knockback (4-8 pixels)
3. Larger damage number with "CRIT!" text
4. Stronger screen shake

---

### Ship Destruction Sequence

1. **Death Flash** (0.1s)
   - Flash red
   - Freeze frame (time scale = 0 for 0.05s)

2. **Explosion** (0.5s)
   - Spawn explosion particle system
   - Ship sprite fragments (4-8 pieces)
   - Fragments fly outward with spin
   - Screen shake (if player ship)

3. **Fade Out** (0.3s)
   - All fragments fade to transparent
   - Explosion particle fades
   - Despawn ship node

**Total Duration:** ~0.9s

---

## Status Effect Visual Indicators

### Elemental Effects

| Effect | Visual | Animation |
|--------|--------|-----------|
| **Burn** | Orange flames around ship | Flicker, rise upward |
| **Freeze** | Blue ice crystals on ship | Gentle float, sparkle |
| **Static** | Yellow lightning sparks | Rapid blink, arc between points |
| **Acid** | Green bubbling liquid | Drip down, dissolve effect |
| **Gravity** | Purple gravity waves | Pulse inward toward ship |

**Stacking Visual:**
- 1 stack: Small effect, subtle
- 2 stacks: Medium effect, visible
- 3 stacks: Large effect, very prominent

### Control Effects

| Effect | Visual | Animation |
|--------|--------|-----------|
| **Stun** | Yellow spirals above ship | Rotate around head |
| **Blind** | White flash overlay | Flicker rapidly |
| **Malfunction** | Sparking circuits | Random sparks on hull |
| **Energy Drain** | Blue energy siphon | Stream away from ship |
| **Pinned Down** | Chains/anchors | Weighted to position |

---

## Exhaust Animations

Exhaust animations change based on ship state, with **dynamic thrust level** determining exhaust sprite visibility.

### Dynamic Exhaust Sizing System

Exhaust sprites have **variable visibility** based on thrust requirements:

| Thrust Level | Visibility | Use Case | Visual Description |
|--------------|------------|----------|-------------------|
| **Idle** | 10% | Ship not moving | Minimal exhaust, just a glow |
| **Moving** | 50% | Standard movement | Half exhaust visible, medium thrust |
| **Full Thrust** | 100% | Abilities, boost, max speed | Full exhaust trail visible |

**Implementation Method:**

Use AnimatedSprite2D with **region_rect** or **scale** to control visibility:

```gdscript
# ExhaustController.gd

@onready var exhaust_sprite: AnimatedSprite2D = $ExhaustSprite
var full_exhaust_height: float = 64.0  # Full sprite height

func set_thrust_level(level: float) -> void:
    # level: 0.1 (idle), 0.5 (moving), 1.0 (full thrust)
    var visible_height = full_exhaust_height * level

    # Option 1: Use region_rect (if using static Sprite2D)
    exhaust_sprite.region_rect = Rect2(
        0, full_exhaust_height - visible_height,  # Start from bottom
        exhaust_sprite.texture.get_width(),
        visible_height
    )

    # Option 2: Use scale + offset (if using AnimatedSprite2D)
    exhaust_sprite.scale.y = level
    exhaust_sprite.offset.y = (full_exhaust_height * (1.0 - level)) / 2.0
```

**Visual Result:**
```
Idle (10%):          Moving (50%):        Full Thrust (100%):
    ____                 ____                    ____
   | ▓▓ |               | ▓▓ |                  | ▓▓ |
    ~~~~                | ▓▓ |                  | ▓▓ |
                        | ░░ |                  | ▓▓ |
                        | ░░ |                  | ▓▓ |
                         ~~~~                   | ░░ |
                                                | ░░ |
                                                | ░░ |
                                                 ~~~~
```

### Idle State (10% Thrust)
- Slow exhaust loop (8 FPS)
- Minimal particle emission
- **10% of exhaust sprite visible** (just the glow at engine)
- Gentle bob animation (ship moves ±1 pixel vertically)

### Moving State (50% Thrust)
- Fast exhaust loop (16 FPS)
- Increased particle emission (2x)
- **50% of exhaust sprite visible** (medium-length trail)
- Ship tilts forward slightly (3-5 degrees)
- Faster bob animation

### Combat State - Attacking (50% Thrust)
- Maintain movement thrust level
- Rapid frame rate (20 FPS)
- Bright glow increase
- **50% exhaust visibility** (standard combat)

### Full Thrust State (100% Thrust)
Activated during:
- Ability activation (energy discharge)
- Speed boost abilities
- Evasive maneuvers
- Retreat sequence

Visuals:
- **100% of exhaust sprite visible** (full trail)
- Maximum frame rate (24 FPS)
- Brightest glow + additional particles
- Afterburner effect (streaks behind ship)

### Damaged State (<30% HP)
- Exhaust flickers/sputters
- Black smoke particles mixed in
- Irregular timing
- **Thrust level fluctuates** (10% ↔ 30% randomly)
- Damaged engine effect

---

## Ability Activation Animations

### Generic Ability Pattern

1. **Charge** (0.3-0.5s based on Frequency stat)
   - Ship glows with ability element color
   - Pulsing effect (brightness increases)
   - Particle buildup around ship
   - Energy sound effect

2. **Activate** (0.1s)
   - Bright flash
   - Shockwave emanates from ship
   - Ability effect spawns
   - Activation sound effect

3. **Cooldown Visual**
   - Radial progress indicator over ship (optional)
   - Faded ability icon

---

## Combo Detonation Effects

When elemental triggers detonate stacked effects:

### Explosive Trigger
- Large explosion at target
- All element particles burst outward
- Multi-colored flash (all present elements)
- Screen shake
- Damage numbers for each element

### Element-Specific Triggers

**Fire Trigger (on Burn stacks):**
- Fireball explosion
- Intense orange flash
- Fire particles scatter
- Heat wave distortion

**Ice Trigger (on Freeze stacks):**
- Ice shatter effect
- Blue/white flash
- Ice shard projectiles fly outward
- Crystalline sound effect

**Lightning Trigger (on Static stacks):**
- Chain lightning arcs
- Yellow/white flash
- Electric crackle particles
- Electrical discharge sound

**Acid Trigger (on Acid stacks):**
- Corrosive splash
- Green/yellow flash
- Bubbling liquid particles
- Hissing/melting sound

**Gravity Trigger (on Gravity stacks):**
- Implosion effect (particles pulled inward, then explode)
- Purple/black flash
- Gravitational distortion wave
- Deep bass sound

---

## Performance Considerations

### Mobile Optimization Rules

1. **Particle Limits**
   - Max 50 particles per system
   - Use GPUParticles2D (not CPU)
   - One-shot particles auto-despawn
   - Pool reusable particle systems

2. **Animation Frame Rates**
   - Exhaust loops: 8-16 FPS (not 60)
   - Status effect indicators: 12 FPS
   - Combat animations: 20-30 FPS for key frames

3. **Sprite Atlas**
   - Batch all projectiles into single atlas
   - Batch all ship sprites into atlas
   - Reduces draw calls significantly

4. **Effect Pooling**
   - Pool damage numbers (create 20, reuse)
   - Pool projectiles (create 50, reuse)
   - Pool explosion effects (create 10, reuse)

5. **Viewport Culling**
   - Only animate ships on screen
   - Disable particle systems for off-screen ships
   - Use VisibleOnScreenNotifier2D

---

## Animation States Priority

When multiple animations compete (e.g., ship is moving AND attacking):

**Priority Order (highest to lowest):**
1. Death/Destruction
2. Hit Reaction
3. Ability Activation
4. Attack
5. Movement
6. Idle

**Blending Rules:**
- Movement + Attack: Blend (show both)
- Hit Reaction + Attack: Hit reaction interrupts attack
- Death: Cancels all other animations

---

## Future Animation Considerations

### Wave 2 Features (Post-MVP)
- Ship warp-in effects (sector deployment)
- Shield recharge animations (between waves)
- Repair drone animations (if implemented)
- Victory/defeat animations (end of combat)
- Ship upgrade installation animations (hangar)

### Polish Phase
- Screen space effects (chromatic aberration on crit)
- Time slowdown on player ship death
- Dynamic camera shake based on action intensity
- Background parallax effects
- Star field particle systems

---

## References

- Ship visual data: `data/ship_visuals_database.csv`
- Ship stats (projectile_count): `data/ship_stat_database.csv`
- Ability visual effects: `data/ability_database.csv`
- Status effects: `data/status_effects.csv`
- Combat formulas: `docs/combat-formulas.md`

**For Animation & Visuals Specialist Agent:**
This document should be referenced when setting up ship scenes, projectile systems, and combat visual effects. The projectile hardpoint mapping is critical for maintaining visual symmetry.
