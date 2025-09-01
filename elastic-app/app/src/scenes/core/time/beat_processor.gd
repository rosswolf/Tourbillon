extends Node
class_name BeatProcessor

## Processes all beat-aware entities in deterministic order
## Ensures consistent game state by processing in Escapement Order
## Cards become Gears when placed on mainplate

signal phase_started(phase_name: String)
signal phase_completed(phase_name: String)

var mainplate: Mainplate
var gremlin_manager: GremlinManager
var poison_interval: int = 10  # Poison ticks every 10 beats by default

## Additional beat listeners for extensibility
var registered_listeners: Array[BeatListenerEntity] = []

func _ready() -> void:
	# References will be set by TimelineManager or GameManager
	pass

## Main beat processing - called by TimelineManager
func process_beat(context: BeatContext) -> void:
	# Phase 1: Process gears in Escapement Order
	_process_gears_phase(context)
	
	# Phase 2: Process gremlins (they handle their own poison)
	_process_gremlins_phase(context)
	
	# Phase 3: Process additional listeners
	_process_listeners_phase(context)
	
	# Phase 4: Check victory/loss conditions
	_check_end_conditions(context)

## Phase 1: Process all gears (cards on mainplate)
func _process_gears_phase(context: BeatContext) -> void:
	if not mainplate:
		return
		
	phase_started.emit("gears")
	
	var gears = mainplate.get_gears_in_escapement_order()
	for gear in gears:
		if gear and is_instance_valid(gear):
			gear.process_beat(context)
	
	phase_completed.emit("gears")

## Phase 2: Process all gremlins
func _process_gremlins_phase(context: BeatContext) -> void:
	if not gremlin_manager:
		return
		
	phase_started.emit("gremlins")
	
	var gremlins = gremlin_manager.get_gremlins_in_order()
	for gremlin in gremlins:
		if gremlin and is_instance_valid(gremlin):
			gremlin.process_beat(context)
	
	phase_completed.emit("gremlins")

## Phase 3: Process additional listeners
func _process_listeners_phase(context: BeatContext) -> void:
	phase_started.emit("listeners")
	
	# Sort by priority for consistent ordering
	registered_listeners.sort_custom(_compare_priority)
	
	for listener in registered_listeners:
		if listener and listener.is_active():
			listener.process_beat(context)
	
	phase_completed.emit("listeners")

## Phase 4: Check end conditions
func _check_end_conditions(context: BeatContext) -> void:
	# Victory takes precedence over loss per PRD
	if _check_victory():
		GlobalSignals.signal_core_victory()
	elif _check_loss():
		GlobalSignals.signal_core_defeat()

## Register an additional beat listener
func register_listener(listener: BeatListenerEntity) -> void:
	if listener not in registered_listeners:
		registered_listeners.append(listener)

## Unregister a beat listener
func unregister_listener(listener: BeatListenerEntity) -> void:
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
func _compare_priority(a: BeatListenerEntity, b: BeatListenerEntity) -> bool:
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