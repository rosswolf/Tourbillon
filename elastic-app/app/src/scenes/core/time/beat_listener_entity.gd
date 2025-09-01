extends Entity
class_name BeatListenerEntity

## Base class for entities that respond to beat processing
## Extends Entity to work with Godot's single inheritance

## Called every beat in deterministic order
## Override this in subclasses to implement beat behavior
func process_beat(context: BeatContext) -> void:
	pass

## Priority for processing order within the same phase
## Lower values are processed first
## Override to change priority (default is 0)
func get_priority() -> int:
	return 0

## Check if this listener should be processed
## Override for conditional processing
func is_active() -> bool:
	return true

## Reset state for new combat
## Override to clear any accumulated state
func reset() -> void:
	pass