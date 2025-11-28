# Ship Statistics Reference

Complete reference guide for all ship statistics in Any-Type-7.

**Related Documentation:**
- [Combat Formulas](combat-formulas.md) - Hit/crit/damage calculations
- [Status Effects & Combos](status-effects-and-combos.md) - Status effects and elemental combo system
- [Upgrade Relic System](upgrade-relic-system.md) - TFT-style combinatorial item crafting for stat enhancement
- [Weapons System](weapons-system.md) - Weapon equipment (distinct from upgrade relics)

---

## Overview

Ships in Any-Type-7 have **17 core statistics** that determine their combat performance, categorized into defensive, offensive, mobility, accuracy, critical hit, ability, and resistance stats.

---

## Defensive Stats

### Hull Points
- **Description**: The ship's primary health pool
- **Type**: Integer (positive)
- **Typical Range**: 50-500+
- **Mechanics**:
  - When Hull Points reach 0, the ship is destroyed
  - Hull damage is permanent during combat
  - Hull is repaired between combat encounters
  - Some effects (like Acid status) block hull recovery

### Shield Points
- **Description**: Temporary regenerating health
- **Type**: Integer (positive)
- **Typical Range**: 25-200+
- **Mechanics**:
  - Shields absorb damage before hull takes damage
  - Shields fully regenerate **between waves** (during tactical phase)
  - Shields do NOT regenerate during combat phase
  - When depleted, hull takes direct damage
  - Some effects (like Static status) block shield regeneration

### Size (Width × Height)
- **Description**: Grid space occupied by the ship
- **Type**: Two integers (width, height)
- **Typical Range**: 1×1 (small) to 3×5+ (capital ships)
- **Mechanics**:
  - **Width**: Number of files (horizontal squares) occupied
  - **Height**: Number of lanes (vertical squares) occupied
  - Larger ships can be hit from more angles but have more stats/abilities
  - Size affects placement constraints in the 15-lane grid
  - 2×2 or larger ships occupy their own grid, allowing smaller units to stack on top of them

### Armor
- **Description**: Percentage damage reduction on all incoming damage
- **Type**: Integer (percentage, can be negative)
- **Default**: 0
- **Typical Range**: 0-75 (most ships 0, frigates 15)
- **Maximum**: 75% damage reduction (cap)
- **Minimum**: No floor (can go negative for damage amplification)
- **Mechanics**:
  - Reduces final damage by X%
  - Formula: `Final Damage = Incoming Damage × (1 - Armor/100)`
  - **40 Armor** = 60% damage taken (40% reduction)
  - **15 Armor** = 85% damage taken (15% reduction)
  - **-20 Armor** = 120% damage taken (20% amplification)
  - Applies AFTER all other damage modifiers (crits, vulnerabilities, etc.)
  - Can be reduced permanently during combat by Acid status effect
  - Can go negative via certain status effects (especially Gravity)
  - Resets to base value between combats

---

## Offensive Stats

### Damage
- **Description**: Damage dealt per projectile from auto-attacks
- **Type**: Integer or Float (positive)
- **Typical Range**: 3-50+ per projectile
- **Mechanics**:
  - Base damage before critical hits or resistances
  - Each successful hit applies this damage
  - Multiplied by number of projectiles

### Projectiles
- **Description**: Number of projectiles fired per auto-attack
- **Type**: Integer (positive)
- **Typical Range**: 1-12
- **Mechanics**:
  - Each projectile rolls separately for hit/miss/crit
  - Total damage per attack = Damage × (Projectiles that hit)
  - Can spread across multiple targets or focus on one

### Attack Speed
- **Description**: Number of auto-attacks per second
- **Type**: Float (positive)
- **Typical Range**: 0.5-3.0 attacks/second
- **Mechanics**:
  - Attack Speed of 1.0 = 1 attack per second (1.0s cooldown)
  - Attack Speed of 2.0 = 2 attacks per second (0.5s cooldown)
  - Attack Speed of 0.5 = 1 attack per 2 seconds (2.0s cooldown)
  - Formula: `Attack Cooldown = 1.0 / Attack_Speed`

