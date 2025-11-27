# Weapons System Reference

Comprehensive guide to the weapon systems in Any-Type-7.

**Related Documentation:**
- [Ship Statistics Reference](ship-stats-reference.md) - Ship stats and equipment slots
- [Status Effects & Combos](status-effects-and-combos.md) - Elemental triggers and combos
- [Combat Formulas](combat-formulas.md) - Damage calculations

---

## Overview

Weapons are equippable systems that ships install in their **weapon slots**. Unlike abilities (which are innate to ships), weapons can be swapped, upgraded, and customized to fit different tactical roles.

**Key Concepts:**
- Weapons are installed in **weapon slots** (determined by ship subclass)
- Each weapon has unique firing patterns, mechanics, and resource systems
- Weapons can have **special qualities** (elemental triggers, bounce, multi-row, etc.)
- Some weapons use **ordinance** (limited ammo that recharges between waves)

---

## Weapon Firing Mechanics

### Standard Weapons

**Standard weapons** fire projectiles using the ship's base stats:
- Use ship's `attack_damage` stat
- Use ship's `attack_speed` stat
- Use ship's `projectile_count` stat
- Use ship's `attack_range` stat
- Use ship's `accuracy` and `precision` stats

Standard weapons are "fire and forget" - they shoot automatically when enemies are in range.

### Combat Movement & Firing Behavior

**Run and Gun Mechanics:**
- Most weapons fire **while moving** - ships do not stop to attack
- Ships only stop when actively auto-attacking with certain heavy weapons
- **Movement Rule**: Ships advance down lanes when no enemies in range, fire while moving when enemies are in range
- **Stationary Firing**: Some heavy weapons (torpedos, siege cannons) may force ships to stop and fire
- **Continuous Fire**: Light/medium weapons fire continuously while ships advance

**Weapon Movement Impact:**
| Weapon Type | Movement Behavior |
|-------------|-------------------|
| **Most weapons** (lasers, bullets, cannons, missiles) | Fire while moving at full speed |
| **Heavy weapons** (torpedos, siege) | Ship stops to fire, resumes movement after |
| **Aura weapons** | Always active, no impact on movement |
| **Drone weapons** | Deploy while moving |

**Note**: There are **no movement speed penalties** for most weapons. Ships maintain full movement speed while firing unless using specific heavy weapons that require stationary firing.

**Tactical Implications:**
- Most weapons support aggressive run-and-gun playstyle
- Heavy ordinance weapons create tactical "stop and shoot" moments
- Aura weapons reward aggressive positioning
- Speed builds synergize with continuous-fire weapons

### Weapon Stat Modifiers

Weapons can modify base ship stats:
- **+Damage**: Adds bonus damage per projectile
- **+Attack Speed**: Increases firing rate
- **+Range**: Extends attack range
- **+Accuracy**: Improves hit chance
- **+Precision**: Increases crit chance

**Example:**
- Ship has 8 base damage, 1.5 attack speed
- Weapon: "Plasma Cannon" (+3 damage, -0.3 attack speed)
- Result: 11 damage per shot, 1.2 attack speed

---

## Weapon Types & Mechanics

### 1. Ordinance Weapons

**Ordinance weapons** have limited ammunition that must be managed during combat.

**Mechanics:**
- **Ammo Count**: Each ordinance weapon has a maximum ammo capacity
- **Ammo Consumption**: Each attack consumes 1 ammo
- **Recharge Condition**: Ammo fully recharges **after each wave** if the player wipes the previous wave
- **All-or-Nothing**: Ordinance recharge is strictly binary - full recharge on wave clear, zero recharge on failure
- **Ability Refills**: Certain ship abilities may refill ordinance ammo mid-combat as a special mechanic
- **Ammo Depletion**: When ammo reaches 0, weapon cannot fire until recharged
- **Wave Failure Penalty**: If the player fails to clear a wave, ordinance does NOT recharge

