extends Resource
class_name BeatContext

## Context object passed during beat processing
## Currently empty but can be extended with metadata if needed

# Could later contain:
# - Total beats elapsed
# - Current tick number  
# - Phase information
# - Trigger source
# - etc.

func _init() -> void:
	pass