### Attack Range
- **Description**: Maximum distance the ship can attack (in grid squares)
- **Type**: Integer (positive)
- **Typical Range**: 3-15 squares
- **Mechanics**:
  - Ships engage enemies when within attack range
  - Range is measured in grid squares (files/lanes)
  - Longer range allows safer engagement

---

## Mobility

### Movement Speed
- **Description**: Speed the ship travels down its lane
- **Type**: Float (positive)
- **Typical Range**: 0.5-5.0 squares/second
- **Mechanics**:
  - Ships advance toward enemy spawners during combat
  - When no enemies in range, ship moves forward
  - When enemy in range, ship stops and attacks
  - Movement speed determines how quickly ships close distance

---

## Accuracy & Evasion System

### Accuracy
- **Description**: Increases chance to hit targets
- **Type**: Integer (can be negative, positive, or 0)
- **Default**: 0
- **Typical Range**: -10 to +50
- **Mechanics**:
  - Adds directly to hit chance percentage
  - Each point of Accuracy = +1% to hit
  - Formula: `Hit Chance = 100% - (Defender_Evasion - Attacker_Accuracy)`
  - See [Combat Formulas](combat-formulas.md) for full details

### Evasion
- **Description**: Decreases chance to be hit by attacks
- **Type**: Integer (can be negative, positive, or 0)
- **Default**: 0
- **Typical Range**: -10 to +50
- **Mechanics**:
  - Subtracts directly from attacker's hit chance
  - Each point of Evasion = -1% for attackers to hit
  - Can be reduced by status effects (Gravity, Pinned Down)

---

## Critical Hit System

### Precision
- **Description**: Increases critical hit chance
- **Type**: Integer (can be negative, positive, or 0)
- **Default**: 0
- **Typical Range**: 0-40
- **Mechanics**:
  - Base critical hit chance is 0%
  - Each point of Precision = +1% critical hit chance
  - Critical hits deal bonus damage (typically 2.0x)
  - Formula: `Crit Chance = Attacker_Precision - Defender_Reinforced_Armor`

### Reinforced Armor
- **Description**: Reduces incoming critical hit chance
- **Type**: Integer (can be negative, positive, or 0)
- **Default**: 0
- **Typical Range**: 0-30
- **Mechanics**:
  - Subtracts from attacker's critical hit chance
  - Each point of Reinforced Armor = -1% to attacker's crit chance
  - Can reduce crit chance to 0% (but not negative)
  - Hard-counters Precision builds

---

## Ability Stats

These stats only affect ships that have abilities (via upgrades or innate abilities).

### Energy Points
- **Description**: Maximum energy the ship can store
- **Type**: Integer (positive)
- **Typical Range**: 0-100
- **Mechanics**:
  - Energy bar that charges during combat
  - Used to cast ship abilities
  - Ships start combat with 0 energy
  - Charged by auto-attacking and taking damage
  - Ships without abilities do not generate energy

### Amplitude
- **Description**: Increases numerical effects of abilities
- **Type**: Integer (percentage)
- **Default**: 0
- **Typical Range**: 0-100+
- **Mechanics**:
  - Each point of Amplitude = +1% to ability number effects
  - Examples:
    - Ability that heals 50 HP with 20% Amplitude = 60 HP
    - Ability that deals 100 damage with 50% Amplitude = 150 damage
  - Only applies to ships with active abilities

### Frequency
- **Description**: Increases duration of ability effects
- **Type**: Integer (percentage)
- **Default**: 0
- **Typical Range**: 0-100+
- **Mechanics**:
  - Each point of Frequency = +1% to effect durations
  - Examples:
    - 10-second buff with 20% Frequency = 12 seconds
    - 5-second stun with 50% Frequency = 7.5 seconds
  - Only applies to abilities with duration-based effects

---

## Resistance

### Resilience
- **Description**: Chance to completely ignore status effects
- **Type**: Integer (percentage chance)
- **Default**: 0
- **Typical Range**: 0-75
- **Mechanics**:
  - Each point of Resilience = 1% chance to ignore a status effect
  - Rolls when a status effect is applied
  - If successful, effect is completely negated
  - Does not affect damage, only status effects (stuns, burns, slows, etc.)
  - See [Status Effects & Combos](status-effects-and-combos.md) for details

