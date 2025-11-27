# Abilities System Reference

Comprehensive guide to ship abilities in Any-Type-7.

**Related Documentation:**
- [Ship Statistics Reference](ship-stats-reference.md) - Ship stats and ability stats (Amplitude, Frequency)
- [Status Effects & Combos](status-effects-and-combos.md) - Elemental triggers and combos
- [Weapons System](weapons-system.md) - Weapon mechanics and triggers
- [Combat Formulas](combat-formulas.md) - Damage calculations

---

## Overview

**Abilities** are special powers that ships can activate during combat. Unlike weapons (which fire automatically), abilities are triggered by the ship when certain conditions are met (typically when enough energy is accumulated).

**Key Concepts:**
- Abilities are **innate to ships** - they cannot be swapped like weapons
- Each ship has one ability defined by its `ship_ability` field
- Abilities are **data-driven** and balanced entirely from CSV files
- Abilities use ship's **Amplitude** and **Frequency** stats to scale effects
- Abilities consume **Energy Points** when activated

---

## Ability Mechanics

### Energy System

Ships generate energy during combat to power their abilities.

**Energy Generation:**
- Ships start combat with **0 energy**
- Energy is gained by:
  - **Auto-attacking** enemies
  - **Taking damage** from enemies
- When energy reaches the ability's cost, the ability can be activated
- Energy generation rates are defined globally or per-ship

**Energy Stats:**
- **Energy Points** (ship stat): Maximum energy capacity
- **Energy Cost** (ability stat): Energy required to cast ability

### Amplitude & Frequency

Ships with abilities benefit from **Amplitude** and **Frequency** stats.

**Amplitude** (ship stat):
- Increases **numerical effects** of abilities
- Formula: `Modified_Value = Base_Value × (1 + Amplitude/100)`
- Examples:
  - 50 damage ability with 20% Amplitude = 60 damage
  - 60 shield restore with 40% Amplitude = 84 shields

**Frequency** (ship stat):
- Increases **duration** of ability effects
- Formula: `Modified_Duration = Base_Duration × (1 + Frequency/100)`
- Examples:
  - 10-second buff with 20% Frequency = 12 seconds
  - 3-second stun with 50% Frequency = 4.5 seconds

### Ability Activation

**Activation Methods:**
- **Automatic**: Ability casts automatically when energy is full
- **Manual** (future): Player can trigger abilities manually (mobile tap)
- **Conditional**: Some abilities may have trigger conditions (on low health, on enemy nearby, etc.)

**Cooldowns:**
- Most abilities do not have cooldowns - they activate when energy is available
- Energy regeneration acts as natural cooldown
- Some abilities may have explicit cooldowns defined in CSV

---

## Ability Types

Abilities can be categorized by their primary function:

### 1. Damage Abilities

**Purpose**: Deal direct damage to enemies

**Examples:**
- **Missile Lock**: Launch a high-damage missile
- **Barrage**: Fire rapid burst of projectiles
- **Burning Field**: AoE damage over time

**CSV Properties:**
- `damage`: Base damage dealt
- `damage_type`: physical, fire, ice, lightning, acid, gravity, explosive
- `aoe_radius`: Area of effect (0 = single target)

### 2. Buff Abilities

**Purpose**: Enhance allied ships' stats or capabilities

**Examples:**
- **Tactical Command**: Grant nearby ships bonus stats
- **Shield Battery**: Restore shields to allies
- **Silent Running**: Grant self movement speed and cloak

**CSV Properties:**
- `buff_target`: self, allies, all
- `buff_stat`: stat to modify (damage, speed, accuracy, etc.)
- `buff_value`: amount of stat increase
- `buff_duration`: how long buff lasts

### 3. Debuff/Control Abilities

**Purpose**: Weaken or disable enemies

**Examples:**
- **Mark Target**: Increase damage taken by target
- **EMP Burst**: Stun enemies
- **Gravity Well**: Slow enemies in area

**CSV Properties:**
- `debuff_target`: enemy, enemies, all_enemies
- `debuff_stat`: stat to reduce
- `debuff_value`: amount of reduction
- `debuff_duration`: how long debuff lasts

### 4. Defensive Abilities

**Purpose**: Protect ship or allies from damage

**Examples:**
- **Reactive Armor**: Gain shields and reflect damage
- **Shield Projection**: Create blocking obstacle
- **Emergency Cloak**: Gain stealth temporarily

**CSV Properties:**
- `shield_restore`: Amount of shields granted
- `damage_reduction`: Percentage damage reduction
- `creates_obstacle`: true/false
- `grants_stealth`: true/false

### 5. Utility Abilities

**Purpose**: Special mechanics that don't fit other categories

**Examples:**
- **Teleport**: Instant repositioning
- **Drone Deploy**: Summon combat drone
- **Ordinance Reload**: Refill weapon ammo

