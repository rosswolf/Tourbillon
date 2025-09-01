extends Node
class_name TimelineManager

## Core time tracking system for Tourbillon
## Time only advances when cards are played
## 1 Tick = 10 Beats for precision

signal beat_processed(context: BeatContext)
signal tick_completed(tick_number: int)
signal time_advanced(ticks: float, total_beats: int)

var total_beats: int = 0
var pending_beats: int = 0

var beat_processor: BeatProcessor

func _ready() -> void:
	beat_processor = BeatProcessor.new()
	add_child(beat_processor)

## Advance time by the specified number of ticks
func advance_time(ticks: float) -> void:
	var beats_to_add = int(ticks * 10)
	pending_beats = beats_to_add
	
	time_advanced.emit(ticks, total_beats + beats_to_add)
	_process_pending_beats()

## Process all pending beats sequentially
func _process_pending_beats() -> void:
	while pending_beats > 0:
		_process_single_beat()
		total_beats += 1
		pending_beats -= 1
		
		# Emit tick signal every 10 beats
		if total_beats % 10 == 0:
			tick_completed.emit(total_beats / 10)

## Process a single beat
func _process_single_beat() -> void:
	var context = BeatContext.new()
	beat_processor.process_beat(context)
	beat_processed.emit(context)

## Get current time in ticks (for display)
func get_current_ticks() -> float:
	return total_beats / 10.0

## Get current time in beats (for internal use)
func get_current_beats() -> int:
	return total_beats

## Reset timeline for new combat
func reset() -> void:
	total_beats = 0
	pending_beats = 0
	beat_processor.reset()