---

## CSV Database Structure

### ship_stat_database.csv Columns

```csv
ship_ID,ship_name,ship_size_class,ship_sub_class,tier,
hull_points,shield_points,armor,energy_points,
size_width,size_height,
attack_damage,attack_speed,projectile_count,attack_range,
movement_speed,
accuracy,evasion,
precision,reinforced_armor,
amplitude,frequency,resilience,
ship_ability,upgrade_slots,weapon_slots
```

### Column Reference

| Column | Type | Description |
|--------|------|-------------|
| `ship_ID` | String | Unique identifier (e.g., "basic_interceptor") |
| `ship_name` | String | Display name (e.g., "Striker") |
| `ship_size_class` | String | Size category (interceptor, fighter, frigate, etc.) |
| `ship_sub_class` | String | Subclass/role (Strike Class, Missile Platform, etc.) |
| `tier` | String | Rarity tier (basic, common, uncommon, rare, epic, legendary) |
| `hull_points` | Integer | Health pool |
| `shield_points` | Integer | Regenerating shields |
| `armor` | Integer | Percentage damage reduction |
| `energy_points` | Integer | Maximum energy for abilities |
| `size_width` | Integer | Horizontal grid squares occupied |
| `size_height` | Integer | Vertical grid squares occupied |
| `attack_damage` | Float | Damage per projectile |
| `attack_speed` | Float | Attacks per second |
| `projectile_count` | Integer | Projectiles per attack |
| `attack_range` | Integer | Attack range in grid squares |
| `movement_speed` | Float | Squares per second movement |
| `accuracy` | Integer | Hit chance modifier |
| `evasion` | Integer | Dodge chance modifier |
| `precision` | Integer | Critical hit chance |
| `reinforced_armor` | Integer | Anti-crit defense |
| `amplitude` | Integer | Ability power % increase |
| `frequency` | Integer | Ability duration % increase |
| `resilience` | Integer | Status effect resist % |
| `ship_ability` | String | Reference to ability_database.csv (if any) |
| `upgrade_slots` | Integer | Number of relic slots (typically 6 for all ships) |
| `weapon_slots` | Integer | Number of weapon slots (varies by ship class) |

---

## Stat Enhancement Systems

### Upgrade Relics (Combinatorial Item System)

Ships can equip **upgrade relics** to enhance their base statistics through a TFT-style combinatorial crafting system. Relics are **distinct from weapons** and provide passive stat bonuses and unique effects.

**System Overview:**
- **14 Base Tier 1 Items**: 10 stat items + 4 legacy items
- **105 Tier 2 Combinations**: Combine 2 Tier 1 items to create powerful relics
- **6 Relic Slots**: Each ship can equip up to 6 Tier 2 relics simultaneously
- **Infinite Scaling**: Relics can be upgraded to Tier 3, 4, 5+ for exponential power

**Base Tier 1 Items (Stat Items):**
1. **Chronometer**: +15% Attack Speed
2. **Amplifier**: +10 Attack Damage
3. **Aegis Plate**: +50 Shield Points
4. **Reinforced Hull**: +75 Hull Points
5. **Resonator**: +20% Ability Amplitude
6. **Dampener**: +15% Resilience
7. **Thruster Module**: +20% Movement Speed
8. **Precision Lens**: +10% Precision (crit chance)
9. **Capacitor**: +25 Starting Energy
10. **Ablative Coating**: +8 Armor

**Legacy Items (Tier 1):**
11. **Human Legacy**: +50 Hull Points (resilience/endurance theme)
12. **Alien Legacy**: +3 Hull Regen/sec (biotechnology/adaptation theme)
13. **Machine Legacy**: +50 Shield Points (synthetic/precision theme)
14. **Toxic Legacy**: +2 Energy Regen/sec (corruption/power theme)

**Combination Examples:**
- Chronometer + Chronometer = **Overclocked Targeting** (+30% Attack Speed, +3 Attack Range)
- Human Legacy + Amplifier = **Reinforced Firepower** (+50 Hull, +10 Damage, 15% chance no cooldown)
- Machine Legacy + Dampener = **Electronic Warfare** (+50 Shields, +15% Resilience, shields block status effects)

