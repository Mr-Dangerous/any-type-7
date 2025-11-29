# IndicatorManager System

**Version**: 1.0
**Created**: 2025-11-29
**Status**: Implemented (Phase 2)

## Overview

The **IndicatorManager** is a global autoload singleton that provides unified visual feedback systems across all game modules. It manages pulsing indicators, cooldown displays, charge effects, and other visual feedback elements that need to work consistently in both sector exploration and combat.

### Core Design Principles

1. **Global Singleton Pattern** - One system accessible from anywhere via `IndicatorManager`
2. **Module-Agnostic** - Works in both sector exploration and combat without modification
3. **CanvasLayer-Based** - Uses CanvasLayer for consistent rendering on top of game elements
4. **Persistent** - Indicators survive scene transitions (managed by autoload)
5. **Performance-First** - Minimal overhead, efficient rendering
6. **Expandable** - Designed for future indicator types

## Current Features (v1.0)

### Jump Indicator System

The jump indicator is a pulsing visual marker that shows where a ship will land after a jump maneuver.

**Visual Appearance**:
- Bright yellow/gold pulsing dot
- Outer glow effect (80px diameter)
- White center dot (15px diameter)
- Base size: 50px diameter
- Pulse animation: 0.7x to 1.3x scale at 2 pulses/second
- Z-index: 100 (renders above all game elements)

**Usage**:

```gdscript
# Show jump indicator at a world position
IndicatorManager.show_jump_indicator(Vector2(540, 1950))

# Update position (can be called every frame)
IndicatorManager.show_jump_indicator(Vector2(new_x, new_y))

# Hide indicator
IndicatorManager.hide_jump_indicator()

# Check if visible
if IndicatorManager.is_jump_indicator_visible():
    print("Jump indicator is showing")

# Get current position
var pos = IndicatorManager.get_jump_indicator_position()
```

**Integration in Sector Exploration**:

The sector exploration module uses the jump indicator during the jump charge mechanic:

1. Player holds SPACE key to charge jump
2. After 0.5s delay, jump indicator appears at target position
3. Indicator updates position as charge time increases (longer charge = farther jump)
4. On release, indicator hides and jump executes

**Example from `sector_map.gd`**:

```gdscript
func _update_jump_indicator() -> void:
    """Update the visual jump indicator position using global IndicatorManager"""
    # Show indicator after delay
    if jump_charge_time >= JUMP_INDICATOR_SHOW_DELAY:
        # Calculate current jump target
        var jump_distance = _calculate_jump_distance()
        var target_pos = _calculate_jump_target(jump_distance)

        # Update indicator position
        IndicatorManager.show_jump_indicator(Vector2(target_pos, PLAYER_Y_POSITION))
    else:
        # Hide indicator during initial charge delay
        IndicatorManager.hide_jump_indicator()

func _release_jump() -> void:
    """Release the jump and execute it"""
    # ... jump logic ...

    # Hide indicator
    IndicatorManager.hide_jump_indicator()
```

## Planned Features (Future Expansion)

### 1. Cooldown Indicators

Circular progress indicators for abilities and actions on cooldown.

**Planned API**:

```gdscript
# Show cooldown indicator
var cooldown_id = IndicatorManager.show_cooldown_indicator(
    Vector2(100, 200),  # Position
    10.0                # Duration in seconds
)

# Update progress manually (optional, can auto-update)
IndicatorManager.update_cooldown_progress(cooldown_id, 0.5)  # 50% complete

# Hide when complete
IndicatorManager.hide_cooldown_indicator(cooldown_id)
```

**Visual Design** (planned):
- Circular progress ring
- Color: Blue → Green as cooldown completes
- Optional timer text in center
- Size: 60px diameter (configurable)

**Use Cases**:
- Jump cooldown (10 seconds)
- Ship ability cooldowns
- Weapon reload timers
- Special action cooldowns

### 2. Charge Indicators

Fill-up progress indicators for charging actions.

**Planned API**:

```gdscript
# Start showing charge indicator
IndicatorManager.show_charge_indicator(Vector2(540, 1950))

# Update charge progress (0.0 to 1.0)
IndicatorManager.update_charge_progress(0.35)  # 35% charged

# Hide indicator
IndicatorManager.hide_charge_indicator()
```

**Visual Design** (planned):
- Circular fill-up ring (fills clockwise from top)
- Color: Yellow → Bright white as charge completes
- Pulsing intensity increases with charge level
- Optional "ready" flash at 100%

**Use Cases**:
- Jump charge (current use case - can migrate to this)
- Weapon charging
- Ability charge-ups
- Power collection progress

### 3. Damage Numbers

Floating text that shows damage dealt/received in combat.

**Planned API**:

