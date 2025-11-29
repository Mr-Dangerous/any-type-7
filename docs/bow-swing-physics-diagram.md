# Bow Swing Physics - Visual Diagram

## System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                   BOW SWING ROTATION SYSTEM                 │
└─────────────────────────────────────────────────────────────┘

INPUT (Player)          PHYSICS (Movement)        VISUAL (Rotation)
     │                        │                         │
     ↓                        ↓                         ↓
 Swipe Left/Right      Lateral Velocity      Spring-Based Rotation
     │                        │                         │
     │                        │                         │
     └────────→ Affects ──────┘                         │
                               │                        │
                               └──→ Drives ─────────────┘
```

## Direction Change Sequence

### Frame-by-Frame Breakdown

```
TIME: t=0 (Moving Right)
═══════════════════════════════════════════════════════════
Velocity:  [────────→]  +300 px/s
Rotation:  [───→]        +11° (aligned with velocity)
Status:    Stable state, no direction change


TIME: t=0.1 (Player taps Left)
═══════════════════════════════════════════════════════════
Velocity:  [──────→]    +200 px/s  (slowing down)
Rotation:  [────→]      +13° (still right, slight lag)
Status:    Fighting momentum, rotation lags behind


TIME: t=0.2 (Velocity crosses zero)
═══════════════════════════════════════════════════════════
Velocity:  [──→]        +50 px/s  (nearly stopped)
Rotation:  [──→]        +8° (catching up)
Status:    No overshoot yet (waiting for sign change)


TIME: t=0.25 (DIRECTION CHANGE DETECTED!)
═══════════════════════════════════════════════════════════
Velocity:  [←──]        -100 px/s  ← SIGN CHANGED!
Rotation:  [←──────────] -25° ← OVERSHOOT TRIGGERED!
           (target is only -10°, but multiplied by 2.5x)
Status:    ✓ Overshoot applied (dramatic swing to left)


TIME: t=0.4 (Spring pulling back)
═══════════════════════════════════════════════════════════
Velocity:  [←────]      -200 px/s
Rotation:  [←────]      -18° (spring force pulling toward -13° target)
Status:    Returning to equilibrium


TIME: t=0.6 (First bounce)
═══════════════════════════════════════════════════════════
Velocity:  [←────]      -250 px/s
Rotation:  [←──]        -11° (passed through target, slight bounce back)
Status:    Small overshoot in opposite direction (underdamped)


TIME: t=0.8 (Settled)
═══════════════════════════════════════════════════════════
Velocity:  [←─────]     -280 px/s
Rotation:  [←───]       -12° (aligned with velocity)
Status:    Stable state achieved
```

## Spring Physics Diagram

```
                    TARGET ANGLE (from velocity)
                            ↓
      ╔═════════════════════╗
      ║    -13° (Left)      ║  ← Equilibrium position
      ╚═════════════════════╝
                ↑
                │
                │ Spring Force
                │ (pulls toward target)
                │
                ↓
        Current Rotation
             -25°
        (Overshoot state)


Spring Force = (Target - Current) × Stiffness
             = (-13° - (-25°)) × 8.0
             = (+12°) × 8.0
             = +96° angular acceleration


After applying force:
  rotation_velocity += spring_force × delta
  rotation_velocity = rotation_velocity × DAMPING  ← Prevents oscillation
  current_rotation_angle += rotation_velocity × delta
```

## Parameter Effects Visualized

### ROTATION_OVERSHOOT_MULTIPLIER

```
Multiplier = 1.0 (No overshoot)
────────────────────────────────
Velocity:     [←─────]  -200 px/s
Target Angle:  -10°
Actual Angle:  -10°  (direct tracking, no swing)

                    ┌─────┐
    Velocity ───────┤     ├────── Rotation
                    └─────┘
                   1:1 ratio


Multiplier = 2.5 (Current setting)
────────────────────────────────
Velocity:     [←─────]  -200 px/s
Target Angle:  -10° → -25°  (multiplied by 2.5x on direction change)
Actual Angle:  -25° → springs back to -10°

                    ┌─────┐
    Velocity ───────┤ 2.5x├────── Rotation (initially)
                    └─────┘
                       ↓
                  [Spring back]
                       ↓
                    ┌─────┐
    Velocity ───────┤ 1.0x├────── Rotation (eventually)
                    └─────┘


Multiplier = 3.5 (Heavy cruiser)
────────────────────────────────
Velocity:     [←─────]  -200 px/s
Target Angle:  -10° → -35°  (dramatic swing!)
Actual Angle:  -35° → bounces back to -10°

                    ┌─────┐
    Velocity ───────┤ 3.5x├────── Rotation (initially)
                    └─────┘
                       ↓
                [Strong spring back]
                       ↓
                    ┌─────┐
    Velocity ───────┤ 1.0x├────── Rotation (eventually)
                    └─────┘
```

### ROTATION_SPRING_STIFFNESS

```
Stiffness = 4.0 (Slow, floaty)
────────────────────────────────
Time to settle: ~1.0 seconds
Feels like:     Heavy, drifty, disconnected

  Overshoot → [─────────────────→] Target
                 slow spring


Stiffness = 8.0 (Current setting)
────────────────────────────────
Time to settle: ~0.5 seconds
Feels like:     Balanced, responsive, connected

  Overshoot → [──────────→] Target
               medium spring