**Key Differences from Weapons:**
- **Relics**: Passive stat bonuses and unique effects (no active usage, stackable items)
- **Weapons**: Active equipment with attack patterns, projectile types, targeting behavior
- Ships equip both relics (6 slots) AND weapons (weapon slots vary by ship class)

**See**: [upgrade-relic-system.md](upgrade-relic-system.md) for complete relic combinations and crafting details

---

## Tier System & Equipment Slots

### Ship Tiers (Rarity)

Ships are categorized into **tiers** that control when players can acquire them and determine their upgrade slot capacity. Higher tier ships have more upgrade slots but maintain balance through availability timing.

**Tier Progression:**
- **Basic** - Starting ships, tutorial unlocks
- **Common** - Early game drops and blueprints
- **Uncommon** - Mid-game unlocks
- **Rare** - Late mid-game, special blueprints
- **Epic** - Late game, rare drops, unique bonuses
- **Legendary** - End game, unique ships with special mechanics

### Upgrade Slots by Tier

Upgrade slots allow installation of stat-boosting modules and equipment. Higher tier ships have more upgrade capacity.

| Tier | Upgrade Slots | Notes |
|------|--------------|-------|
| **Basic** | 1 | Tutorial/starter ships |
| **Common** | 1 | Standard early game |
| **Uncommon** | 2 | Mid-game power spike |
| **Rare** | 3 | Maximum upgrade capacity |
| **Epic** | 3 | Max slots + unique bonuses |
| **Legendary** | 3 | Max slots + legendary abilities |

**Note**: Epic and Legendary ships maintain 3 upgrade slots (same as Rare) but gain additional bonuses through unique abilities, higher base stats, or special mechanics not available to lower tiers.

### Weapon Slots by Class/Subclass

Weapon slots are determined by **ship subclass**, not tier. Weapon systems define a ship's attack patterns and combat role.

**Standard Weapon Slot Distribution:**

| Ship Class/Subclass | Base Slots | Total Slots | Notes |
|---------------------|-----------|-------------|-------|
| **Interceptor** (all) | 1 | 1 | Light armament, relies on speed/abilities |
| **Fighter** (standard) | 1 | 1 | Balanced loadout |
| **Fighter - Gunship** | 1 | 2 | Multi-weapon platform (+1 extra) |
| **Fighter - Strike Leader** | 1 | 2 | Command ship with dual weapons (+1 extra) |
| **Frigate** (non-support) | 1 | 2 | Heavy weapons platform (+1 extra) |
| **Frigate - Support** | 1 | 1 | Ability-focused, standard armament |
| **Frigate** (legendary) | 1 | 3 | Highest tier only (+2 extra as unique ability) |
| **Scouts/Disruptors** | 0-1 | 0-1 | May have no weapon slots (ability-focused) |

**Key Rules:**
- All ships start with **1 base weapon slot** (except specialized builds)
- **Gunships** and **Strike Leaders** gain +1 extra weapon slot (2 total)
- **Most Frigates** (except Support) gain +1 extra weapon slot (2 total)
- **Legendary tier Frigates** may have +2 extra weapon slots (3 total) as a unique ability
- **Scouts and Disruptors** may sacrifice weapon slots for abilities

### Equipment Slots Summary

**Upgrade Slots** = Determined by **tier** (rarity/progression)
**Weapon Slots** = Determined by **subclass** (tactical role)

This separation allows for diverse builds:
- A Common Gunship has 1 upgrade slot but 2 weapon slots (firepower focus)
- A Rare Scout has 3 upgrade slots but may have 0-1 weapon slots (stealth/support focus)
- A Legendary Flagship has 3 upgrade slots and 3 weapon slots (ultimate capital ship)

---

## Ship Size Mechanics

### Grid Placement

Ships occupy rectangular grid space defined by `size_width × size_height`:

- **Size 1×1**: Standard small ship (interceptor, fighter)
  - Occupies 1 lane (height) and 1 file (width)

- **Size 2×2**: Medium ship (frigate)
  - Occupies 2 lanes (height) and 2 files (width)

- **Size 3×3**: Large ship (cruiser)
  - Occupies 3 lanes (height) and 3 files (width)