**CSV Properties:**
- `special_mechanic`: Type of utility (teleport, drone, reload, etc.)
- `special_value`: Mechanic-specific value

---

## Ability Targeting

Abilities can target different entities or areas:

**Target Types:**
- **Self**: Affects only the casting ship
- **Single Enemy**: Targets one enemy (current target, nearest, lowest HP, etc.)
- **Single Ally**: Targets one friendly ship
- **Area (Self)**: Affects area around casting ship
- **Area (Target)**: Affects area around targeted enemy
- **Area (Forward)**: Projects area in direction ship is facing
- **Row/Lane**: Affects entire lane(s)
- **All Enemies**: Affects all enemy ships
- **All Allies**: Affects all friendly ships

**CSV Properties:**
- `target_type`: self, enemy, ally, area_self, area_target, area_forward, row, all_enemies, all_allies
- `target_radius`: Range for area effects (grid squares)
- `target_rows`: Number of rows affected (for row-based abilities)

---

## Elemental Triggers

Abilities can apply or detonate **elemental status effects** (see [Status Effects & Combos](status-effects-and-combos.md)).

**Trigger Types:**
- **Fire**: Applies Burn (2 damage/sec per stack)
- **Ice**: Applies Freeze (-20% attack speed per stack)
- **Lightning**: Applies Static (-3 energy/sec per stack)
- **Acid**: Applies Acid (-1 armor/sec per stack)
- **Gravity**: Applies Gravity (-30% movement & evasion per stack)
- **Explosive**: Detonates all active elemental effects

**Application:**
- **Direct Application**: Ability applies X stacks of status effect
- **Trigger Chance**: Ability has X% chance to apply status on hit
- **Detonation**: Ability triggers elemental combo explosions

**CSV Properties:**
- `trigger_type`: fire, ice, lightning, acid, gravity, explosive
- `trigger_stacks`: Number of stacks applied (1-3)
- `trigger_chance`: Chance to apply (0.0-1.0)

---

## CSV Database Structure

### ability_database.csv Columns

```csv
ability_ID,ability_name,ability_description,
energy_cost,cooldown,
damage,damage_type,aoe_radius,projectile_count,
target_type,target_radius,target_rows,
buff_target,buff_stat,buff_value,buff_duration,
debuff_target,debuff_stat,debuff_value,debuff_duration,
shield_restore,damage_reduction,
creates_obstacle,obstacle_duration,obstacle_health,
grants_stealth,stealth_duration,
special_mechanic,special_value,
trigger_type,trigger_stacks,trigger_chance,
animation_id,particle_effect,sound_effect
```

### Column Reference

| Column | Type | Description |
|--------|------|-------------|
| `ability_ID` | String | Unique identifier (e.g., "missile_lock") |
| `ability_name` | String | Display name |
| `ability_description` | String | Text description of ability effect |
| `energy_cost` | Integer | Energy required to cast |
| `cooldown` | Float | Cooldown in seconds (0 = no cooldown) |
| **Damage Properties** | | |
| `damage` | Integer | Base damage dealt |
| `damage_type` | String | physical, fire, ice, lightning, acid, gravity, explosive |
| `aoe_radius` | Integer | Area of effect radius (0 = single target) |
| `projectile_count` | Integer | Number of projectiles fired (if applicable) |
| **Targeting** | | |
| `target_type` | String | self, enemy, ally, area_self, area_target, area_forward, row, all_enemies, all_allies |
| `target_radius` | Integer | Range for area effects (grid squares) |
| `target_rows` | Integer | Number of rows/lanes affected |
| **Buff Properties** | | |
| `buff_target` | String | self, allies, all |
| `buff_stat` | String | Stat to modify (damage, speed, accuracy, etc.) |
| `buff_value` | Integer/Float | Amount of stat increase |
| `buff_duration` | Float | Duration in seconds |
| **Debuff Properties** | | |
| `debuff_target` | String | enemy, enemies, all_enemies |
| `debuff_stat` | String | Stat to reduce |
| `debuff_value` | Integer/Float | Amount of reduction |
| `debuff_duration` | Float | Duration in seconds |
| **Defensive Properties** | | |
| `shield_restore` | Integer | Amount of shields granted |
| `damage_reduction` | Float | Percentage damage reduction (0.0-1.0) |
| **Obstacle Properties** | | |
| `creates_obstacle` | Boolean | true if creates blocking object |
| `obstacle_duration` | Float | How long obstacle lasts |
| `obstacle_health` | Integer | HP of obstacle (if damageable) |
| **Stealth Properties** | | |
| `grants_stealth` | Boolean | true if grants stealth |
| `stealth_duration` | Float | How long stealth lasts |
| **Special Mechanics** | | |
| `special_mechanic` | String | Type of special effect (teleport, drone, reload, etc.) |
| `special_value` | String/Integer | Mechanic-specific value |
| **Elemental Triggers** | | |
| `trigger_type` | String | fire, ice, lightning, acid, gravity, explosive |
| `trigger_stacks` | Integer | Number of stacks applied (1-3) |
| `trigger_chance` | Float | Chance to apply (0.0-1.0) |
| **Visual/Audio** | | |
| `animation_id` | String | Reference to animation asset |
| `particle_effect` | String | Particle effect to play |
| `sound_effect` | String | Sound effect to play |

