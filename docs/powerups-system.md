# Powerups System Reference

Comprehensive guide to combat powerups in Any-Type-7.

**Related Documentation:**
- [Combat Formulas](combat-formulas.md) - Combat mechanics and damage calculations
- [Ship Statistics Reference](ship-stats-reference.md) - Ship stats affected by powerups
- [Weapons System](weapons-system.md) - Weapon mechanics and powerup interactions
- [Abilities System](abilities-system.md) - Ability mechanics

---

## Overview

**Powerups** are temporary item drops that appear during combat when enemies are destroyed. Ships can pick them up by moving over them, gaining immediate bonuses ranging from stat boosts to powerful one-time attacks.

**Key Concepts:**
- Powerups **drop randomly** when enemies are destroyed
- Ships pick up powerups by **moving over them** on the grid
- Most powerups provide **temporary buffs** (10-30 seconds)
- Some powerups grant **instant effects** (bombs, capital ship strikes)
- Some powerups last **for the rest of combat** (permanent buffs)
- Powerups are **first-come, first-served** - any allied ship can pick them up

---

## Powerup Mechanics

### Drop System

**Enemy Destruction:**
- When an enemy ship is destroyed, there's a **chance** to drop a powerup
- Drop chance varies by enemy type (basic enemies: 5-10%, elite enemies: 20-30%, bosses: 100%)
- Powerup type is randomly selected from available pool
- Powerup spawns at the destroyed enemy's position

**Drop Visualization:**
- Powerups appear as glowing icons on the combat grid
- Each powerup has a unique color/icon for identification
- Powerups remain on the field for **15 seconds** before despawning
- Visual timer shows remaining pickup time

**Drop Rates:**
| Enemy Type | Drop Chance | Powerup Pool |
|------------|-------------|--------------|
| Basic Enemy | 8% | Common powerups only |
| Elite Enemy | 25% | Common + Rare powerups |
| Boss Enemy | 100% | All powerups, weighted toward rare |
| Wave Clear Bonus | 50% | Guaranteed 1-2 powerups on wave clear |

### Pickup System

**Collision Detection:**
- Ship picks up powerup when its grid position **overlaps** the powerup
- Pickup is **automatic** - no player input required
- Powerup applies effect **immediately** on pickup
- Visual/audio feedback confirms pickup

**Pickup Priority:**
- **Any allied ship** can pick up powerups (not locked to specific ships)
- Ships moving faster have better chance to reach powerups first
- Strategic positioning: Place fast interceptors near enemy spawns for powerup priority

**Despawn Timer:**
- Powerups last **15 seconds** on the field
- After 15s, powerup disappears with fade effect
- Missed powerups do not respawn

---

## Powerup Types

Powerups fall into several categories based on their effects:

### 1. Stat Buff Powerups

**Temporary stat increases for duration**

**Examples:**
- **Overcharge**: Double attack speed
- **Phoenix Attacks**: Attack adjacent lanes simultaneously

**Mechanics:**
- Buff applies to the ship that picked it up
- Duration countdown begins immediately
- Stacks additively with other buffs
- Buff expires after duration or combat ends

### 2. Permanent Combat Buffs

**Buffs that last until combat ends**

**Examples:**
- **Projectile Augmentation**: +1 projectile permanently for this combat

**Mechanics:**
- Effect lasts entire combat (all remaining waves)
- Does not expire until combat ends
- Multiple pickups stack (picking up 2 = +2 projectiles)
- Resets between combat encounters

### 3. Instant Attack Powerups

**One-time powerful attacks triggered on pickup**

**Examples:**
- **Cluster Bomb**: Map-wide rolling explosion
- **Crucible Ray**: Capital ship orbital strike

**Mechanics:**
- Attack executes immediately on pickup
- No cooldown or energy cost
- Cannot be saved or delayed
- Damage scales with wave difficulty

### 4. Drone Powerups

**Deploy support drones temporarily**

**Examples:**
- **Repair Drone**: Heals 15 hull/sec for 10s
- **Shield Drone**: Restores 25 shields/sec for 10s