### Placement Constraints

- Ships must fit within the 15-lane grid height
- Ships cannot overlap with other friendly ships
- Large ships occupy their own grid; fighters and interceptors fly over them

### Hit Detection

- Any projectile hitting any grid square occupied by the ship counts as a hit
- Larger ships are easier to hit (more surface area)
- Larger ships typically have more hull/shields to compensate

---

## Shield Mechanics

### Shield Behavior

1. **Damage Priority**: Shields absorb damage before hull
   - Incoming damage depletes shields first
   - Overflow damage carries over to hull

2. **Regeneration**: Shields regenerate between waves
   - Ships return to deployment zone after wave clear
   - Shields restore to maximum during tactical phase
   - Shields do NOT regenerate during combat phase

3. **Shield Break**: When shields reach 0
   - Ship continues fighting with hull only
   - No special penalty or mechanic
   - Shields will still regenerate at next tactical phase (if ship survives)

### Example Combat Flow

```
Wave 1 Start:
  Ship has 100 Hull, 50 Shields

During Combat:
  Takes 70 damage → Shields 0, Hull 80
  Takes 30 damage → Hull 50

Wave 1 Clear → Tactical Phase:
  Shields regenerate → Shields 50, Hull 50

Wave 2 Start:
  Ship has 50 Hull, 50 Shields (shields full, hull still damaged)
```

---

## Energy Mechanics

### Energy Generation

Ships generate energy during combat through:

1. **Auto-Attacks**: Gain energy when attacking
2. **Taking Damage**: Gain energy when damaged

Exact generation rates TBD (will be defined globally or per-ship).

### Energy Usage

- Ships start combat with 0 energy
- Energy charges up during combat
- When enough energy is accumulated, ship can cast its ability
- Ability costs are defined per-ability (not per-ship stat)

### Ships Without Abilities

- Ships without abilities do not generate energy
- Energy bar is not visible if that unit does not have abilities

---

## Ship Archetypes & Subclasses

Ships are organized by **size class** (Interceptor, Fighter, Frigate) with specialized **subclasses** that define tactical roles and abilities.

**Note**: This subclass system is expandable. New subclasses may be added dynamically as the game evolves to introduce new tactical roles and mechanics.

---

### Interceptor (1×1)

**General Characteristics:**
- **Focus**: High evasion, high speed, low health
- **Typical Stats**:
  - Hull: 40-60
  - Shields: 30-50
  - Evasion: 25-40
  - Movement Speed: 3.0-4.0

#### Scout (Interceptor Subclass)

**Role**: Forward reconnaissance and lane support
**Special Mechanics**:
- Deploy further down the combat grid (closer to enemy)
- Enhance attack range of all ships in their lane
- **Stealth**: Cannot be attacked unless attacker is adjacent OR scout takes damage from any source

**Scout Variants:**

- **Common Scout**
  - **Ability**: Cloak - Gain Stealth
  - **Passive**: Grant allies in row +1 attack range while cloaked

- **Uncommon Scout**
  - **Ability**: Cloak - Gain Stealth
  - **Passive**: Grant allies in row bonus damage while cloaked

- **Rare Scout**
  - **Ability**: TBD
  - **Passive**: TBD

- **Epic Scout**
  - **Ability**: Targeted Cloak - Gain Stealth
  - **Passive**: Grant allies in row critical hit chance while cloaked

#### Striker (Interceptor Subclass)

**Role**: High-damage single-target assassin
**Focus**:
- High attack damage
- High attack speed
- High evasion
- Specialized in eliminating single high-value targets

#### Disruptor (Interceptor Subclass)

**Role**: Ability-focused specialist
**Focus**:
- Small equipment loadout
- Powerful signature ability
- High-risk, high-reward tactical plays
- **Note**: Kamikaze units fall into this category (AI-only, player cannot build)

---

### Fighter (1×1)

**General Characteristics:**
- **Focus**: Balanced stats, medium range
- **Typical Stats**:
  - Hull: 60-90
  - Shields: 40-60
  - Accuracy/Evasion: 10-15 each
  - Attack Range: 8-12

#### Ranger (Fighter Subclass)

