extends Node
class_name BeatProcessor

## Processes all beat-aware entities in deterministic order
## Ensures consistent game state by processing in Escapement Order

signal phase_started(phase_name: String)
signal phase_completed(phase_name: String)

var mainplate: Mainplate
var gremlin_manager: GremlinManager
var poison_interval: int = 10  # Poison ticks every 10 beats by default

## Additional beat listeners for extensibility
var registered_listeners: Array[BeatListener] = []

func _ready() -> void:
	# References will be set by TimelineManager or GameManager
	pass

## Main beat processing - called by TimelineManager
func process_beat(beat_number: int) -> void:
	# Phase 1: Process complications in Escapement Order
	_process_complications_phase(beat_number)
	
	# Phase 2: Process poison if on interval
	if beat_number % poison_interval == 0:
		_process_poison_phase(beat_number)
	
	# Phase 3: Process gremlins in slot order
	_process_gremlins_phase(beat_number)
	
	# Phase 4: Process additional listeners
	_process_listeners_phase(beat_number)
	
	# Phase 5: Check victory/loss conditions
	_check_end_conditions(beat_number)

## Phase 1: Process all complications
func _process_complications_phase(beat_number: int) -> void:
	if not mainplate:
		return
		
	phase_started.emit("complications")
	
	var complications = mainplate.get_complications_in_escapement_order()
	for complication in complications:
		if complication and is_instance_valid(complication):
			complication.process_beat(beat_number)
	
	phase_completed.emit("complications")

## Phase 2: Process poison damage
func _process_poison_phase(beat_number: int) -> void:
	phase_started.emit("poison")
	
	# TODO: Implement poison processing
	# Will check hero/gremlins for poison stacks
	
	phase_completed.emit("poison")

## Phase 3: Process all gremlins
func _process_gremlins_phase(beat_number: int) -> void:
	if not gremlin_manager:
		return
		
	phase_started.emit("gremlins")
	
	var gremlins = gremlin_manager.get_gremlins_in_order()
	for gremlin in gremlins:
		if gremlin and is_instance_valid(gremlin):
			gremlin.process_beat(beat_number)
	
	phase_completed.emit("gremlins")

## Phase 4: Process additional listeners
func _process_listeners_phase(beat_number: int) -> void:
	phase_started.emit("listeners")
	
	# Sort by priority for consistent ordering
	registered_listeners.sort_custom(_compare_priority)
	
	for listener in registered_listeners:
		if listener and listener.is_active():
			listener.process_beat(beat_number)
	
	phase_completed.emit("listeners")

## Phase 5: Check end conditions
func _check_end_conditions(beat_number: int) -> void:
	# Victory takes precedence over loss per PRD
	if _check_victory():
		GlobalSignals.signal_core_victory()
	elif _check_loss():
		GlobalSignals.signal_core_defeat()

## Register an additional beat listener
func register_listener(listener: BeatListener) -> void:
	if listener not in registered_listeners:
		registered_listeners.append(listener)

## Unregister a beat listener
func unregister_listener(listener: BeatListener) -> void:
	registered_listeners.erase(listener)

## Set the mainplate reference
func set_mainplate(plate: Mainplate) -> void:
	mainplate = plate

## Set the gremlin manager reference
func set_gremlin_manager(manager: GremlinManager) -> void:
	gremlin_manager = manager

## Reset for new combat
func reset() -> void:
	for listener in registered_listeners:
		listener.reset()

## Helper to sort listeners by priority
func _compare_priority(a: BeatListener, b: BeatListener) -> bool:
	return a.get_priority() < b.get_priority()

## Check victory conditions
func _check_victory() -> bool:
	# TODO: Implement victory check
	# Victory when all gremlins defeated
	return false

## Check loss conditions  
func _check_loss() -> bool:
	# TODO: Implement loss check
	# Loss when hand empty after card resolution
	# Loss when can't draw from empty deck+discard
	return false