**Tactical Use:**
- High burst damage for critical moments
- Requires careful ammo management across waves
- Rewards efficient wave clearing

**Examples:**
- **Torpedos**: Heavy damage, 3 ammo, slow firing
- **Missile Pods**: Medium damage, 8 ammo, fast firing
- **Cluster Bombs**: AoE damage, 5 ammo, multi-row targeting

**CSV Properties:**
- `is_ordinance`: true/false
- `max_ammo`: Integer (e.g., 3, 5, 8)

---

### 2. Multi-Row Weapons

**Multi-row weapons** target multiple lanes simultaneously, allowing ships to engage enemies across a wider area.

**Mechanics:**
- **Targeting Patterns**: Not always simple "width" - can be cones, diagonals, cross patterns, etc.
- **Pattern Types**:
  - **Wide**: Hits 3+ adjacent lanes (horizontal spread)
  - **Cone**: Expands outward (1 lane near, 3 lanes far)
  - **Diagonal**: Hits lanes in diagonal pattern
  - **Cross**: Hits ship's lane + lanes above/below
  - **Scattered**: Random pattern across multiple lanes

**Tactical Use:**
- Engage multiple enemies simultaneously
- Cover wide areas with single ship
- Less single-target damage, more area control

**Examples:**
- **Flak Cannon**: Wide 3-lane burst
- **Spread Missiles**: Cone pattern (1 → 2 → 3 lanes)
- **Chain Lightning**: Hits 1 lane, then bounces to 2 adjacent lanes

**CSV Properties:**
- `targeting_pattern`: String (wide, cone, diagonal, cross, scattered)
- `pattern_width`: Integer (number of lanes affected)
- `pattern_shape`: String (specific pattern definition)

---

### 3. Projectile Bounce Weapons

**Bounce weapons** have projectiles that hit multiple targets after the initial impact.

**Mechanics:**
- **Initial Hit**: Projectile hits primary target normally
- **Random Trajectory**: After hit, projectile flies off in a random direction
- **Collision Detection**: If the projectile crosses another valid target's path, it counts as a hit
- **Bounce Count**: Number of additional hits possible after initial impact
- **Bounce Upgrades**: Some upgrades increase bounce count (+1 bounce, +2 bounces, etc.)
- **No Guaranteed Hits**: Bounces are not seeking - they may miss if no targets are in the random flight path
- **Diminishing Damage** (optional): Each bounce may deal reduced damage

**Tactical Use:**
- Maximize damage in dense enemy formations
- Efficient against clustered enemies
- Less effective against single targets

**Examples:**
- **Ricochet Cannon**: 2 bounces, same damage each hit
- **Chain Lightning**: 3 bounces, -20% damage per bounce
- **Seeking Bullets**: 1 bounce, prioritizes low-health targets

**CSV Properties:**
- `bounce_count`: Integer (0 = no bounce, 1+ = number of bounces)
- `bounce_range`: Integer (grid squares for bounce targeting)
- `bounce_damage_modifier`: Float (1.0 = full damage, 0.8 = 80% per bounce, etc.)

---

### 4. Drone Weapons

**Drone weapons** deploy autonomous units that fight alongside the ship for a limited duration.

**Mechanics:**
- **Deployment**: Weapon "fires" a drone instead of a projectile
- **Duration**: Drone lasts for X seconds before expiring
- **Drone Behavior**: Drones have their own stats (HP, damage, attack speed, range)
- **Drone Limit**: No global drone cap - each ship ability/weapon that spawns drones creates only one drone at a time
- **Single Drone Rule**: If a ship ability spawns a drone, it can only have one active from that source
- **Refresh**: When duration expires or drone is destroyed, weapon can deploy a new drone

**Tactical Use:**
- Extend ship's effective firepower
- Create temporary reinforcements
- Drones can tank damage or provide utility

