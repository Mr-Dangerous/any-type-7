# Combat Formulas & Damage Calculation

This document defines all combat calculation formulas for Any-Type-7, including hit chance, critical hits, damage calculation, and attack timing.

---

## Hit Chance Calculation

### Formula

```
Base Hit Chance = 100%

Final Hit Chance = 100% - (Defender_Evasion - Attacker_Accuracy)

Minimum Hit Chance: 5% (always at least 5% chance to hit)
Maximum Hit Chance: 95% (always at least 5% chance to miss)
```

### How It Works

- Start with 100% base hit chance
- Subtract the difference between defender's Evasion and attacker's Accuracy
- If Accuracy > Evasion: Hit chance increases (capped at 95%)
- If Evasion > Accuracy: Hit chance decreases (minimum 5%)

### Examples

| Attacker Accuracy | Defender Evasion | Calculation | Final Hit Chance |
|-------------------|------------------|-------------|------------------|
| 0 | 0 | 100% - (0-0) = 100% | 95% (capped) |
| 10 | 5 | 100% - (5-10) = 105% | 95% (capped) |
| 0 | 20 | 100% - (20-0) = 80% | 80% |
| 5 | 30 | 100% - (30-5) = 75% | 75% |
| -10 | 10 | 100% - (10-(-10)) = 80% | 80% |
| 0 | 100 | 100% - (100-0) = 0% | 5% (minimum) |

### Design Notes

- **5% minimum**: Guarantees no attack is truly unhittable
- **95% maximum**: Guarantees no attack is guaranteed to hit (always some risk)
- **Linear scaling**: Each point of Accuracy/Evasion = 1% hit chance change
- **Simple mental math**: Easy for players to estimate hit chances

---

## Critical Hit Chance Calculation

### Formula

```
Base Crit Chance = 0%

Final Crit Chance = Attacker_Precision - Defender_Reinforced_Armor

Minimum Crit Chance: 0% (cannot be negative)
Maximum Crit Chance: 100% (theoretically, though unlikely to achieve)
```

### How It Works

- Start with 0% base crit chance (no free crits)
- Add attacker's Precision
- Subtract defender's Reinforced Armor
- Cannot go below 0%

### Examples

| Attacker Precision | Defender Reinforced Armor | Calculation | Final Crit Chance |
|--------------------|---------------------------|-------------|-------------------|
| 0 | 0 | 0 - 0 = 0% | 0% |
| 20 | 0 | 20 - 0 = 20% | 20% |
| 30 | 10 | 30 - 10 = 20% | 20% |
| 15 | 20 | 15 - 20 = -5% | 0% (minimum) |
| 50 | 10 | 50 - 10 = 40% | 40% |

### Design Notes

- **0% base**: Must invest in Precision to get crits
- **Hard-countered by Reinforced Armor**: Defensive stat directly counters offensive stat
- **Linear scaling**: Each point = 1% crit chance
- **Build diversity**: Crit builds vs. anti-crit builds

---

## Damage Calculation

### Per-Projectile Calculation

Each projectile follows this sequence:

```
For each projectile:
  1. Roll d100 for hit chance
     - If roll ≤ Hit Chance: HIT
     - If roll > Hit Chance: MISS (no damage)

  2. If HIT, roll d100 for crit chance
     - If roll ≤ Crit Chance: CRITICAL HIT
     - If roll > Crit Chance: NORMAL HIT

  3. Calculate base damage:
     - Critical Hit: Base_Damage × Crit_Multiplier
     - Normal Hit: Base_Damage
     - Miss: 0 damage

  4. Apply damage modifiers (vulnerabilities, buffs, etc.)
     Modified_Damage = Base_Damage × All_Multipliers

  5. Apply armor reduction (FINAL STEP):
     Final_Damage = Modified_Damage × (1 - Target_Armor/100)
     - Armor capped at 75% (maximum 75% reduction)
     - Armor can be negative (damage amplification)
```

### Total Attack Damage

```
Total Damage = Sum of all projectile damage that hit
```

### Critical Hit Multiplier

**Default**: 2.0x (TBD - may vary by weapon/ability)

Common multipliers:
- Standard: 2.0x (double damage)
- Light: 1.5x (50% bonus)
- Heavy: 2.5x (massive crits)

### Example Calculations

**Example 1: Single Projectile (No Armor)**
```
Ship Stats:
- Attack Damage: 10
- Projectile Count: 1
- Accuracy: 10
- Precision: 20

Target Stats:
- Evasion: 5
- Reinforced Armor: 0
- Armor: 0

Hit Chance: 100% - (5-10) = 105% → 95%
Crit Chance: 20 - 0 = 20%

Rolls:
- Hit roll: 45 (≤ 95%) → HIT!
- Crit roll: 15 (≤ 20%) → CRIT!

Damage Calculation:
- Base: 10 × 2.0 (crit) = 20 damage
- Armor: 20 × (1 - 0/100) = 20 × 1.0 = 20 damage
Final: 20 damage
```