**Mechanics:**
- Drone spawns at pickup ship's position
- Follows pickup ship (or stays stationary, depending on drone type)
- Duration countdown independent of ship
- Drone can be destroyed by enemy fire

### 5. Defensive Powerups

**Protective effects and survivability**

**Examples:**
- **Remote Shield**: Invincibility for 10 seconds

**Mechanics:**
- Applies defensive buff to pickup ship
- Can turn tide of battle during critical moments
- Visual indicator shows protected status

### 6. Utility Powerups

**Strategic effects beyond direct combat**

**Examples:**
- **Scanner Sweep**: Reveal cloaked enemies for 30s
- **Magnetic Sweep**: Double combat rewards for 10s

**Mechanics:**
- Affects battlefield state or meta-progression
- Rewards tactical decision-making (when to pick up vs save for ally)
- Some effects benefit entire fleet

---

## Powerup Database

### Powerup Details

#### Overcharge
- **Type**: Stat Buff
- **Effect**: Double attack speed for 10 seconds
- **Target**: Pickup ship
- **Rarity**: Common
- **Tactical Use**: Maximize DPS during critical wave moments
- **Icon Color**: Yellow/Orange

#### Projectile Augmentation
- **Type**: Permanent Combat Buff
- **Effect**: Gain +1 projectile for rest of combat
- **Target**: Pickup ship
- **Rarity**: Rare
- **Tactical Use**: Long-term DPS increase, prioritize on multi-weapon ships
- **Stacking**: Yes (multiple pickups = multiple projectiles)
- **Icon Color**: Blue

#### Cluster Bomb
- **Type**: Instant Attack
- **Effect**: Rolling explosion deals moderate damage (30-50) across entire map
- **Target**: All enemies
- **Rarity**: Uncommon
- **Tactical Use**: Wave clearing, weakening clustered enemies
- **Damage**: 40 base (scales with wave)
- **Icon Color**: Red

#### Crucible Ray
- **Type**: Instant Attack
- **Effect**: Capital ship fires devastating beam at pickup ship's current target
- **Target**: Single enemy (current target of pickup ship)
- **Rarity**: Rare
- **Tactical Use**: Eliminate high-priority targets (bosses, elites)
- **Damage**: 150 base (scales with wave)
- **Icon Color**: Purple

#### Repair Drone
- **Type**: Drone
- **Effect**: Deploys drone that heals pickup ship for 15 hull/sec for 10 seconds
- **Target**: Pickup ship
- **Rarity**: Common
- **Tactical Use**: Emergency healing for damaged ships
- **Total Healing**: 150 hull over 10 seconds
- **Drone HP**: 30
- **Icon Color**: Green

#### Shield Drone
- **Type**: Drone
- **Effect**: Deploys drone that restores pickup ship's shields at 25/sec for 10 seconds
- **Target**: Pickup ship
- **Rarity**: Common
- **Tactical Use**: Shield recovery between waves
- **Total Restore**: 250 shields over 10 seconds
- **Drone HP**: 30
- **Icon Color**: Cyan

#### Remote Shield
- **Type**: Defensive
- **Effect**: Gain invincibility for 10 seconds
- **Target**: Pickup ship
- **Rarity**: Rare
- **Tactical Use**: Survive overwhelming damage, push aggressive positions
- **Invincibility**: Complete immunity to all damage
- **Icon Color**: White/Gold

#### Scanner Sweep
- **Type**: Utility
- **Effect**: Reveal all cloaked/stealth units for 30 seconds
- **Target**: All enemies (battlefield-wide)
- **Rarity**: Uncommon
- **Tactical Use**: Counter stealth enemies, reveal ambushes
- **Duration**: 30 seconds
- **Icon Color**: Light Blue

#### Magnetic Sweep
- **Type**: Utility
- **Effect**: Double all combat rewards (metal, crystals, salvage) from ship destruction for 10 seconds
- **Target**: Entire fleet (reward multiplier)
- **Rarity**: Uncommon
- **Tactical Use**: Maximize resource gain during high-kill phases
- **Multiplier**: 2x rewards
- **Duration**: 10 seconds
- **Icon Color**: Gold

