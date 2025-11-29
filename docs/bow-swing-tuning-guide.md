# Bow Swing Rotation Animation - Tuning Guide

## Overview

The player ship's rotation animation now features a dynamic "bow swing" effect using spring physics with overshoot. When changing direction, the ship's bow visually swings out beyond its actual travel direction, then smoothly springs back to align with the velocity vector.

**File**: `/home/mrdangerous/any-type-7/scenes/sector_exploration/sector_map.gd`

## How It Works

### Physics Model

1. **Target Angle Calculation**: Based on lateral velocity (normalized to `MAX_TILT_ANGLE`)
2. **Direction Change Detection**: Monitors when velocity sign changes (left ↔ right)
3. **Overshoot Application**: On direction change, multiplies target angle by `ROTATION_OVERSHOOT_MULTIPLIER`
4. **Damped Spring Physics**: Smoothly interpolates current rotation toward target using spring force and damping

### Key Differences from Previous System

**Before**:
```gdscript
# Direct 1:1 relationship - instant, no overshoot
var tilt_angle = (player_lateral_velocity / MAX_LATERAL_VELOCITY) * MAX_TILT_ANGLE
player_ship.rotation_degrees = -90 + tilt_angle
```

**After**:
- Separate `current_rotation_angle` (visual) from `velocity_based_angle` (physics)
- Spring system with velocity and acceleration
- Overshoot on direction changes
- Smooth spring-back to equilibrium

## Tunable Parameters

### 1. ROTATION_OVERSHOOT_MULTIPLIER
**Location**: Line 35
**Default**: `2.5`
**Purpose**: How much the ship overshoots when changing direction

**Effect**:
- `1.0` = No overshoot (direct velocity tracking, like old system)
- `2.0` = 100% overshoot (2x the target angle momentarily)
- `2.5` = 150% overshoot (current setting - dramatic swing)
- `3.0+` = Very exaggerated, cartoonish swing

**Tuning Recommendations**:
- **Subtle feel**: `1.5 - 2.0` (small ship, responsive)
- **Balanced feel**: `2.0 - 2.5` (medium ship, noticeable swing) **← CURRENT**
- **Heavy feel**: `2.5 - 3.5` (capital ship, dramatic bow swing)

### 2. ROTATION_SPRING_STIFFNESS
**Location**: Line 36
**Default**: `8.0`
**Purpose**: How quickly rotation snaps back to target angle

**Effect**:
- `2.0 - 5.0` = Slow spring-back (floaty, drifty feel)
- `6.0 - 10.0` = Medium spring-back (current range) **← CURRENT at 8.0**
- `10.0 - 15.0` = Fast spring-back (tight, responsive)
- `15.0+` = Near-instant snap (loses spring feel)

**Tuning Recommendations**:
- **Heavy/sluggish**: `4.0 - 6.0` (slow to realign)
- **Balanced**: `7.0 - 9.0` (natural spring feel) **← CURRENT**
- **Nimble/responsive**: `10.0 - 12.0` (quick recovery)

### 3. ROTATION_DAMPING
**Location**: Line 37
**Default**: `0.85`
**Purpose**: Prevents endless oscillation (angular velocity decay per frame)

**Effect**:
- `0.70 - 0.80` = High damping (quick settling, less bounce)
- `0.80 - 0.90` = Medium damping (1-2 oscillations) **← CURRENT at 0.85**
- `0.90 - 0.95` = Low damping (multiple bounces, springy)
- `0.95+` = Very low damping (can oscillate endlessly)

**Tuning Recommendations**:
- **Critical damping** (no bounce): `0.70 - 0.75`
- **Slightly underdamped** (1 small bounce): `0.80 - 0.85` **← CURRENT**
- **Underdamped** (multiple bounces): `0.90 - 0.95`

### 4. MAX_TILT_ANGLE
**Location**: Line 32
**Default**: `15.0` degrees
**Purpose**: Maximum rotation angle at full lateral velocity

