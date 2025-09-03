extends Node
class_name TimelineManager

## Core time tracking system for Tourbillon
## Time only advances when cards are played
## 1 Tick = 10 Beats for precision

# Minimal signals for MVP
signal time_changed(total_beats: int)      # Any time change
signal card_ticks_complete()               # Card's time cost fully processed

var total_beats: int = 0
var beat_processor: BeatProcessor

func _ready() -> void:
	beat_processor = BeatProcessor.new()
	add_child(beat_processor)

## Advance time by the specified number of ticks
func advance_time(ticks: float) -> void:
	var beats_to_add: int = int(ticks * 10)
	__advance_beats_animated(beats_to_add)

## Animate the beat advancement
func __advance_beats_animated(beats_to_add: int) -> void:
	if beats_to_add <= 0:
		card_ticks_complete.emit()
		return
	
	# Create a timer for animating beats
	var timer: Timer = Timer.new()
	timer.wait_time = 0.1  # 100ms per beat for visible counting
	timer.one_shot = false
	add_child(timer)
	
	var beats_processed: int = 0
	
	timer.timeout.connect(func():
		if beats_processed < beats_to_add:
			total_beats += 1
			__process_single_beat()
			time_changed.emit(total_beats)
			beats_processed += 1
		else:
			timer.stop()
			timer.queue_free()
			card_ticks_complete.emit()
	)
	
	timer.start()

## Process a single beat
func __process_single_beat() -> void:
	var context = BeatContext.new()
	context.beat_number = total_beats
	context.tick_number = total_beats / 10
	context.beat_in_tick = total_beats % 10
	
	beat_processor.process_beat(context)

## Get current time in ticks (for display)
func get_current_ticks() -> float:
	return total_beats / 10.0

## Get current time in beats (for internal use)
func get_current_beats() -> int:
	return total_beats

## Reset timeline for new combat
func reset() -> void:
	total_beats = 0
	beat_processor.reset()
