# Gremlin Damage System Design

## Core Damage Pipeline

The damage system follows a sequential pipeline where each stage can modify the damage before it reaches the target:

```
Source → Modifiers → Defenses → Vulnerabilities → Application
```

## 1. Damage Types

### Base Damage Types
- **Physical**: Standard damage, affected by armor
- **Energy**: Bypasses armor, affected by shields  
- **True**: Ignores all defenses (rare, powerful)
- **Poison**: Damage over time, ignores shields

### Damage Properties (Flags)
- **Piercing**: Ignores shields
- **Overwhelming**: Excess damage carries through shields
- **Chaining**: Jumps to adjacent gremlins at reduced power
- **Explosive**: Hits all gremlins but divided among them
- **Execution**: Instant kill if target below X health

## 2. Damage Calculation Pipeline

```gdscript
class DamagePacket:
    var base_amount: int
    var damage_type: DamageType
    var properties: Array[DamageProperty] = []
    var source: Entity  # The card/gear that dealt damage
    var multipliers: float = 1.0
    var flat_bonuses: int = 0
    var ignore_shields: bool = false
    var ignore_armor: bool = false
    
func calculate_damage(packet: DamagePacket, target: Gremlin) -> int:
    # Stage 1: Source Modifiers (from gears that buff damage)
    packet = apply_source_modifiers(packet)
    
    # Stage 2: Global Modifiers (field effects, complications)
    packet = apply_global_modifiers(packet)
    
    # Stage 3: Target Defenses
    var damage = packet.base_amount * packet.multipliers + packet.flat_bonuses
    
    if not packet.ignore_shields and target.shields > 0:
        damage = apply_shields(damage, target, packet)
    
    if not packet.ignore_armor and target.armor > 0:
        damage = apply_armor(damage, target, packet)
    
    # Stage 4: Vulnerabilities/Resistances
    damage = apply_vulnerabilities(damage, target, packet)
    
    # Stage 5: Final modifications (minimum 1 damage unless blocked)
    return max(1, damage)
```

## 3. Shield Mechanics

### Shield Types
- **Temporary Shields**: Last X turns, absorb damage
- **Regenerating Shields**: Restore Y amount each turn
- **Reflective Shields**: Return % of damage to attacker
- **Brittle Shields**: Break after 1 hit regardless of damage

### Shield Interaction
```gdscript
func apply_shields(damage: int, target: Gremlin, packet: DamagePacket) -> int:
    if packet.has_property(DamageProperty.PIERCING):
        return damage  # Piercing ignores shields
    
    var remaining_damage = damage
    
    # Shields absorb damage
    if target.shields >= remaining_damage:
        target.shields -= remaining_damage
        return 0
    else:
        remaining_damage -= target.shields
        target.shields = 0
        
        if packet.has_property(DamageProperty.OVERWHELMING):
            return remaining_damage  # Excess carries through
        else:
            return 0  # Shields block all
```

## 4. Gremlin Vulnerabilities

### Vulnerability System
Each gremlin can have:
- **Weaknesses**: Take +50% damage from specific type
- **Resistances**: Take -50% damage from specific type
- **Immunities**: Take 0 damage from specific type

### State-Based Vulnerabilities
- **Exposed**: Next hit deals double damage
- **Fortified**: Next hit deals half damage
- **Marked**: All sources deal +2 damage
- **Blessed**: Immune to next damage instance

## 5. Gear Interactions

### Damage-Modifying Gears

#### Offensive Gears
```gdscript
class AmplifierGear extends Gear:
    # "All damage dealt is increased by 2"
    func modify_outgoing_damage(packet: DamagePacket) -> DamagePacket:
        packet.flat_bonuses += 2
        return packet

class CriticalGear extends Gear:
    # "25% chance to deal double damage"
    func modify_outgoing_damage(packet: DamagePacket) -> DamagePacket:
        if randf() < 0.25:
            packet.multipliers *= 2.0
        return packet
```

#### Defensive Gears
```gdscript
class ShieldGeneratorGear extends Gear:
    # "When placed: Give all gremlins +3 shields"
    func on_place():
        for gremlin in get_all_gremlins():
            gremlin.add_shields(3)

class ArmorPlatingGear extends Gear:
    # "Reduce all incoming damage by 1"
    func modify_incoming_damage(damage: int) -> int:
        return max(0, damage - 1)
```

### Combo Gears
```gdscript
class ChainLightningGear extends Gear:
    # "Damage chains to adjacent gremlins at 50% power"
    func modify_outgoing_damage(packet: DamagePacket) -> DamagePacket:
        packet.properties.append(DamageProperty.CHAINING)
        packet.chain_reduction = 0.5
        return packet
```

## 6. Implementation Examples

### Example 1: Basic Attack
```
Lightning Bolt deals 5 damage to Gremlin
→ No modifiers active
→ Gremlin has 2 shields
→ Shields absorb 2, 3 damage goes through
→ Gremlin takes 3 damage
```

### Example 2: Complex Interaction
```
Fireball deals 4 damage to Shielded Gremlin
→ Amplifier Gear adds +2 (6 total)
→ Gremlin is "Vulnerable to Fire" (+50% = 9 damage)
→ Gremlin has 5 shields
→ Shields absorb 5, 4 damage goes through
→ Gremlin takes 4 damage
```

### Example 3: Execution Mechanic
```
Assassinate deals 3 damage with Execution property
→ Target gremlin has 2 health, 0 shields
→ Execution triggers (below 3 health threshold)
→ Gremlin is instantly defeated
```

## 7. Special Cases

### Damage Over Time (DoT)
- Poison/Burn effects deal damage at beat intervals
- Ignores shields but affected by armor
- Can stack or refresh duration

### Area of Effect (AoE)
- **Split**: Total damage divided among targets
- **Full**: Each target takes full damage
- **Cascade**: Damage reduces with each target hit

### Lifesteal
- Heals source based on damage dealt
- Only counts actual health damage (not shield damage)

## 8. UI/UX Considerations

### Damage Preview
Show players:
- Base damage amount
- Modifiers being applied (+2 from gear, x1.5 from weakness)
- Final damage calculation
- Whether it will defeat the gremlin

### Visual Feedback
- Different colors for damage types
- Shield break animations
- Vulnerability indicators
- Damage number popups with modifier tags

## 9. Balance Considerations

### Scaling
- Early game: 1-3 damage is significant
- Mid game: 5-10 damage expected
- Late game: 15+ damage with combos

### Counter-play
- Players can build defensive gears to counter damage
- Timing shields before big attacks
- Using immunities strategically

## 10. Database Schema

```json
{
  "damage_effects": {
    "lightning_bolt": {
      "base_damage": 5,
      "damage_type": "energy",
      "properties": ["overwhelming"],
      "description": "Deal 5 energy damage, excess pierces shields"
    },
    "poison_dart": {
      "base_damage": 2,
      "damage_type": "poison",
      "properties": ["dot"],
      "dot_duration": 3,
      "description": "Deal 2 poison damage for 3 beats"
    }
  }
}
```

## Future Expansions

1. **Elemental Reactions**: Fire + Ice = Steam explosion
2. **Combo Multipliers**: Damage increases with consecutive hits
3. **Revenge Damage**: Gremlins deal damage when destroyed
4. **Damage Redirection**: Transfer damage to another gremlin
5. **Conditional Damage**: Extra damage if target is stunned/frozen