**Drone Types:**
- **Combat Drone**: Attacks enemies autonomously
- **Shield Drone**: Orbits ship, provides bonus shields
- **Repair Drone**: Heals nearby allied ships
- **Disruption Drone**: Applies debuffs to enemies

**Examples:**
- **Assault Drone Launcher**: Deploys 1 combat drone, 15s duration, light firepower
- **Repair Swarm**: Deploys 3 small repair drones, 10s duration, heals allies

**CSV Properties:**
- `is_drone_weapon`: true/false
- `drone_id`: Reference to drone_database.csv
- `drone_duration`: Float (seconds)
- `max_active_drones`: Integer (limit per weapon)

---

### 5. Aura Weapons

**Aura weapons** deal continuous damage to all enemies within a short range around the ship.

**Mechanics:**
- **Aura Range**: Damage radius (in grid squares)
- **Damage Over Time**: Deals damage per second to all enemies in range
- **No Projectiles**: No firing animation, continuous field effect
- **Range Limitation**: Very short range (1-3 grid squares)
- **Accuracy Bypass**: Aura damage ignores accuracy/evasion (always hits)
- **Aura Stacking**: Multiple ships with aura weapons can stack damage in overlapping areas

**Tactical Use:**
- Close-range defense
- Punish enemies that get too close
- Effective on slow, tanky ships that enemies swarm
- Combines well with high armor/hull builds

**Examples:**
- **Tesla Coil**: 2-square radius, lightning damage, applies Static status
- **Flame Projector**: 1-square radius, fire damage, applies Burn stacks
- **Pulse Field**: 3-square radius, low damage, slows enemies

**CSV Properties:**
- `is_aura_weapon`: true/false
- `aura_range`: Integer (grid squares)
- `aura_damage_per_second`: Float
- `aura_element`: String (fire, ice, lightning, etc.)

---

## Weapon Qualities

Weapons can have **additional qualities** that modify their behavior or add special effects.

### Elemental Triggers

Weapons can apply **elemental status effects** or trigger **elemental combos** (see [Status Effects & Combos](status-effects-and-combos.md)).

**Trigger Types:**
- **Fire**: Applies Burn stacks (2 damage/sec per stack)
- **Ice**: Applies Freeze stacks (-20% attack speed per stack)
- **Lightning**: Applies Static stacks (-3 energy/sec per stack)
- **Acid**: Applies Acid stacks (-1 armor/sec per stack)
- **Gravity**: Applies Gravity stacks (-30% movement & evasion per stack)
- **Explosive**: Detonates all active elemental effects on target

**Application Chance:**
- Weapons have a **trigger chance** (e.g., 30% chance to apply Burn on hit)
- Each projectile rolls independently for trigger application
- Multi-hit weapons (bounce, multi-row) can stack effects quickly

**Examples:**
- **Incendiary Cannon**: 40% chance to apply Burn, Fire trigger quality
- **Cryo Blaster**: 50% chance to apply Freeze, Ice trigger quality
- **Graviton Beam**: 100% chance to apply Gravity (but low damage)

**CSV Properties:**
- `trigger_type`: String (fire, ice, lightning, acid, gravity, explosive)
- `trigger_chance`: Float (0.0-1.0, percentage chance to apply)

### Piercing

**Piercing weapons** ignore a percentage of target armor.

**Mechanics:**
- Reduces target's effective armor by X%
- Example: 50% pierce vs. 40 armor target = treats as 20 armor

**CSV Properties:**
- `armor_pierce`: Float (0.0-1.0, percentage of armor ignored)

### Shieldbuster

**Shieldbuster weapons** deal bonus damage to shields.

**Mechanics:**
- Deals X% bonus damage to shields only
- Normal damage to hull

**CSV Properties:**
- `shield_damage_multiplier`: Float (1.5 = +50% damage to shields)

### Critical Strike Modifiers

Weapons can modify critical hit behavior.

