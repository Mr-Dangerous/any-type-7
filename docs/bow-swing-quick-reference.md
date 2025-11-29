# Bow Swing Animation - Quick Reference Card

**File**: `/home/mrdangerous/any-type-7/scenes/sector_exploration/sector_map.gd`

## Current Settings (Balanced Fighter)

```gdscript
# Lines 35-37
const ROTATION_OVERSHOOT_MULTIPLIER: float = 2.5  # 150% overshoot on direction change
const ROTATION_SPRING_STIFFNESS: float = 8.0      # Medium spring-back speed
const ROTATION_DAMPING: float = 0.85              # Slight underdamping (1 small bounce)
```

## Quick Tuning Adjustments

### Make it MORE dramatic (Heavy Cruiser)
```gdscript
const ROTATION_OVERSHOOT_MULTIPLIER: float = 3.2  # ← Increase this
const ROTATION_SPRING_STIFFNESS: float = 6.0      # ← Decrease this
const ROTATION_DAMPING: float = 0.88              # ← Increase this slightly
```

### Make it LESS dramatic (Nimble Scout)
```gdscript
const ROTATION_OVERSHOOT_MULTIPLIER: float = 1.5  # ← Decrease this
const ROTATION_SPRING_STIFFNESS: float = 12.0     # ← Increase this
const ROTATION_DAMPING: float = 0.75              # ← Decrease this
```

### Make it MORE bouncy (Arcade Feel)
```gdscript
const ROTATION_DAMPING: float = 0.92              # ← Increase this only
```

### Make it LESS bouncy (Realistic)
```gdscript
const ROTATION_DAMPING: float = 0.75              # ← Decrease this only
```

## Parameter Ranges

| Parameter | Subtle | Balanced | Dramatic |
|-----------|--------|----------|----------|
| **Overshoot** | 1.5-2.0 | 2.0-2.5 | 2.5-3.5 |
| **Stiffness** | 10-12 | 7-9 | 4-6 |
| **Damping** | 0.70-0.75 | 0.80-0.85 | 0.88-0.92 |

## What Each Parameter Does

**ROTATION_OVERSHOOT_MULTIPLIER** = How much the bow swings OUT when changing direction
- Higher = more dramatic initial swing
- Lower = tighter, more controlled rotation

**ROTATION_SPRING_STIFFNESS** = How fast the rotation snaps BACK to equilibrium
- Higher = quick recovery, tight tracking
- Lower = slow, drifty feel

**ROTATION_DAMPING** = How much the rotation BOUNCES before settling
- Higher (0.90+) = multiple bounces, springy
- Lower (0.70-) = no bounce, immediate settling

## Testing Checklist

1. Press A (left), then quickly tap D (right)
2. Watch the ship's bow:
   - Does it swing dramatically to the right?
   - Does it spring back smoothly?
   - How many times does it bounce?

3. Adjust parameters and repeat until it feels right

## See Full Guide

For detailed explanations, presets, and advanced tuning:
`/home/mrdangerous/any-type-7/docs/bow-swing-tuning-guide.md`