**Role**: Stealthy reconnaissance fighter
**Focus**:
- Similar to Scouts but slower
- Equipped with stealth capabilities
- Balanced between mobility and combat effectiveness

#### Gunship (Fighter Subclass)

**Role**: Heavy weapons platform
**Focus**:
- Multiple weapon systems
- Powerful auto-attacks
- High sustained damage output
- Lower mobility than other fighters

#### Hunter (Fighter Subclass)

**Role**: Anti-interceptor and anti-stealth specialist
**Focus**:
- High Precision stat
- Specialized in hunting down Interceptors
- Can detect and engage stealthed units
- Counters high-evasion targets

#### Guardian (Fighter Subclass)

**Role**: Defensive support and disruption
**Focus**:
- Prolonged engagements
- Abilities that disrupt attacks against them
- Defensive buffs and protective mechanics
- Sustain-oriented combat style

#### Strike Leader (Fighter Subclass)

**Role**: Tactical command and coordination
**Focus**:
- Buffs nearby Fighters and Interceptors
- Enables tactical options for allied units
- Force multiplier for small ship formations
- Command aura mechanics

---

### Frigate (2×2)

**General Characteristics:**
- **Focus**: High shields, reinforced armor, slower
- **Typical Stats**:
  - Hull: 100-150
  - Shields: 75-125
  - Reinforced Armor: 10-20
  - Movement Speed: 1.0-1.5

#### Support Frigate (Frigate Subclass)

**Role**: Shield generation and buff platform
**Focus**:
- Powerful energy generators
- Shield projection to allies
- Buff and support abilities
- Offensive support capabilities

#### Shield Frigate (Frigate Subclass)

**Role**: Frontline tank and damage absorber
**Focus**:
- Massive armor values
- Projectile blocking abilities
- Short auto-attack range (close-range tank)
- Defensive wall for allied formations
- **Differs from Support Frigates**: More tank, less utility

#### Corvette (Frigate Subclass)

**Role**: Heavy weapons assault ship
**Focus**:
- Heavy armaments (torpedos, laser cannons, missiles)
- Bonuses when using weapon systems
- High offensive firepower
- Weapon-specialized combat style

#### Flagship (Frigate Subclass)

**Role**: Command vessel with armor buffs
**Focus**:
- Powerful armor buffs for fleet
- Utility capabilities
- Fleet coordination mechanics
- Command presence on battlefield


---

### Support (varies)

**General Characteristics:**
- **Focus**: Ability-focused, uses Amplitude/Frequency
- **Typical Stats**:
  - Energy Points: 80-120
  - Amplitude: 20-50
  - Frequency: 20-50
  - Defensive stats moderate

**Note**: Support is a role modifier that can apply across size classes (Support Frigates, Support Cruisers, etc.)

---

## Stat Scaling & Balance

### Offensive vs. Defensive

- **High Accuracy** counters high evasion enemies
- **High Evasion** requires enemies to invest in accuracy
- **High Precision** requires enemies to have reinforced armor
- **High Reinforced Armor** hard-counters precision builds

### Size Trade-offs

- **Small ships** (1×1):
  - Hard to hit (small profile)
  - Lower stats (hull, shields, damage)
  - Fast and nimble (high movement speed)


- **Large ships** (2×2+):
  - Easy to hit (large profile)
  - Higher stats (hull, shields, damage)
  - Slow and powerful (low movement speed)


### Attack Speed vs. Damage

- **High Attack Speed, Low Damage**: Consistent chip damage, more hit rolls
- **Low Attack Speed, High Damage**: Burst damage, fewer hit rolls
- **Projectile Count**: Spreads risk across multiple rolls

---

## Summary

The ship stat system provides deep customization through 17 core statistics across offense, defense, mobility, and utility.

**Key Takeaways:**
- Hull & Shields & Armor = survivability
- Damage, Projectiles, Attack Speed = offense
- Accuracy vs. Evasion = hit chance contest
- Precision vs. Reinforced Armor = crit chance contest
- Amplitude & Frequency = ability power
- Resilience = status effect immunity

For combat calculations, see [Combat Formulas](combat-formulas.md).
For status effects and combos, see [Status Effects & Combos](status-effects-and-combos.md).