**Mechanics:**
- **+Crit Chance**: Adds to ship's Precision stat
- **+Crit Damage**: Multiplies critical hit damage (default 2.0x)

**CSV Properties:**
- `bonus_precision`: Integer (added to ship's Precision)
- `crit_damage_multiplier`: Float (default 2.0, can be 2.5, 3.0, etc.)

---

## Weapon Combinations

Ships with **multiple weapon slots** can equip different weapons for tactical versatility.

**Example Loadouts:**

### Gunship (2 weapon slots)
- **Slot 1**: Plasma Cannon (high damage, standard firing)
- **Slot 2**: Flak Burst (multi-row, area control)
- **Synergy**: Single-target burst + area suppression

### Corvette (2-3 weapon slots)
- **Slot 1**: Torpedo Launcher (ordinance, heavy damage)
- **Slot 2**: Point Defense Laser (fast firing, anti-projectile)
- **Slot 3**: Shield Disruptor (shieldbuster quality)
- **Synergy**: Burst damage + defense + shield breaking

### Legendary Flagship (3 weapon slots)
- **Slot 1**: Graviton Beam (applies Gravity, slows enemies)
- **Slot 2**: Explosive Cannon (trigger detonation)
- **Slot 3**: Repair Drone Launcher (support)
- **Synergy**: Apply Gravity → Detonate → Sustain allies

---

## CSV Database Structure

### weapon_database.csv Columns

```csv
weapon_ID,weapon_name,weapon_type,weapon_description,
damage_modifier,attack_speed_modifier,range_modifier,accuracy_modifier,precision_modifier,
is_ordinance,max_ammo,
targeting_pattern,pattern_width,
bounce_count,bounce_range,bounce_damage_modifier,
is_drone_weapon,drone_id,drone_duration,max_active_drones,
is_aura_weapon,aura_range,aura_damage_per_second,
trigger_type,trigger_chance,
armor_pierce,shield_damage_multiplier,
bonus_precision,crit_damage_multiplier,
weapon_tier,upgrade_slots
```

### Column Reference

| Column | Type | Description |
|--------|------|-------------|
| `weapon_ID` | String | Unique identifier (e.g., "plasma_cannon") |
| `weapon_name` | String | Display name |
| `weapon_type` | String | Category (standard, ordinance, drone, aura, etc.) |
| `weapon_description` | String | Flavor text |
| `damage_modifier` | Integer | Bonus damage added to ship's base damage |
| `attack_speed_modifier` | Float | Bonus/penalty to ship's attack speed |
| `range_modifier` | Integer | Bonus range added to ship's base range |
| `accuracy_modifier` | Integer | Bonus accuracy |
| `precision_modifier` | Integer | Bonus precision (crit chance) |
| `is_ordinance` | Boolean | true if weapon uses ammo |
| `max_ammo` | Integer | Maximum ammo capacity (if ordinance) |
| `targeting_pattern` | String | Pattern type (wide, cone, diagonal, cross, etc.) |
| `pattern_width` | Integer | Number of lanes targeted |
| `bounce_count` | Integer | Number of bounces (0 = none) |
| `bounce_range` | Integer | Grid squares for bounce targeting |
| `bounce_damage_modifier` | Float | Damage multiplier per bounce (1.0 = full) |
| `is_drone_weapon` | Boolean | true if deploys drones |
| `drone_id` | String | Reference to drone_database.csv |
| `drone_duration` | Float | Seconds drone lasts |
| `max_active_drones` | Integer | Max drones from this weapon |
| `is_aura_weapon` | Boolean | true if aura-type |
| `aura_range` | Integer | Aura radius in grid squares |
| `aura_damage_per_second` | Float | DPS within aura |
| `trigger_type` | String | Elemental trigger (fire, ice, lightning, etc.) |
| `trigger_chance` | Float | Chance to apply trigger (0.0-1.0) |
| `armor_pierce` | Float | Percentage of armor ignored (0.0-1.0) |
| `shield_damage_multiplier` | Float | Damage multiplier vs shields |
| `bonus_precision` | Integer | Added to ship's Precision |
| `crit_damage_multiplier` | Float | Critical hit damage multiplier |
| `weapon_tier` | String | Rarity tier (common, uncommon, rare, etc.) |
| `upgrade_slots` | Integer | Weapon upgrade slots |

---

## Weapon Tiers (Rarity)

Like ships, weapons are categorized into **tiers** that control availability and power level.

**Tier Progression:**
- **Common** - Early game drops, basic blueprints
- **Uncommon** - Mid-game unlocks
- **Rare** - Late mid-game, special blueprints
- **Epic** - Late game, rare drops, unique mechanics
- **Legendary** - End game, unique weapons with special abilities

**Tier Effects on Weapons:**
- Higher tier weapons have better base stats (+damage, +range, etc.)
- Higher tier weapons may have more weapon upgrade slots
- Epic/Legendary weapons often have unique mechanics (extra bounces, special triggers, etc.)
- Weapon tier is independent of ship tier (Common ship can equip Legendary weapon if unlocked)

---

## Weapon Upgrade Slots

Some weapons have their own **upgrade slots** for weapon-specific modifications.

**Weapon Upgrades:**
- **+Ammo Capacity** (ordinance weapons): +2 max ammo
- **+Bounce** (bounce weapons): +1 bounce count
- **+Aura Range** (aura weapons): +1 grid square radius
- **+Trigger Chance**: +10% elemental trigger chance
- **+Drone Duration**: +5 seconds drone lifespan

**Upgrade Slots by Weapon Tier:**
| Tier | Weapon Upgrade Slots |
|------|---------------------|
| **Common** | 0-1 |
| **Uncommon** | 1 |
| **Rare** | 1-2 |
| **Epic** | 2 |
| **Legendary** | 2-3 |

Weapon upgrades are separate from ship upgrades, allowing deep customization.

---

## Design Considerations

### Balance Goals

1. **No Strictly Superior Weapons**: Each weapon type has strengths and weaknesses
2. **Ordinance Risk/Reward**: High power, limited ammo, requires wave clears
3. **Multi-Row Trade-off**: Area coverage vs single-target damage
4. **Bounce Efficiency**: Strong vs groups, weak vs single targets
5. **Drone Sustainability**: Temporary power spike, requires cooldown
6. **Aura Range Limitation**: High DPS but extreme close range

### Tactical Depth

- **Weapon slot scarcity** forces meaningful choices
- **Subclass defines slots**: Gunships/Corvettes get more weapons
- **Synergy opportunities**: Combine weapons for combos (Gravity + Explosive)
- **Counter-play**: Anti-shield, anti-armor, anti-evasion weapons
- **Build diversity**: Speed + Aura (kamikaze), Range + Bounce (sniper), Ordinance + Drones (burst)

---

## Next Steps

**To Do:**
- [ ] Populate `weapon_database.csv` with example weapons
- [ ] Define drone stat system (`drone_database.csv`)
- [ ] Create weapon upgrade database
- [ ] Implement weapon firing patterns (cone, diagonal, etc.)
- [ ] Balance ordinance ammo counts vs damage
- [ ] Design weapon acquisition system (drops, blueprints, crafting)

---

## Summary

The weapons system provides deep tactical customization through:
- **5 core mechanics**: Ordinance, Multi-row, Bounce, Drone, Aura
- **Special qualities**: Elemental triggers, piercing, shieldbuster, crit modifiers
- **Equipment slots**: Determined by ship subclass
- **Upgrade systems**: Both ship upgrades and weapon-specific upgrades
- **Synergy design**: Combine weapons for elemental combos and tactical combos

For ship equipment slots, see [Ship Statistics Reference](ship-stats-reference.md).
For elemental triggers and combos, see [Status Effects & Combos](status-effects-and-combos.md).
