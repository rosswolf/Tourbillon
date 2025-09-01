extends Resource
class_name BeatListener

## Base interface for entities that respond to beat processing
## All beat-aware entities should extend this class

## Called every beat in deterministic order
## Override this in subclasses to implement beat behavior
func process_beat(beat_number: int) -> void:
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