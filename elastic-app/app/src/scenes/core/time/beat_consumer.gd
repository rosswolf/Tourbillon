extends Resource
class_name BeatConsumer

## Base class for effects that consume beats over time
## Examples: Poison, Burn, Regeneration, etc.

var owner: Node  # The entity this consumer is attached to
var is_active: bool = true

## Called every beat while active
## Override in subclasses to implement behavior
func process_beat(context: BeatContext) -> void:
	pass

## Check if this consumer should be removed
func should_remove() -> bool:
	return false

## Reset the consumer state
func reset() -> void:
	is_active = true