---

## Data-Driven Design Philosophy

**All ability balancing happens in CSV files**, not in code.

### Benefits:
1. **Easy Iteration**: Change damage values without touching code
2. **Rapid Balancing**: Adjust all abilities by editing CSV
3. **Content Creation**: Designers can create new abilities without programming
4. **Version Control**: CSV changes are easy to track and review
5. **Modding Support**: Community can create custom abilities

### Implementation Pattern:

```gdscript
# EffectResolver.gd (example)
func execute_ability(ship: Ship, ability_id: String):
    var ability = DataManager.get_ability(ability_id)

    # Apply Amplitude scaling to damage
    var final_damage = ability.damage * (1.0 + ship.amplitude / 100.0)

    # Apply Frequency scaling to duration
    var final_duration = ability.buff_duration * (1.0 + ship.frequency / 100.0)

    # Execute ability based on CSV data
    if ability.target_type == "area_self":
        apply_area_effect(ship.position, ability.target_radius, final_damage)
    elif ability.target_type == "enemy":
        apply_single_target(ship.current_target, final_damage)

    # Apply status effects if defined
    if ability.trigger_type != "":
        apply_status_effect(target, ability.trigger_type, ability.trigger_stacks)
```

---

## Ability Animation System

Each ability has an `animation_id` that references visual/audio assets.

**Animation Components:**
- **Casting Animation**: Ship's visual during ability cast
- **Projectile Animation**: Visual for projectile-based abilities
- **Impact Effect**: Particle effect on hit/activation
- **Area Effect**: Visual for AoE abilities (field, radius, etc.)
- **Sound Effect**: Audio cue for ability activation

**CSV Reference:**
- `animation_id`: "missile_launch", "shield_pulse", "cloak_activate", etc.
- `particle_effect`: "explosion", "shield_bubble", "fire_field", etc.
- `sound_effect`: "missile_whoosh", "shield_recharge", "stealth_activate", etc.

---

## Design Considerations

### Balance Goals

1. **Energy Cost = Power**: Stronger abilities cost more energy
2. **Cooldown Trade-offs**: Low-cost frequent abilities vs high-cost rare abilities
3. **Amplitude/Frequency Scaling**: Support ships leverage these stats for utility
4. **Counterplay**: Defensive abilities counter offensive abilities
5. **Synergy**: Abilities combo with weapons and ship roles

### Tactical Depth

- **Ability Timing**: When to use limited-use powerful abilities
- **Energy Management**: Deciding when to save vs spend energy
- **Combo Potential**: Chaining abilities with elemental triggers
- **Role Definition**: Abilities reinforce ship subclass identity
- **Fleet Coordination**: Abilities that buff allies encourage formation play

---

## Ability Examples (Placeholder)

Below are placeholder abilities to be populated with complete data:

### Damage Abilities
- **Missile Lock**: High-damage single-target missile
- **Barrage**: Rapid-fire burst attack
- **Burning Field**: AoE fire damage over time

### Buff Abilities
- **Tactical Command**: Area buff to nearby allies
- **Shield Battery**: Area shield restoration
- **Silent Running**: Self-buff with stealth and speed

### Defensive Abilities
- **Reactive Armor**: Shield gain with damage reflection
- **Shield Projection**: Create forward blocking obstacle

### Utility Abilities
- **Mark Target**: Increase damage taken by enemy

---

## Next Steps

**To Do:**
- [ ] Get complete ability descriptions from design notes
- [ ] Populate `ability_database.csv` with balanced values
- [ ] Define animation_id references
- [ ] Create ability icon assets
- [ ] Implement EffectResolver.gd system
- [ ] Test Amplitude/Frequency scaling
- [ ] Balance energy costs vs power levels

---

## Summary

The abilities system provides:
- **Data-driven design**: All abilities balanced from CSV
- **Amplitude/Frequency scaling**: Support builds leverage ability stats
- **Energy management**: Strategic resource spending
- **Diverse ability types**: Damage, buff, debuff, defensive, utility
- **Elemental integration**: Abilities trigger status effects and combos
- **Animation system**: Visual/audio feedback for all abilities

For ship ability stats, see [Ship Statistics Reference](ship-stats-reference.md).
For elemental triggers, see [Status Effects & Combos](status-effects-and-combos.md).