#### Phoenix Attacks
- **Type**: Stat Buff
- **Effect**: Ship fires additional projectiles down adjacent lanes (above and below) for 10 seconds
- **Target**: Pickup ship
- **Rarity**: Uncommon
- **Tactical Use**: Multi-lane coverage, area suppression
- **Lanes Affected**: Ship's lane + 1 above + 1 below (3 total)
- **Duration**: 10 seconds
- **Icon Color**: Orange/Red

---

## Powerup Interactions

### Stacking Rules

**Same Powerup Multiple Pickups:**
- **Stat Buffs**: Duration refreshes (doesn't stack duration, resets to full)
- **Permanent Buffs**: Effects stack (2x Projectile Augmentation = +2 projectiles)
- **Instant Attacks**: Each pickup triggers separate attack
- **Drones**: Multiple drones can exist simultaneously
- **Invincibility**: Duration refreshes (doesn't extend)

**Different Powerups:**
- All powerup effects stack with each other
- Ship can have multiple buffs active simultaneously
- Example: Overcharge + Phoenix Attacks = double attack speed on 3 lanes

### Powerups + Ship Abilities

Powerups interact with ship abilities:
- **Overcharge** affects ability energy generation (faster attacks = more energy)
- **Projectile Augmentation** affects weapons, not abilities
- **Invincibility** blocks damage but doesn't prevent status effects from abilities
- **Scanner Sweep** reveals stealthy Scout ships

### Powerups + Weapon Systems

Powerups affect equipped weapons:
- **Overcharge** doubles attack speed of all equipped weapons
- **Projectile Augmentation** adds projectile to primary weapon only
- **Phoenix Attacks** applies to all weapon fire
- Ordinance weapons benefit from **Overcharge** (faster reload)

---

## Strategic Depth

### Pickup Decisions

**Who Should Pick It Up?**
- **Overcharge**: Give to high-damage ships (Strikers, Gunships)
- **Projectile Augmentation**: Prioritize ships with weapon slots
- **Repair/Shield Drones**: Send to damaged ships
- **Invincibility**: Use on tanks pushing forward or ships about to die
- **Cluster Bomb**: Any ship can pick up for instant effect
- **Magnetic Sweep**: Pick up right before killing elite enemies or clearing wave

### Positioning for Powerups

**Fast Ships = Powerup Priority:**
- Interceptors with high movement speed reach powerups first
- Position fast ships near enemy spawn points
- Use Scouts to grab powerups, then return to support role

**Risk vs Reward:**
- Powerups often drop in dangerous forward positions
- Sending fragile ship to grab powerup may result in destruction
- Weigh powerup value vs ship loss risk

### Timing Considerations

**15-Second Despawn Timer:**
- Must reach powerup quickly or lose it
- Plan movement paths to intercept drops
- Don't overextend just for a common powerup

**Wave Clear Bonuses:**
- Clearing waves quickly = more powerup opportunities
- Save powerful abilities to secure wave clears
- Magnetic Sweep before wave clear = double rewards

---

## CSV Database Structure

### powerups_database.csv Columns

```csv
powerup_ID,powerup_name,powerup_type,rarity,duration,
effect_target,effect_stat,effect_value,effect_multiplier,
instant_damage,instant_damage_type,instant_target,
drone_id,drone_duration,drone_hp,
special_mechanic,
despawn_timer,icon_sprite,icon_color,particle_effect,sound_effect,
description
```

### Column Reference

| Column | Type | Description |
|--------|------|-------------|
| `powerup_ID` | String | Unique identifier (e.g., "overcharge") |
| `powerup_name` | String | Display name |
| `powerup_type` | String | stat_buff, permanent_buff, instant_attack, drone, defensive, utility |
| `rarity` | String | common, uncommon, rare |
| `duration` | Float | Effect duration in seconds (0 = instant) |
| **Effect Properties** | | |
| `effect_target` | String | pickup_ship, all_allies, all_enemies, battlefield |
| `effect_stat` | String | attack_speed, projectiles, damage, etc. |
| `effect_value` | Integer/Float | Flat value added/modified |
| `effect_multiplier` | Float | Multiplier (2.0 = double, 1.5 = +50%) |
| **Instant Attack Properties** | | |
| `instant_damage` | Integer | Damage dealt (if instant attack) |
| `instant_damage_type` | String | physical, fire, explosive, etc. |
| `instant_target` | String | single, area, all_enemies, lane |
| **Drone Properties** | | |
| `drone_id` | String | Reference to drone_database.csv |
| `drone_duration` | Float | How long drone lasts |
| `drone_hp` | Integer | Drone health |
| **Other Properties** | | |
| `special_mechanic` | String | Custom mechanics (invincibility, reveal_stealth, double_rewards) |
| `despawn_timer` | Float | Seconds before powerup despawns from field (default 15) |
| **Visual/Audio** | | |
| `icon_sprite` | String | Sprite path for powerup icon |
| `icon_color` | String | Hex color for glow effect |
| `particle_effect` | String | Particle effect on pickup |
| `sound_effect` | String | Sound effect on pickup |
| `description` | String | Text description |

---

## Design Considerations

### Balance Goals

1. **Risk/Reward**: Powerups drop in dangerous positions, forcing tactical choices
2. **Tempo Swings**: Powerups can turn losing battles into victories
3. **Build Diversity**: Different ships benefit from different powerups
4. **Resource Economy**: Magnetic Sweep adds resource management layer
5. **Counterplay**: Scanner Sweep counters stealth strategies

### Drop Rate Tuning

- Too frequent: Powerups feel meaningless, constant buffs normalize gameplay
- Too rare: Players forget they exist, no tactical engagement
- **Sweet Spot**: ~1-2 powerups per wave, feels rewarding without overwhelming

### Visual Clarity

- Powerups must be **instantly recognizable** on busy battlefield
- Color coding by type (damage = red, heal = green, utility = blue)
- Large icons with glow effects
- Audio cues for drops and pickups

---

## Implementation Notes

### Powerup Lifecycle

1. **Spawn**: Enemy destroyed → drop chance roll → spawn powerup at position
2. **Idle**: Powerup sits on grid with despawn timer (15s)
3. **Pickup**: Ship overlaps powerup → apply effect → destroy powerup
4. **Despawn**: Timer expires → fade out → destroy powerup

### Code Structure

```gdscript
# PowerupManager.gd (example)
func spawn_powerup(position: Vector2, powerup_id: String):
    var powerup = DataManager.get_powerup(powerup_id)
    var instance = powerup_scene.instantiate()
    instance.position = position
    instance.powerup_data = powerup
    instance.despawn_timer = powerup.despawn_timer
    add_child(instance)

func on_ship_overlap_powerup(ship: Ship, powerup: Powerup):
    apply_powerup_effect(ship, powerup.powerup_data)
    EventBus.powerup_collected.emit(powerup.powerup_id, ship)
    powerup.queue_free()

func apply_powerup_effect(ship: Ship, powerup_data: Dictionary):
    match powerup_data.powerup_type:
        "stat_buff":
            ship.apply_buff(powerup_data.effect_stat, powerup_data.effect_multiplier, powerup_data.duration)
        "instant_attack":
            execute_instant_attack(powerup_data.instant_damage, powerup_data.instant_target)
        "drone":
            spawn_drone(ship, powerup_data.drone_id, powerup_data.drone_duration)
```

---

## Summary

The powerups system adds dynamic tactical layers to combat:
- **Random drops** create emergent gameplay moments
- **Pickup positioning** rewards strategic ship placement
- **Diverse effects** (buffs, attacks, drones, utility)
- **Risk/reward** decisions (chase powerup or stay safe?)
- **Build synergies** (different ships benefit differently)
- **Resource economy** (Magnetic Sweep for meta-progression)

Powerups transform static autobattler combat into dynamic, reactive gameplay where positioning and timing matter beyond initial deployment.

For combat mechanics, see [Combat Formulas](combat-formulas.md).
For ship stats affected by powerups, see [Ship Statistics Reference](ship-stats-reference.md).
