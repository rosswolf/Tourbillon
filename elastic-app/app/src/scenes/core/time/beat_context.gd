extends Resource
class_name BeatContext

## Context object passed during beat processing

# Time tracking properties
var beat_number: int = 0      # Total beats elapsed
var tick_number: int = 0      # Current tick (beat_number / 10)
var beat_in_tick: int = 0     # Beat within current tick (0-9)

func _init() -> void:
	pass