**Effect**:
- `10.0` = Subtle tilt (realistic spacecraft)
- `15.0` = Noticeable tilt (current setting) **← CURRENT**
- `20.0 - 25.0` = Dramatic tilt (arcade feel)
- `30.0+` = Extreme tilt (combat aircraft)

**Note**: Overshoot can exceed this value (up to 3x for safety clamp)

## Relationship Between ship_responsiveness and Rotation

The `ship_responsiveness` parameter (line 40, default `0.95`) affects **velocity physics**, not rotation directly:

- High responsiveness (0.9-1.0) = Ship fights direction changes → **more** bow swing opportunity
- Low responsiveness (0.0-0.5) = Ship turns easily → **less** bow swing opportunity

**These systems work together**:
- High `ship_responsiveness` + High `ROTATION_OVERSHOOT_MULTIPLIER` = Heavy capital ship feel
- Low `ship_responsiveness` + Low `ROTATION_OVERSHOOT_MULTIPLIER` = Nimble interceptor feel

## Preset Configurations

### Preset 1: Nimble Scout (Light, Responsive)
```gdscript
const ROTATION_OVERSHOOT_MULTIPLIER: float = 1.5
const ROTATION_SPRING_STIFFNESS: float = 12.0
const ROTATION_DAMPING: float = 0.75
const MAX_TILT_ANGLE: float = 12.0
var ship_responsiveness: float = 0.5  # Low resistance
```

### Preset 2: Balanced Fighter (Current Default)
```gdscript
const ROTATION_OVERSHOOT_MULTIPLIER: float = 2.5
const ROTATION_SPRING_STIFFNESS: float = 8.0
const ROTATION_DAMPING: float = 0.85
const MAX_TILT_ANGLE: float = 15.0
var ship_responsiveness: float = 0.95  # High resistance
```

### Preset 3: Heavy Cruiser (Dramatic Swing)
```gdscript
const ROTATION_OVERSHOOT_MULTIPLIER: float = 3.2
const ROTATION_SPRING_STIFFNESS: float = 6.0
const ROTATION_DAMPING: float = 0.88
const MAX_TILT_ANGLE: float = 20.0
var ship_responsiveness: float = 1.0  # Maximum resistance
```

### Preset 4: Arcade Racer (Springy, Fun)
```gdscript
const ROTATION_OVERSHOOT_MULTIPLIER: float = 2.8
const ROTATION_SPRING_STIFFNESS: float = 10.0
const ROTATION_DAMPING: float = 0.92
const MAX_TILT_ANGLE: float = 22.0
var ship_responsiveness: float = 0.7  # Medium resistance
```

## Testing Procedure

### Visual Feedback Checklist

1. **Direction Change Test**:
   - Press A (left), then quickly D (right)
   - Watch for visible overshoot beyond equilibrium angle
   - Ship should swing out, then spring back smoothly

2. **Oscillation Test**:
   - Tap A briefly, then release
   - Count how many bounces before settling
   - Ideal: 1-2 small bounces (underdamped)

3. **Responsiveness Test**:
   - Make rapid left-right inputs (A-D-A-D)
   - Ship rotation should feel connected but lagging behind input
   - Should see continuous swinging motion

4. **Velocity Tracking Test**:
   - Hold D to build velocity
   - Release input (ship drifts)
   - Rotation should smoothly align with drift direction

### Performance Verification

- **Frame rate**: Should maintain 60 FPS (rotation calc is lightweight)
- **No jitter**: Smooth interpolation, no sudden jumps
- **Bounded rotation**: Never exceeds 3x `MAX_TILT_ANGLE` (safety clamp)

## Common Tuning Scenarios

### "Ship feels too twitchy"
**Solution**: Increase `ROTATION_SPRING_STIFFNESS` to 10.0+, or decrease `ROTATION_DAMPING` to 0.80

