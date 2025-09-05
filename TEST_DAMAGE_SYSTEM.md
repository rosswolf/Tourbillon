# Damage System Test Scenarios

## System Overview

The damage system is now fully connected from cards to gremlins with the following flow:

1. **Card Placement**: Card placed on mainplate with `on_fire_effect`
2. **Time Advances**: Playing card advances time by its `time_cost`
3. **Beat Processing**: Each beat, mainplate checks all gears
4. **Gear Activation**: When timer reaches interval, gear fires
5. **Effect Processing**: SimpleEffectProcessor parses effect string
6. **Damage Application**: DamagePacket created and applied to gremlin

## Available Damage Effects

### Basic Damage
- `damage=10` - Deal 10 damage to top gremlin
- `damage_all=5` - Deal 5 damage to all gremlins
- `damage_weakest=8` - Target lowest HP gremlin
- `damage_strongest=12` - Target highest HP gremlin
- `damage_bottom=7` - Target last gremlin
- `damage_random=6` - Random target

### Keyword Damage
- `pierce_damage=10` - Ignores armor
- `pierce_damage_all=5` - Pierce all enemies
- `pop_damage=10` - Double damage vs shields
- `overkill_damage=15` - Excess carries to next
- `execute=10` - Instant kill if below 10 HP

### DOT Effects
- `poison=3` - Apply 3 poison stacks
- `poison_all=2` - Poison all gremlins
- `burn=5` - Prevent healing for 5 ticks
- `burn_all=3` - Burn all gremlins

## Test Cards Available

### Simple Damage Cards
- **"rs.damage_1"**: `on_fire_effect: "damage=1"` (Every 3 ticks)
- **"rs.damage_all_1"**: `on_fire_effect: "damage_all=1"` (Every 5 ticks)
- **"rs.damage_2"**: `on_fire_effect: "damage=2"` (Every 4 ticks)

### Resource-Based Damage
- **"rs.pay_red_damage"**: `on_fire_effect: "pay_red=2,damage=1"` (Consume 2 red, deal 1)
- **"rs.pay_heat_damage"**: `on_fire_effect: "pay_heat=3,damage=5"` (Consume 3 heat, deal 5)

### Advanced Effects
- **"rs.poison_damage"**: `on_fire_effect: "poison=1,pay_red=2.5,damage=1"`
- **"rs.pierce_damage"** (needs creation): `on_fire_effect: "pierce_damage=8"`
- **"rs.execute_low"** (needs creation): `on_fire_effect: "execute=15"`

## Testing Instructions

### Test 1: Basic Damage
1. Spawn a gremlin with 10 HP
2. Place card "rs.damage_1" on mainplate
3. Advance time 3 ticks (card fires)
4. Verify gremlin takes 1 damage (HP = 9)

### Test 2: Damage All
1. Spawn 3 gremlins with 10 HP each
2. Place card "rs.damage_all_1" on mainplate
3. Advance time 5 ticks
4. Verify all gremlins take 1 damage (HP = 9 each)

### Test 3: Resource Consumption
1. Give hero 5 red force
2. Spawn gremlin with 10 HP
3. Place "rs.pay_red_damage" card
4. Advance time 3 ticks
5. Verify: Red force decreases by 2, gremlin takes 1 damage

### Test 4: Pierce Damage
1. Spawn gremlin with 10 HP and 5 armor
2. Create/place pierce damage card
3. Let it fire
4. Verify full damage applied (ignoring armor)

### Test 5: Poison Application
1. Spawn gremlin
2. Place poison card
3. Let it fire
4. Verify poison stacks applied
5. Advance 10 beats (1 tick)
6. Verify poison damage dealt

## Debug Commands

Check gremlin status:
```gdscript
var gremlins = GlobalGameManager.get_active_gremlins()
for g in gremlins:
    print("Gremlin: ", g.gremlin_name, " HP: ", g.current_hp, "/", g.max_hp)
```

Check mainplate gear states:
```gdscript
var cards = GlobalGameManager.mainplate.get_cards_in_order()
for c in cards:
    var state = GlobalGameManager.mainplate.get_card_state(c.instance_id)
    print("Card: ", c.display_name, " Progress: ", state.current_beats, " Ready: ", state.is_ready)
```

Force gear activation:
```gdscript
var card = GlobalGameManager.mainplate.get_card_at(Vector2i(0,0))
if card and not card.on_fire_effect.is_empty():
    SimpleEffectProcessor.process_effects(card.on_fire_effect, card)
```

## Known Issues to Watch For

1. **Resource Checking**: Gears won't fire if they can't consume required resources
2. **Targeting**: Default is top gremlin; use specific targeting for others
3. **Beat vs Tick**: Remember 10 beats = 1 tick for timing
4. **Effect Order**: Effects process sequentially (consume first, then damage)

## Success Criteria

- [x] SimpleEffectProcessor handles all damage effect types
- [x] DamagePackets created with proper keywords
- [x] Gremlins receive damage through unified system
- [x] Mainplate processes beats and fires gears
- [x] Resource consumption gates damage effects
- [ ] Visual feedback shows damage numbers (UI layer)
- [ ] Gremlin death removes from combat
- [ ] Overkill damage carries to next gremlin