Stiffness = 12.0 (Fast, tight)
────────────────────────────────
Time to settle: ~0.3 seconds
Feels like:     Nimble, snappy, tight tracking

  Overshoot → [─────→] Target
             fast spring
```

### ROTATION_DAMPING

```
Damping = 0.75 (Critical damping - no bounce)
────────────────────────────────────────────
Rotation path:
    Overshoot → [smooth curve] → Target (stops)
                                    ↑
                                 No bounce!


Damping = 0.85 (Current - slight underdamping)
────────────────────────────────────────────
Rotation path:
    Overshoot → [bounce] → Target → [tiny bounce] → Settles
                   ↓                      ↓
                First                   Second
                bounce                  bounce
                (small)                (very small)


Damping = 0.92 (Heavy underdamping - springy)
────────────────────────────────────────────
Rotation path:
    Overshoot → [bounce] → [bounce] → [bounce] → Settles
                   ↓          ↓           ↓
                 Big       Medium       Small
                bounce     bounce      bounce
```

## Velocity vs Rotation Graph

```
Lateral Movement (Top Graph):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 +400 ┤                 ┌────┐
      │               ┌─┘    └─┐
      │             ┌─┘        └─┐
    0 ┼─────────────┘            └──────────
      │                              ┌───┐
      │                            ┌─┘   └─
 -400 ┤                          ┌─┘
      └────────────────────────────────────→ Time
      Player presses D → holds → releases → presses A

Rotation Angle (Bottom Graph - WITH BOW SWING):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  +45°┤                 ┌───┐      ← Overshoot!
      │                ╱     ╲
  +15°┤              ┌┘       └┐   ← Target (from velocity)
      │            ╱│           ╲
    0°┼───────────┘ │            └────────
      │             │                 ┌──╲╱─
      │             │               ╱─     └─
  -45°┤             └─────────────┌─        ← Overshoot!
      └────────────────────────────────────→ Time
                         ↑
                   Direction change
                   detected here!


Rotation Angle (Bottom Graph - WITHOUT BOW SWING):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  +15°┤                 ┌───┐
      │               ┌─┘   └─┐
      │             ┌─┘       └─┐
    0°┼─────────────┘           └──────────
      │                              ┌───┐
      │                            ┌─┘   └─
  -15°┤                          ┌─┘
      └────────────────────────────────────→ Time
      Direct 1:1 tracking (old system)
```

## Code Flow Diagram

```
┌─────────────────────────────────────────────────────────┐
│  _process(delta)  - Main game loop                     │
└────────────────┬────────────────────────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────────────────────────┐
│  Update player_lateral_velocity                         │
│  - Apply input acceleration                             │
│  - Apply damping                                        │
│  - Apply centering force                                │
│  - Clamp to MAX_LATERAL_VELOCITY                        │
└────────────────┬────────────────────────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────────────────────────┐
│  _update_bow_swing_rotation(delta)                      │
└────────────────┬────────────────────────────────────────┘
                 │
    ┌────────────┴────────────┐
    ↓                         ↓
┌─────────────────┐   ┌──────────────────┐
│ Calculate       │   │ Detect direction │
│ velocity_based  │   │ change           │
│ angle           │   │ (sign flip)      │
└────────┬────────┘   └────────┬─────────┘
         │                     │
         ↓                     ↓
         └──────┬──────────────┘
                │
                ↓
      ┌─────────────────────┐
      │ Direction changed?  │
      └─────────┬───────────┘
                │
       ┌────────┴────────┐
       │                 │
      YES               NO
       │                 │
       ↓                 ↓
┌──────────────┐  ┌──────────────┐
│ Apply        │  │ Set target = │
│ OVERSHOOT    │  │ velocity_    │
│ target *= 2.5│  │ based_angle  │
│              │  │              │
│ Kick         │  └──────┬───────┘
│ rotation_vel │         │
└──────┬───────┘         │
       │                 │
       └────────┬────────┘
                ↓
┌─────────────────────────────────────────┐
│ SPRING PHYSICS                          │
│ 1. spring_force = error × stiffness     │
│ 2. rotation_velocity += force × delta   │
│ 3. rotation_velocity *= damping         │
│ 4. current_angle += velocity × delta    │
│ 5. clamp(angle, -45°, +45°)             │
└────────────────┬────────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────────┐
│ Apply to ship sprite:                   │
│ player_ship.rotation_degrees =          │
│     -90 + current_rotation_angle        │
└─────────────────────────────────────────┘
```

## Key Insights

1. **Overshoot only triggers on direction CHANGE** (sign flip)
   - Not when starting to move from rest
   - Not when coming to a stop
   - Only when velocity crosses zero with momentum

2. **Spring physics runs EVERY frame**
   - Always pulling rotation toward target
   - Target changes based on direction change state

3. **Visual rotation is INDEPENDENT of velocity**
   - Ship can face one way while moving another (briefly)
   - Creates the illusion of mass and inertia

4. **Rotation velocity has momentum**
   - Can overshoot target and bounce back
   - Damping prevents endless oscillation

## Performance Notes

- All calculations are lightweight (basic math operations)
- No trigonometry except for final rotation application
- No physics engine queries
- Runs at 60 FPS with negligible overhead
- ~10 lines of logic per frame
