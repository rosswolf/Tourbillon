extends RefCounted
class_name TimelineManager

## Core time tracking system for Tourbillon
## Time only advances when cards are played
## 1 Tick = 10 Beats for precision
## Owns and manages the BeatProcessor

# Minimal signals for MVP
signal time_changed(total_beats: int)      # Any time change
signal card_ticks_complete()               # Card's time cost fully processed

var total_beats: int = 0
var beat_processor: BeatProcessor

# Beat processing control
var beats_pending: int = 0  # Beats waiting to be processed
var beat_delay_ms: float = 20.0  # Milliseconds between beats (20ms = 50 beats/sec)
var is_processing_beats: bool = false
var last_beat_time: float = 0.0

func _init() -> void:
	# Create beat processor immediately
	beat_processor = BeatProcessor.new()

## Get the beat processor (for external setup)
func get_beat_processor() -> BeatProcessor:
	return beat_processor

## Set mainplate reference on beat processor
func set_mainplate(mainplate: Mainplate) -> void:
	if beat_processor:
		beat_processor.set_mainplate(mainplate)

## Set gremlin manager reference on beat processor
func set_gremlin_manager(manager: GremlinManager) -> void:
	if beat_processor:
		beat_processor.set_gremlin_manager(manager)

## Register additional beat listener
func register_beat_listener(listener: BeatListenerEntity) -> void:
	if beat_processor:
		beat_processor.register_listener(listener)

## Unregister a beat listener
func unregister_beat_listener(listener: BeatListenerEntity) -> void:
	if beat_processor:
		beat_processor.unregister_listener(listener)

## Advance time by the specified number of ticks
func advance_time(ticks: float, instant: bool = false) -> void:
	var beats_to_add: int = int(ticks * 10)
	if instant:
		__advance_beats_instant(beats_to_add)
	else:
		__advance_beats_smooth(beats_to_add)

## Instantly advance beats and process them
func __advance_beats_instant(beats_to_add: int) -> void:
	if beats_to_add <= 0:
		card_ticks_complete.emit()
		return
	
	print("Advancing time by ", beats_to_add, " beats")
	
	# Process all beats instantly, emitting time change for each
	for i in range(beats_to_add):
		total_beats += 1
		__process_single_beat()
		# Emit time changed for EACH beat so UI can update incrementally
		time_changed.emit(total_beats)
	
	# Signal completion
	card_ticks_complete.emit()

## Process a single beat
func __process_single_beat() -> void:
	var context: BeatContext = BeatContext.new()
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

## Advance beats smoothly over time
func __advance_beats_smooth(beats_to_add: int) -> void:
	if beats_to_add <= 0:
		card_ticks_complete.emit()
		return
	
	print("Smoothly advancing time by ", beats_to_add, " beats")
	
	# Add to pending beats
	beats_pending += beats_to_add
	
	# Start processing if not already running
	if not is_processing_beats:
		__start_beat_processing()

## Start the beat processing loop
func __start_beat_processing() -> void:
	is_processing_beats = true
	last_beat_time = Time.get_ticks_msec()
	
	# We need access to the scene tree for timing
	# Since we're RefCounted, we'll use the GlobalGameManager's tree
	var tree = GlobalGameManager.get_tree() if GlobalGameManager else null
	if tree:
		tree.process_frame.connect(__check_beat_timing)

## Check if it's time to process next beat
func __check_beat_timing() -> void:
	if beats_pending <= 0:
		__stop_beat_processing()
		return
	
	var current_time = Time.get_ticks_msec()
	var time_since_last = current_time - last_beat_time
	
	# Process beats that are due
	while time_since_last >= beat_delay_ms and beats_pending > 0:
		total_beats += 1
		__process_single_beat()
		time_changed.emit(total_beats)
		
		beats_pending -= 1
		last_beat_time += beat_delay_ms
		time_since_last -= beat_delay_ms

## Stop the beat processing loop
func __stop_beat_processing() -> void:
	is_processing_beats = false
	
	var tree = GlobalGameManager.get_tree() if GlobalGameManager else null
	if tree and tree.process_frame.is_connected(__check_beat_timing):
		tree.process_frame.disconnect(__check_beat_timing)
	
	# Signal completion when all beats are done
	card_ticks_complete.emit()

## Set the delay between beats in milliseconds
func set_beat_delay(delay_ms: float) -> void:
	beat_delay_ms = max(10.0, delay_ms)  # Minimum 10ms delay

## Reset timeline for new combat
func reset() -> void:
	total_beats = 0
	beats_pending = 0
	is_processing_beats = false
	beat_processor.reset()