### "Not enough swing on direction change"
**Solution**: Increase `ROTATION_OVERSHOOT_MULTIPLIER` to 3.0+, or increase `MAX_TILT_ANGLE` to 20.0

### "Ship wobbles too much"
**Solution**: Decrease `ROTATION_DAMPING` to 0.75-0.80 (critical damping)

### "Rotation feels disconnected from movement"
**Solution**: Increase `ROTATION_SPRING_STIFFNESS` to 12.0+ for tighter tracking

### "Want more dramatic arcade feel"
**Solution**:
- `ROTATION_OVERSHOOT_MULTIPLIER = 3.0`
- `MAX_TILT_ANGLE = 25.0`
- `ROTATION_DAMPING = 0.90` (allow bouncing)

### "Want realistic spacecraft feel"
**Solution**:
- `ROTATION_OVERSHOOT_MULTIPLIER = 1.5`
- `MAX_TILT_ANGLE = 10.0`
- `ROTATION_DAMPING = 0.75` (critical damping)
- `ship_responsiveness = 0.3` (low inertia)

## Technical Details

### Direction Change Detection

Direction changes are detected when velocity crosses zero:
```gdscript
var current_velocity_sign = sign(player_lateral_velocity)
if last_velocity_sign != 0.0 and current_velocity_sign != 0.0:
    if last_velocity_sign != current_velocity_sign:
        is_direction_changing = true
```

This prevents false positives when:
- Starting to move from rest (no previous direction)
- Coming to a complete stop (velocity = 0)

### Overshoot Kick

On direction change, rotation velocity gets an additional impulse:
```gdscript
var overshoot_kick = sign(velocity_based_angle) * MAX_TILT_ANGLE * 2.0
rotation_velocity += overshoot_kick
```

This creates a sharper initial swing before the spring physics take over.

### Safety Clamp

Rotation is clamped to prevent wild spins:
```gdscript
var max_overshoot = MAX_TILT_ANGLE * 3.0
current_rotation_angle = clamp(current_rotation_angle, -max_overshoot, max_overshoot)
```

This allows overshoot while preventing runaway rotation from spring oscillations.

## Integration Notes

### Jump System
When jumping, all rotation variables are reset to zero:
```gdscript
current_rotation_angle = 0.0
rotation_velocity = 0.0
target_rotation_angle = 0.0
last_velocity_sign = 0.0
```

This prevents rotation momentum from carrying over after teleportation.

### Control Lock (Gravity Assist)
Rotation animation continues during control lock - the ship will still rotate to match its momentum even when player can't steer.

## Future Enhancements

Potential additions to the system:

1. **Speed-dependent overshoot**: Higher speeds = more dramatic swing
   ```gdscript
   var speed_factor = current_speed_multiplier / 2.0  # Normalize to 1.0 at 2.0x speed
   target_rotation_angle = velocity_based_angle * ROTATION_OVERSHOOT_MULTIPLIER * speed_factor
   ```

2. **Responsiveness-linked rotation**: Tie overshoot to `ship_responsiveness`
   ```gdscript
   var overshoot_mult = lerp(1.5, 3.5, ship_responsiveness)
   target_rotation_angle = velocity_based_angle * overshoot_mult
   ```

3. **Velocity magnitude influence**: Faster movement = more rotation
   ```gdscript
   var velocity_magnitude = abs(player_lateral_velocity) / MAX_LATERAL_VELOCITY
   var dynamic_max_tilt = MAX_TILT_ANGLE * velocity_magnitude
   ```

4. **Asymmetric spring constants**: Different stiffness for left vs right turns

5. **Trail particles**: Spawn thrust particles aligned to rotation angle (not velocity)

## Summary

The bow swing system creates a more visceral, weighty feel by separating visual rotation from actual physics. The ship "fights" direction changes visually, swinging out before settling back into alignment. This makes the heavy momentum-based movement feel more intentional and satisfying.

**Key takeaway**: The three constants work together - adjust them in small increments and test in-game with rapid direction changes to find your preferred feel.