**Example 2: With Armor (Frigate)**
```
Ship Stats:
- Attack Damage: 50

Target Stats (Frigate):
- Armor: 15

Damage Calculation:
- Base: 50 damage
- Armor: 50 × (1 - 15/100) = 50 × 0.85 = 42.5 damage
Final: 42.5 damage (15% reduced)
```

**Example 3: With Negative Armor (Gravity Debuff)**
```
Ship Stats:
- Attack Damage: 50

Target Stats:
- Armor: -20 (from Gravity debuff)

Damage Calculation:
- Base: 50 damage
- Armor: 50 × (1 - (-20)/100) = 50 × 1.20 = 60 damage
Final: 60 damage (20% amplified)
```

**Example 2: Multiple Projectiles**
```
Ship Stats:
- Attack Damage: 5
- Projectile Count: 4
- Accuracy: 0
- Precision: 15

Target Stats:
- Evasion: 20
- Reinforced Armor: 5

Hit Chance: 100% - (20-0) = 80%
Crit Chance: 15 - 5 = 10%

Rolls (4 projectiles):
  Projectile 1: Hit (65) + Crit (8) = 5 × 2.0 = 10 damage
  Projectile 2: Hit (42) + No Crit (55) = 5 damage
  Projectile 3: Miss (87) = 0 damage
  Projectile 4: Hit (15) + No Crit (90) = 5 damage

Total Damage: 10 + 5 + 0 + 5 = 20 damage
```

---

## Attack Speed & Timing

### Attack Cooldown Formula

```
Attack Cooldown (seconds) = 1.0 / Attack_Speed

Where Attack_Speed is attacks per second
```

### Examples

| Attack Speed | Cooldown | Attacks per Minute |
|--------------|----------|-------------------|
| 0.5 | 2.0 seconds | 30 |
| 1.0 | 1.0 seconds | 60 |
| 1.5 | 0.667 seconds | 90 |
| 2.0 | 0.5 seconds | 120 |
| 3.0 | 0.333 seconds | 180 |

### Attack Speed Scaling

Attack speed can be modified by:
- **Upgrades**: Chamber Cooling I-V (+0.1 to +1.2 attacks/sec)
- **Status Effects**: Freeze (-20% per stack)
- **Buffs**: Runaway Oscillator (+2% per auto-attack)

**Modified Attack Speed Example:**
```
Base Attack Speed: 1.0
Chamber Cooling III: +0.4
3 Freeze stacks: -60% = ×0.4

Final Attack Speed: (1.0 + 0.4) × 0.4 = 0.56 attacks/sec
Cooldown: 1.0 / 0.56 = 1.79 seconds
```

---

## Damage Application Order

When damage is dealt, it's applied in this order:

### 1. Calculate Final Damage (Including Armor)
```
1. Roll for hit/crit
2. Calculate base damage (with crit multiplier if applicable)
3. Apply damage modifiers (vulnerable, buffs, etc.)
4. Apply armor reduction (FINAL):
   Final_Damage = Modified_Damage × (1 - Armor/100)
```

### 2. Shields First
```
If target has shields:
  - Final damage depletes shields first
  - Overflow damage carries to hull

Example:
  Ship: 50 hull, 20 shields, 15 armor
  Takes 100 incoming damage

  After armor: 100 × (1 - 15/100) = 85 damage
  Result:
  - Shields: 20 - 85 = -65 (destroyed)
  - Hull: 50 - 65 = 0 (ship destroyed!)
```

### 3. Hull Second
```
If shields are depleted or nonexistent:
  - Damage goes directly to hull (already reduced by armor)
  - Hull reaching 0 = ship destroyed
```

### 4. Special Cases

**Armor Reduction (Acid):**
- Acid status effect reduces armor by 1 per second per stack
- Armor reduction is permanent for the duration of combat
- Armor resets to base value between combats
- Example: Frigate with 15 armor and 3 Acid stacks
  - After 5 seconds: 15 - (3 × 5) = 0 armor
  - After 10 seconds: 15 - (3 × 10) = -15 armor (damage amplified!)

**Acid Status Effect:**
- Blocks hull point recovery
- Ship cannot heal hull while Acid is active

**Static Status Effect:**
- Blocks shield regeneration
- Ship cannot gain shields while Static is active

---

