extends BeatConsumer
class_name PoisonConsumer

## Poison effect that deals damage over time
## Triggers every 10 beats (1 tick), reduces by 1 each trigger

var poison_value: int = 0
var beats_until_trigger: int = 10
var trigger_interval: int = 10  # Every 10 beats (1 tick)

func _init(initial_value: int = 1) -> void:
	poison_value = initial_value
	beats_until_trigger = trigger_interval

## Add more poison stacks
func add_poison(amount: int) -> void:
	poison_value += amount

## Process beat for poison
func process_beat(context: BeatContext) -> void:
	if poison_value <= 0:
		return
	
	beats_until_trigger -= 1
	
	if beats_until_trigger <= 0:
		_trigger_poison()
		beats_until_trigger = trigger_interval

## Trigger poison damage
func _trigger_poison() -> void:
	if owner:
		# Use unified damage system for poison damage
		if owner.has_method("receive_damage"):
			var packet = DamageFactory.create_poison(poison_value, str(get_instance_id()))
			owner.receive_damage(packet)
		else:
			push_warning("PoisonConsumer: owner doesn't support receive_damage: ", owner.get_class())
		
		# Reduce poison by 1 after dealing damage
		poison_value = max(0, poison_value - 1)

## Check if poison is exhausted
func should_remove() -> bool:
	return poison_value <= 0

## Get current poison stacks
func get_poison_value() -> int:
	return poison_value

## Reset poison
func reset() -> void:
	super.reset()
	poison_value = 0
	beats_until_trigger = trigger_interval
