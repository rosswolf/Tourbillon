extends BeatConsumer
class_name PoisonConsumer

## Beat consumer that handles poison damage over time
## Attached to gremlins and processes poison ticks

var poison_stacks: int = 0
var tick_interval: int = 10  # Every 10 beats (1 tick) by default
var beats_until_tick: int = 0

signal poison_tick(damage: int)

func _init(initial_stacks: int = 0, interval: int = 10) -> void:
	poison_stacks = initial_stacks
	tick_interval = interval
	beats_until_tick = tick_interval
	is_active = poison_stacks > 0

## Process a beat for poison
func process_beat(context: BeatContext) -> void:
	if poison_stacks <= 0:
		is_active = false
		return
	
	beats_until_tick -= 1
	
	if beats_until_tick <= 0:
		_apply_poison_damage()
		beats_until_tick = tick_interval

## Apply poison damage
func _apply_poison_damage() -> void:
	if not owner:
		return
	
	# Deal damage equal to poison stacks
	if owner is Gremlin:
		var gremlin = owner as Gremlin
		
		# Create poison damage packet
		var packet = DamageFactory.create_poison(poison_stacks, "Poison")
		var actual_damage = gremlin.receive_damage(packet)
		
		poison_tick.emit(actual_damage)
		
		print("Poison dealt ", actual_damage, " damage to ", gremlin.gremlin_name, 
			  " (", poison_stacks, " stacks)")

## Add more poison stacks
func add_poison(stacks: int) -> void:
	poison_stacks += stacks
	is_active = poison_stacks > 0
	print("Added ", stacks, " poison stacks (total: ", poison_stacks, ")")

## Remove poison stacks
func remove_poison(stacks: int) -> void:
	poison_stacks = max(0, poison_stacks - stacks)
	is_active = poison_stacks > 0

## Get current poison value
func get_poison_value() -> int:
	return poison_stacks

## Check if should be removed
func should_remove() -> bool:
	return poison_stacks <= 0

## Reset poison
func reset() -> void:
	poison_stacks = 0
	beats_until_tick = tick_interval
	is_active = false