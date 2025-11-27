# Status Effects & Elemental Combos

This document defines all status effects, elemental combos, and the trigger system for Any-Type-7.

---

## Table of Contents

1. [Status Effect Categories](#status-effect-categories)
2. [Elemental Status Effects](#elemental-status-effects)
3. [Control Status Effects](#control-status-effects)
4. [Resilience & Resistance](#resilience--resistance)
5. [Elemental Combos & Trigger System](#elemental-combos--trigger-system)
6. [Cross-Element Combo Matrix](#cross-element-combo-matrix)
7. [Implementation Notes](#implementation-notes)

---

## Status Effect Categories

Status effects are divided into two main categories:

1. **Elemental Status Effects** - Stackable (max 3 stacks), used for elemental combos
2. **Control Status Effects** - Non-stackable, ability-specific durations

---

## Elemental Status Effects

These status effects can stack up to **3 times** on a single ship. Each stack is tracked independently and expires separately. When elemental combos are triggered, all stacks are consumed and stripped from the target.

### Burn (Fire Element)

- **Effect**: Deals **2 fire damage per second** per stack
- **Duration**: Stack-specific (defined by source ability/weapon)
- **Combo Element**: Fire
- **Visual**: Flames/heat distortion on ship
- **Max Stacks**: 3

**Example**: 3 stacks of Burn = 6 fire damage/second

---

### Freeze (Ice Element)

- **Effect**: Reduces **attack speed by 20%** per stack
- **Duration**: Stack-specific (defined by source ability/weapon)
- **Combo Element**: Ice/Cold
- **Visual**: Ice crystals/frost on ship
- **Max Stacks**: 3

**Example**: 3 stacks of Freeze = -60% attack speed (ship attacks at 40% normal speed)

---

### Static (Lightning Element)

- **Effect**:
  - Drains **3 energy per second** per stack
  - **Blocks shield regeneration** (ship cannot gain shields while Static is active)
- **Duration**: Stack-specific (defined by source ability/weapon)
- **Combo Element**: Lightning/Electric
- **Visual**: Electrical arcs/sparks on ship
- **Max Stacks**: 3

**Example**: 3 stacks of Static = -9 energy/sec + no shield regen

---

### Acid (Corrosive Element)

- **Effect**:
  - Reduces **Armor stat by 1 per second** per stack (permanent for combat duration)
  - **Blocks hull point recovery** (ship cannot heal hull while Acid is active)
- **Duration**: **10 seconds** per stack
- **Combo Element**: Corrosive/Poison
- **Visual**: Corrosive dripping/melting hull
- **Max Stacks**: 3
- **Armor Mechanics**:
  - Armor reduction is permanent until combat ends
  - Can reduce armor below 0 (causing damage amplification)
  - Armor resets to base value between combats

**Example**: 3 stacks of Acid on a Frigate (15 base armor)
- After 5 seconds: 15 - (3 × 5) = 0 armor (no reduction)
- After 7 seconds: 15 - (3 × 7) = -6 armor (6% damage amplification!)
- After 10 seconds: Acid expires, armor frozen at -15 for rest of combat

---

### Gravity (Gravity Element)

- **Effect**:
  - Reduces **movement speed and evasion by 30%** per stack
  - Some Gravity abilities can also reduce **Armor** (causing damage amplification)
- **Duration**: Stack-specific (defined by source ability/weapon)
- **Combo Element**: Gravity/Dark Matter
- **Visual**: Gravitational distortion/purple aura
- **Max Stacks**: 3

**Example**: 3 stacks of Gravity = -90% movement speed and -90% evasion

**Note**: Certain cross-element combos involving Gravity may apply armor debuffs, pushing targets into negative armor for damage amplification.

---

## Stack Behavior

- **Maximum Stacks**: 3 per elemental type per ship
- **Independent Expiration**: Each stack expires based on its own timer
- **Separate Tracking**: Stack 1 applied at 0s (expires 5s), Stack 2 applied at 2s (expires 7s), etc.
- **Combo Consumption**: When an elemental combo is triggered, **all stacks are removed**
- **Combo Scaling**: More stacks = stronger combo effect (formula: Base × (1 + Stacks × 0.5))

---

## Control Status Effects

These effects do not stack and cannot trigger elemental combos. Duration is defined by the ability or weapon that applies them.

### Stun

- **Effect**:
  - Ship **cannot move, attack, or cast abilities**
  - Attacks against stunned targets deal **+25% damage**
- **Duration**: Ability-specific (typically 1-3 seconds)
- **Resilience**: Can be blocked by Resilience stat
- **Visual**: Electricity/stasis field around ship

---

### Pinned Down / Root

- **Effect**:
  - Ship **cannot move**
  - Loses **25 evasion**
- **Duration**: Ability-specific (typically 2-4 seconds)
- **Resilience**: Can be blocked by Resilience stat
- **Visual**: Harpoons/tether beams holding ship in place

---

### Blind

- **Effect**: Ship **cannot auto-attack** (abilities still functional)
- **Duration**: Ability-specific (typically 3-5 seconds)
- **Resilience**: Can be blocked by Resilience stat
- **Visual**: Blinding light/targeting system disruption

---

### Malfunction

- **Effect**: Ship **cannot cast abilities or activate non-auto-attack weapons**
- **Duration**: Ability-specific (typically 3-4 seconds)
- **Resilience**: Can be blocked by Resilience stat
- **Visual**: System errors/sparking systems
- **Note**: Often applied by cross-element combos (Freeze + Fire = Steam Explosion)

---

### Energy Drain

- **Effect**: Steals **5 energy per second** and transfers it to the caster
- **Duration**: Ability-specific (typically 3-5 seconds)
- **Resilience**: Can be blocked by Resilience stat
- **Visual**: Energy siphon beam connecting ships
- **Note**: Unique status effect often applied by cross-element combos (Static + Ice, Static + Acid)

---

### Additional Control Effects

| Effect | Description | Can Block? |
|--------|-------------|-----------|
| **Slow** | Reduces movement speed by 50% | Yes (Resilience) |
| **Weaken** | Reduces damage dealt by 30% | Yes (Resilience) |
| **Vulnerable** | Increases damage taken by 25% | Yes (Resilience) |
| **Silence** | Cannot cast abilities | Yes (Resilience) |
| **Disarm** | Cannot auto-attack or use weapons | Yes (Resilience) |
| **Taunt** | Forced to attack the taunting unit | Yes (Resilience) |
| **Fear** | Forced to move away from source | Yes (Resilience) |

---

## Resilience & Resistance

### How Resilience Works

Resilience provides a **% chance to completely ignore** incoming status effects.

When a status effect is applied:
1. Roll d100
2. If roll ≤ Resilience, status effect is **completely negated**
3. If roll > Resilience, status effect is **applied normally**

**Example**: Ship has 30 Resilience
- 30% chance to ignore any incoming status effect
- 70% chance status effect applies normally

### What Resilience Blocks

**Elemental Status Effects:**
- Burn, Freeze, Static, Acid, Gravity

**Control Status Effects:**
- Stun, Pinned Down, Blind, Malfunction, Energy Drain
- Slow, Weaken, Vulnerable, Silence, Disarm, Root, Taunt, Fear

### What Resilience Does NOT Block

- Direct damage from attacks
- Critical hits
- Miss chance (that's handled by Evasion)
- Elemental combo damage (combos bypass Resilience)

---

## Elemental Combos & Trigger System

Elemental combos are triggered by abilities with the **Trigger** keyword. When a trigger ability hits a target with elemental status effect stacks, those status effects detonate for massive burst damage.

### Trigger Keyword Mechanics

**Core Rules:**

1. **Trigger abilities** detonate elemental status effects on hit
2. **All stacks are consumed** when triggered (removed from target)
3. **Combo damage scales** with number of stacks present
4. **Multiple status effects** trigger sequentially (one after another)
5. **Setup before Trigger**: Trigger checks for combos BEFORE applying new status stacks

---

## Trigger Types

### Trigger (Explosive) - Universal Detonation

The most common trigger type. Detonates **any** elemental status effect for damage matching that element.

**Mechanics:**
- Explodes status effects for moderate damage matching the element type
- Damage scales with number of stacks
- Can detonate multiple different elements on the same target
- Each element detonates one after another (sequential)

**Example:**
```
Target has: 3 Burn, 2 Freeze, 1 Static
Rocket hits with Trigger (Explosive)

Result:
1. Burn explodes → 20 × (1 + 3 × 0.5) = 50 fire damage
2. Freeze explodes → 15 × (1 + 2 × 0.5) = 30 cold damage
3. Static explodes → 18 × (1 + 1 × 0.5) = 27 lightning damage
Total: 30 (rocket) + 50 + 30 + 27 = 137 damage
All status effects removed
```

---

### Trigger (Element-Specific) - Special Interactions

Triggers can be element-specific (Fire, Ice, Lightning, Acid, Gravity) for unique effects.

**Mechanics:**
- Triggers combos with ALL elements present (not just matching)
- Creates unique cross-element interactions
- Can apply NEW stacks after detonation
- Hybrid effects (damage + utility)

---

## Same-Element Combos

When a trigger matches the status effect element, special enhanced effects occur.

| Combo | Base Damage | Scaling | Special Effect |
|-------|-------------|---------|----------------|
| **Fire + Burn** | 25 | 0.6 | Reapply 3 Burn stacks |
| **Ice + Freeze** | 20 | 0.6 | Apply Stun for 1 second |
| **Lightning + Static** | 23 | 0.6 | Chain to all enemies with Static within 5 squares |
| **Acid + Acid** | 28 | 0.6 | Reapply 3 Acid stacks |
| **Gravity + Gravity** | 22 | 0.6 | Pull all nearby enemies into this ship's row |

---

## Cross-Element Combo Matrix

All 25 cross-element combinations with unique effects.

### Fire Trigger Cross-Combos

| Status Effect | Combo Name | Damage | Effect |
|---------------|------------|--------|--------|
| Freeze | Steam Explosion | 22 | Apply Malfunction for 3 seconds |
| Static | Plasma Burst | 24 | Deal bonus damage and apply 2 Burn stacks |
| Acid | Toxic Fumes | 23 | Leave poisonous cloud dealing 10 dmg/sec for 5s |
| Gravity | Stellar Collapse | 25 | Pull nearby enemies 2 squares and apply 1 Burn |

### Ice Trigger Cross-Combos

| Status Effect | Combo Name | Damage | Effect |
|---------------|------------|--------|--------|
| Burn | Flash Freeze | 21 | Apply Stun for 1.5s and extinguish all Burn stacks |
| Static | Subvoltage Pulse | 22 | Apply Energy Drain for 3 seconds |
| Acid | Crystallize | 23 | Reduce movement 50% and increase damage taken 15% for 4s |
| Gravity | Cryostasis | 24 | Root target in place for 2 seconds |

### Lightning Trigger Cross-Combos

| Status Effect | Combo Name | Damage | Effect |
|---------------|------------|--------|--------|
| Burn | Plasma Storm | 24 | Chain to 2 nearby enemies and apply 1 Burn to each |
| Freeze | Shatter Shock | 22 | Break frozen targets and apply 2 Static to nearby enemies |
| Acid | Electro-Corrosion | 25 | Amplify acid damage by 50% for 4 seconds |
| Gravity | EMP Wave | 23 | Drain 20 energy from all enemies within 3 squares |

### Acid Trigger Cross-Combos

| Status Effect | Combo Name | Damage | Effect |
|---------------|------------|--------|--------|
| Burn | Caustic Flames | 24 | Leave fire pool dealing 8 dmg/sec for 6 seconds |
| Freeze | Brittle Corrosion | 23 | Reduce armor by 5 and increase damage taken 20% for 3s |
| Static | Battery Leak | 22 | Apply Energy Drain for 4 seconds and deal bonus damage |
| Gravity | Corrosive Singularity | 25 | Pull nearby enemies and splash 2 Acid stacks on all |

### Gravity Trigger Cross-Combos

| Status Effect | Combo Name | Damage | Effect |
|---------------|------------|--------|--------|
| Burn | Supernova | 26 | Massive AoE explosion applying 2 Burn to all within 4 squares |
| Freeze | Absolute Zero Field | 24 | Freeze all enemies within 3 squares applying 2 Freeze stacks |
| Static | Gravitational Pulse | 23 | EMP burst draining 15 energy and pulling enemies 2 squares |
| Acid | Toxic Vortex | 25 | Pull enemies and create acid pool dealing 12 dmg/sec for 5s |

---

## Combo Damage Formula

```
Combo Damage = Base_Combo_Damage × (1 + Stack_Count × 0.5)

Example:
Burn Base Combo = 20 damage
Target has 3 Burn stacks

Combo Damage = 20 × (1 + 3 × 0.5) = 20 × 2.5 = 50 fire damage
```

**Multi-Element Example:**
```
Target has: 2 Burn, 3 Freeze, 1 Static
Tesla Cannon hits with Trigger (Lightning)

Sequential Combos:
1. Burn + Lightning = Plasma Storm
   → 24 × (1 + 2 × 0.5) = 48 lightning damage
   → Chain to 2 nearby enemies, apply 1 Burn each

2. Freeze + Lightning = Shatter Shock
   → 22 × (1 + 3 × 0.5) = 55 lightning damage
   → Apply 2 Static to nearby enemies

3. Static + Lightning = Chain Discharge
   → 23 × (1 + 1 × 0.5) = 34.5 lightning damage
   → Chain to all enemies with Static within 5 squares

Total: 28 (Tesla) + 48 + 55 + 34.5 = 165.5 damage
Plus utility effects and status spread
```

---

## Example Trigger Abilities

### Rocket
- **Type**: Trigger (Explosive)
- **Behavior**: Shoots straight down the lane
- **Damage**: 30 direct damage
- **Combo**: Detonates all status effects on hit

### Missile
- **Type**: Trigger (Explosive)
- **Behavior**: Homes toward current target
- **Damage**: 30 direct damage
- **Combo**: Detonates all status effects on hit

### Deathseeker Missile
- **Type**: Trigger (Explosive)
- **Behavior**: Targets enemy with lowest hull
- **Damage**: 30 direct damage
- **Combo**: Detonates all status effects for **+50% combo damage**

### Incinerator Ray
- **Type**: Trigger (Fire)
- **Behavior**: Beam weapon
- **Damage**: 30 fire damage
- **Combo**: Detonates Burn stacks, then applies 3 new Burn stacks

---

## Setup vs. Trigger Philosophy

### Setup Abilities (Apply Status)
- Apply elemental status effects (Burn, Freeze, Static, Acid, Gravity)
- Can have Trigger keyword, but trigger checks BEFORE applying stacks
- Examples: Flamethrower, Ice Beam, EMP Pulse

### Trigger Abilities (Detonate Status)
- Have the Trigger keyword
- Detonate existing status effects
- Can apply status AFTER detonation
- Examples: Rocket, Missile, Incinerator Ray

### Why This Design?
- Prevents infinite loops
- Creates team synergy (setup + trigger ships)
- Tactical decision-making (when to detonate vs. stack)
- Balances burst damage

---

## Strategy & Tactics

### Stack Management
- **More stacks = bigger explosion**
- **Trigger too early = waste potential**
- **Wait too long = stacks expire**

### Multi-Element Combos
- Multiple elements on one target = massive burst
- Setup ships apply different elements
- Trigger ship detonates all at once

### Team Composition
- **Setup Ships**: Apply status effects (Flamethrower, Ice Beam)
- **Trigger Ships**: Detonate combos (Missile ships, Rocket ships)
- **Hybrid Ships**: Element-specific triggers (setup + detonate same element)

---

## Implementation Notes

### CSV Databases

**status_effects.csv** - Defines all status effects
**elemental_combos.csv** - Defines combo damage and effects
**ability_database.csv** - Defines trigger and setup abilities

### Trigger Resolution Order

1. Trigger ability hits target
2. Check for elemental status effects on target
3. Calculate combo damage for each element present
4. Apply combo damage (element by element, sequentially)
5. Remove all triggered status stacks
6. Apply trigger ability's direct damage
7. Apply any special effects (element-specific triggers)
8. Apply new status stacks if ability grants them

### EffectResolver Singleton

The EffectResolver autoload handles status effect application and combo triggering.

```gdscript
func trigger_combos(trigger_type: String, target, attacker):
    var combos = []

    # Check each elemental status on target
    for element in ["burn", "freeze", "static", "acid", "gravity"]:
        if target.has_status(element):
            var stacks = target.get_status_stacks(element)
            var combo_data = get_combo_data(element, trigger_type)
            var damage = calculate_combo_damage(combo_data, stacks)
            combos.append({
                "element": element,
                "damage": damage,
                "effect": combo_data.special_effect
            })
            target.remove_status(element)  # Consume stacks

    # Apply combos sequentially
    for combo in combos:
        apply_combo_damage(target, combo.damage, combo.element)
        apply_combo_effect(target, combo.effect)
```

---

## Balance Considerations

- **Base combo damage**: 15-28 depending on element
- **Scaling**: 0.5 per stack (50% increase per additional stack)
- **Max damage per element**: ~45-70 damage (3 stacks)
- **5-element max burst**: ~250+ damage from combos alone
- **Resilience cap**: 75% max (always 25% chance to apply)
