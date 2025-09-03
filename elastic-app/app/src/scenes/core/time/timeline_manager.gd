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
	__advance_beats_instant(beats_to_add)

## Instantly advance beats and process them
func __advance_beats_instant(beats_to_add: int) -> void:
	if beats_to_add <= 0:
		card_ticks_complete.emit()
		return
	
	print("Advancing time by ", beats_to_add, " beats")
	
	# Process all beats instantly for game logic
	var start_beat: int = total_beats
	for i in range(beats_to_add):
		total_beats += 1
		__process_single_beat()
	
	# Animate the UI display quickly (but not instantly)
	__animate_ui_beats(start_beat, total_beats)
	
	# Signal completion immediately (game logic is done)
	card_ticks_complete.emit()

## Animate UI beat display for visual feedback
func __animate_ui_beats(from_beat: int, to_beat: int) -> void:
	# Emit starting position immediately
	time_changed.emit(from_beat)
	
	var beats_to_show: int = to_beat - from_beat
	if beats_to_show <= 0:
		return
		
	# Fast animation: 20ms per beat for quick visual counting
	# For 20 beats (2 ticks), this takes 0.4 seconds total
	var timer: Timer = Timer.new()
	timer.wait_time = 0.02  # 20ms per beat
	timer.one_shot = false
	add_child(timer)
	
	var current_display_beat: int = from_beat
	
	timer.timeout.connect(func():
		if current_display_beat < to_beat:
			current_display_beat += 1
			time_changed.emit(current_display_beat)
		else:
			timer.stop()
			timer.queue_free()
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