```gdscript
# Show normal damage
IndicatorManager.show_damage_number(
    Vector2(500, 1200),  # Position
    45,                  # Damage amount
    false                # Not critical
)

# Show critical hit damage
IndicatorManager.show_damage_number(
    Vector2(500, 1200),  # Position
    120,                 # Damage amount
    true                 # Critical hit
)
```

**Visual Design** (planned):
- Floating text that rises and fades
- Normal damage: White text, medium size
- Critical damage: Yellow/gold text, larger size, bold
- Animation: Rise 100px over 1 second, fade out
- Optional: Damage type colors (fire = red, ice = blue, etc.)

**Use Cases**:
- Combat damage feedback
- Healing numbers (green text)
- Shield damage vs hull damage (different colors)

### 4. Status Effect Icons

Small icons showing active status effects above units.

**Planned API**:

```gdscript
# Show status icon above a ship
var icon_id = IndicatorManager.show_status_icon(
    ship_node,           # Target node to attach to
    "burn",             # Effect type
    5.0                 # Duration in seconds
)

# Hide when effect ends
IndicatorManager.hide_status_icon(icon_id)
```

**Visual Design** (planned):
- Small icon (32x32px) above unit
- Icon follows unit position
- Stacks vertically for multiple effects
- Fade in/out animations
- Optional: Timer ring around icon

**Use Cases**:
- Burn, freeze, static, acid, gravity status effects
- Control effects (stun, blind, malfunction)
- Buff/debuff indicators

## Technical Architecture

### File Location

```
/home/mrdangerous/any-type-7/scripts/autoloads/IndicatorManager.gd
```

### Autoload Configuration

Added to `project.godot`:

```ini
[autoload]
IndicatorManager="*res://scripts/autoloads/IndicatorManager.gd"
```

The `*` prefix ensures the singleton is instantiated immediately when the game starts.

### Node Hierarchy

```
IndicatorManager (Node, autoload singleton)
└── JumpIndicatorLayer (CanvasLayer, layer=100)
    └── JumpIndicatorSprite (Node2D)
        └── (Future: Custom drawing or sprite children)
```

**Why CanvasLayer?**
- Ensures indicators render on top of all game elements
- Independent of camera transformations
- Consistent z-ordering across scenes
- Performance: Separate render pass for UI elements

### Memory Management

- Indicators are persistent across scenes (autoload pattern)
- Minimal memory footprint (only active indicators exist)
- Automatic cleanup on scene transitions via `clear_all_indicators()`
- No leaks: All child nodes properly freed on deletion

### Performance Considerations

1. **Minimal Processing**: Only active indicators run update logic
2. **Efficient Rendering**: Uses CanvasLayer for optimized draw calls
3. **Scale Animation Only**: Jump indicator uses simple scale transform (no heavy effects)
4. **Future**: Sprite-based rendering for better visual quality with minimal overhead

## Constants Reference

### Jump Indicator Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `JUMP_INDICATOR_SIZE` | 50.0 | Base diameter in pixels |
| `JUMP_PULSE_MIN_SCALE` | 0.7 | Smallest scale during pulse |
| `JUMP_PULSE_MAX_SCALE` | 1.3 | Largest scale during pulse |
| `JUMP_PULSE_SPEED` | 2.0 | Pulses per second |
| `JUMP_GLOW_SIZE` | 80.0 | Outer glow diameter |
| `JUMP_CENTER_SIZE` | 15.0 | White center dot diameter |
| `INDICATOR_Z_INDEX` | 100 | CanvasLayer rendering priority |

### Color Constants

| Constant | Color | Usage |
|----------|-------|-------|
| `JUMP_COLOR_PRIMARY` | RGB(255, 230, 51) | Main indicator color (yellow/gold) |
| `JUMP_COLOR_GLOW` | RGBA(255, 217, 0, 153) | Outer glow (semi-transparent) |
| `JUMP_COLOR_CENTER` | RGB(255, 255, 255) | Center dot (white) |

## Future Combat Integration

When the combat module is implemented, the jump indicator will work seamlessly:

**Combat Jump Usage** (planned):

```gdscript
# In combat grid (15x25 lanes)
func _on_ship_jump_ability_activated(ship: Node2D, target_lane: int, target_file: int):
    # Convert grid coordinates to world position
    var target_pos = combat_grid.get_cell_world_position(target_lane, target_file)

    # Show jump indicator at target cell
    IndicatorManager.show_jump_indicator(target_pos)

    # Execute jump after delay
    await get_tree().create_timer(0.5).timeout
    ship.position = target_pos

    # Hide indicator
    IndicatorManager.hide_jump_indicator()
```

**Key Advantages for Combat**:
- No combat-specific indicator code needed
- Consistent visual language with sector exploration
- Same API works with different coordinate systems
- CanvasLayer ensures visibility above combat particles/effects

