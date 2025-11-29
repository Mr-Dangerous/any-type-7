# Testing the Bow Swing Animation

## Quick Start

1. **Open the project** in Godot 4.5
2. **Run the sector exploration scene** (F5 or play button)
3. **Use keyboard controls** to test:
   - `A` = Move left
   - `D` = Move right

## What to Test

### Test 1: Basic Direction Change
1. Hold `D` for 2 seconds (ship moves right)
2. Quickly press `A` (change direction to left)
3. **Expected**: Ship's bow should swing dramatically to the left, then spring back smoothly

### Test 2: Rapid Direction Changes
1. Quickly tap `A-D-A-D-A-D` repeatedly
2. **Expected**: Ship should continuously swing back and forth, fighting momentum

### Test 3: Overshoot and Bounce
1. Tap `A` briefly (about 0.5 seconds)
2. Release completely
3. **Expected**: Ship should overshoot slightly, bounce once, then settle aligned with drift

## Visual Checklist

✅ **Good Signs**:
- [ ] Ship rotation overshoots when changing direction
- [ ] Smooth spring-back motion to equilibrium
- [ ] One small bounce before settling
- [ ] Rotation feels connected to movement but not instant
- [ ] Ship appears to have mass/weight

❌ **Problems** (shouldn't happen):
- [ ] Rotation is instant (no overshoot visible)
- [ ] Endless wobbling/oscillation
- [ ] Ship spins wildly or rotates > 45°
- [ ] Rotation feels disconnected from movement

## Tuning Parameters

If you want to adjust the feel, edit `/home/mrdangerous/any-type-7/scenes/sector_exploration/sector_map.gd` lines 35-37:

```gdscript
# Make it MORE dramatic (Heavy Cruiser)
const ROTATION_OVERSHOOT_MULTIPLIER: float = 3.2
const ROTATION_SPRING_STIFFNESS: float = 6.0
const ROTATION_DAMPING: float = 0.88

# Make it LESS dramatic (Nimble Scout)
const ROTATION_OVERSHOOT_MULTIPLIER: float = 1.5
const ROTATION_SPRING_STIFFNESS: float = 12.0
const ROTATION_DAMPING: float = 0.75

# Current (Balanced Fighter) - default
const ROTATION_OVERSHOOT_MULTIPLIER: float = 2.5
const ROTATION_SPRING_STIFFNESS: float = 8.0
const ROTATION_DAMPING: float = 0.85
```

## Documentation

For detailed tuning information, see:
- **Quick Reference**: `/home/mrdangerous/any-type-7/docs/bow-swing-quick-reference.md`
- **Full Guide**: `/home/mrdangerous/any-type-7/docs/bow-swing-tuning-guide.md`
- **Physics Diagrams**: `/home/mrdangerous/any-type-7/docs/bow-swing-physics-diagram.md`

## Performance Check

The animation should maintain 60 FPS easily. If you experience frame drops, the issue is elsewhere (not the rotation system).

## Questions?

See the implementation summary: `/home/mrdangerous/any-type-7/docs/bow-swing-implementation-summary.md`