## Damage Types

### Physical Damage
- Standard auto-attack damage
- Affected by armor (future feature)
- Can crit based on Precision

### Elemental Damage
- Fire, Cold, Lightning, Acid, Gravity
- From abilities and status effects
- Can trigger elemental combos

### True Damage
- Bypasses shields (future feature)
- Goes directly to hull
- Cannot be mitigated

---

## DPS Calculations

### Base DPS Formula

```
DPS = Attack_Damage × Projectile_Count × Attack_Speed × Hit_Chance
```

### DPS With Crits

```
Average Damage per Hit = Base_Damage × (1 + Crit_Chance × (Crit_Multiplier - 1))

DPS = Avg_Damage × Projectile_Count × Attack_Speed × Hit_Chance
```

### Example DPS Calculation

```
Ship Stats:
- Attack Damage: 10
- Projectile Count: 2
- Attack Speed: 1.5
- Accuracy: 10
- Precision: 20

Target Stats:
- Evasion: 5
- Reinforced Armor: 0

Hit Chance: 100% - (5-10) = 105% → 95%
Crit Chance: 20 - 0 = 20%

Average Damage per Projectile:
  10 × (1 + 0.20 × (2.0 - 1)) = 10 × 1.20 = 12

DPS = 12 × 2 × 1.5 × 0.95 = 34.2 damage per second
```

---

## Implementation Notes

### DamageCalculator Singleton

The DamageCalculator autoload handles all combat calculations:

```gdscript
# Hit Chance
func calculate_hit_chance(attacker, defender) -> float:
    var base_hit = 100.0
    var final_hit = base_hit - (defender.evasion - attacker.accuracy)
    return clamp(final_hit, 5.0, 95.0)

# Crit Chance
func calculate_crit_chance(attacker, defender) -> float:
    var crit_chance = attacker.precision - defender.reinforced_armor
    return max(0.0, crit_chance)

# Hit Roll
func roll_to_hit(hit_chance: float) -> bool:
    return randf() * 100.0 <= hit_chance

# Crit Roll
func roll_to_crit(crit_chance: float) -> bool:
    return randf() * 100.0 <= crit_chance

# Calculate Single Projectile Damage
func calculate_projectile_damage(attacker, defender, crit_multiplier: float = 2.0) -> float:
    var hit_chance = calculate_hit_chance(attacker, defender)

    if not roll_to_hit(hit_chance):
        return 0.0  # Miss

    var crit_chance = calculate_crit_chance(attacker, defender)
    var is_crit = roll_to_crit(crit_chance)

    var damage = attacker.attack_damage
    if is_crit:
        damage *= crit_multiplier

    return damage

# Apply Damage to Target
func apply_damage(target, damage: float) -> void:
    if target.shield_points > 0:
        var shield_damage = min(damage, target.shield_points)
        target.shield_points -= shield_damage
        damage -= shield_damage

    if damage > 0:
        target.hull_points -= damage

    if target.hull_points <= 0:
        target.destroy()
```

---

## Balance Considerations

### Accuracy vs. Evasion

- **Baseline**: Most ships start with 0/0
- **Interceptors**: High evasion (25-40), low accuracy
- **Snipers**: High accuracy (20-35), low evasion
- **Balanced**: 10-15 in both stats

### Precision vs. Reinforced Armor

- **Baseline**: Most ships start with 0/0
- **Crit builds**: 20-40 Precision
- **Anti-crit tanks**: 15-30 Reinforced Armor
- **Glass cannons**: High Precision, low everything else

### Attack Speed vs. Damage

- **Fast attackers**: 2.0+ attacks/sec, 5-10 damage
- **Slow hitters**: 0.5-1.0 attacks/sec, 25-50 damage
- **DPS equivalence**: Both should achieve similar DPS at baseline

### Projectile Count

- **Single shot**: 1 projectile, high damage, high variance
- **Multi-shot**: 3-5 projectiles, lower damage, consistent
- **Shotgun**: 8-12 projectiles, very low damage, spreads risk

---

## Future Considerations

### To Be Determined

- **Crit Multiplier Variance**: Should different weapons have different crit multipliers?
- **Armor System**: Physical damage reduction?
- **Damage Types**: Elemental resistances?
- **Overkill**: Does excess damage on kill carry to next target?
- **Penetration**: Ignore a % of evasion/armor?

### Potential Expansions

- **Damage Ramp**: Increase damage the longer you attack
- **First Strike Bonus**: Extra damage on first hit
- **Execute Threshold**: Bonus damage to low HP targets
- **Dodge Frames**: Temporary invulnerability windows
- **Parry/Counter**: Reflect damage back to attacker