## Utility Functions

### clear_all_indicators()

Clears all active indicators. Useful for scene transitions.

```gdscript
func _on_scene_changed():
    IndicatorManager.clear_all_indicators()
```

**Current Behavior**:
- Hides jump indicator
- Future: Will clear all indicator types

## Migration Notes

### Changes to sector_map.gd

**Removed**:
- `var jump_indicator: Node2D = null` - No longer needed
- `_create_jump_indicator()` function - Handled by IndicatorManager

**Updated**:
- `_update_jump_indicator()` - Now calls `IndicatorManager.show_jump_indicator()`
- `_release_jump()` - Now calls `IndicatorManager.hide_jump_indicator()`
- `_cancel_jump()` - Now calls `IndicatorManager.hide_jump_indicator()`

**Benefits**:
- 10+ lines of code removed from sector_map.gd
- No local indicator management
- Scene stays under 300-line limit
- Indicator works globally (future combat module gets it for free)

## Testing Checklist

### Manual Testing (Sector Exploration)

- [ ] Jump indicator appears after 0.5s charge delay
- [ ] Indicator pulses smoothly (0.7x to 1.3x scale)
- [ ] Indicator position updates as charge time increases
- [ ] Indicator appears on top of all nodes/grid tiles
- [ ] Indicator hides on jump release
- [ ] Indicator hides on jump cancel (out of fuel)
- [ ] Indicator survives scene transitions (autoload persistence)

### Performance Testing

- [ ] No FPS drop when indicator is active
- [ ] Smooth 60 FPS pulsing animation
- [ ] No memory leaks after repeated show/hide cycles

### Integration Testing

- [ ] Works correctly at different screen positions (left, center, right)
- [ ] Works with different aspect ratios (18:9, 19:9, 19.5:9, 20:9)
- [ ] Visible in all lighting conditions (dark space, bright stars)

## Code Style Compliance

- ✅ File size: 254 lines (well under 300-line limit)
- ✅ Uses typed GDScript for clarity
- ✅ Comprehensive documentation comments
- ✅ Follows singleton autoload pattern
- ✅ EventBus-ready (no signals needed currently, but compatible)
- ✅ No hardcoded game logic (pure visual feedback system)

## Future Enhancements

### Visual Improvements

1. **Sprite-Based Rendering**
   - Replace procedural drawing with pre-rendered sprites
   - Better visual quality
   - Easier to customize per game theme

2. **Particle Effects**
   - Add subtle particle emissions around jump indicator
   - Trail effects for charge indicators
   - Impact particles for damage numbers

3. **Screen-Space Positioning**
   - Add option for HUD-relative indicators (not world-space)
   - Useful for UI feedback (button presses, menu selections)

### Functional Improvements

1. **Indicator Pooling**
   - Pre-create indicator instances for better performance
   - Reuse instances instead of creating/destroying

2. **Priority System**
   - Handle overlapping indicators gracefully
   - Stack or offset multiple indicators at same position

3. **Audio Integration**
   - Optional sound effects on indicator show/hide
   - Integration with AudioManager singleton

## Related Documentation

- **sector-exploration-module.md** - Jump mechanic design
- **combat-formulas.md** - Future: Damage number calculations
- **status-effects-and-combos.md** - Future: Status icon reference
- **phase-2-sector-exploration.md** - Implementation roadmap

## Version History

- **v1.0** (2025-11-29) - Initial implementation
  - Jump indicator system
  - CanvasLayer-based rendering
  - Sector exploration integration
  - Stub functions for future features

## API Summary

### Current (v1.0)

```gdscript
# Jump Indicators
IndicatorManager.show_jump_indicator(world_position: Vector2) -> void
IndicatorManager.hide_jump_indicator() -> void
IndicatorManager.is_jump_indicator_visible() -> bool
IndicatorManager.get_jump_indicator_position() -> Vector2

# Utilities
IndicatorManager.clear_all_indicators() -> void
```

### Future (Planned)

```gdscript
# Cooldown Indicators
IndicatorManager.show_cooldown_indicator(position: Vector2, duration: float) -> String
IndicatorManager.hide_cooldown_indicator(id: String) -> void

# Charge Indicators
IndicatorManager.show_charge_indicator(position: Vector2) -> void
IndicatorManager.update_charge_progress(progress: float) -> void
IndicatorManager.hide_charge_indicator() -> void

# Damage Numbers
IndicatorManager.show_damage_number(position: Vector2, damage: int, is_critical: bool) -> void

# Status Effect Icons
IndicatorManager.show_status_icon(target_node: Node2D, effect_type: String, duration: float) -> String
IndicatorManager.hide_status_icon(id: String) -> void
```

---

**End of Documentation**
