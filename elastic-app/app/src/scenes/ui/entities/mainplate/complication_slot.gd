extends EngineSlot
class_name ComplicationSlot

## Tourbillon-specific slot for complications on the mainplate
## Extends EngineSlot to add beat-based timing and production

@export var grid_position: Vector2i = Vector2i.ZERO

var production_interval_beats: int = 30  # Default 3 ticks
var current_beats: int = 0
var is_ready: bool = false

# Force requirements and production
var force_consumption: Dictionary = {}  # GameResource.Type -> amount
var force_production: Dictionary = {}    # GameResource.Type -> amount

signal production_fired(slot: ComplicationSlot)
signal ready_state_entered(slot: ComplicationSlot)
signal ready_state_exited(slot: ComplicationSlot)

func _ready() -> void:
	super._ready()
	# Additional Tourbillon-specific setup

## Called by BeatProcessor each beat
func process_beat(beat_number: int) -> void:
	if not __button_entity or not __button_entity.card:
		return
	
	# Update timer progress
	if not is_ready:
		current_beats += 1
		_update_progress_display()
		
		if current_beats >= production_interval_beats:
			_enter_ready_state()
	
	# Try to fire if ready
	if is_ready and _can_produce():
		_fire_production()

## Setup complication from card data
func setup_from_card(card: Card) -> void:
	if not card:
		return
		
	# Get timing from card
	production_interval_beats = card.get_production_interval() * 10  # Convert ticks to beats
	
	# Get force requirements
	force_consumption = card.get_force_consumption()
	force_production = card.get_force_production()
	
	# Reset state
	current_beats = 0
	is_ready = false
	_update_progress_display()

## Check if we have required forces to produce
func _can_produce() -> bool:
	if force_consumption.is_empty():
		return true  # No requirements, always can produce
	
	# Check each required force
	for force_type in force_consumption:
		var required_amount = force_consumption[force_type]
		if not GlobalGameManager.hero.has_force(force_type, required_amount):
			return false
	
	return true

## Fire production effect
func _fire_production() -> void:
	# Consume required forces
	for force_type in force_consumption:
		var amount = force_consumption[force_type]
		GlobalGameManager.hero.consume_force(force_type, amount)
	
	# Produce forces
	for force_type in force_production:
		var amount = force_production[force_type]
		GlobalGameManager.hero.add_force(force_type, amount)
	
	# Fire any additional card effects
	if __button_entity.card:
		__button_entity.card.activate_slot_effect(__button_entity, null)
	
	production_fired.emit(self)
	
	# Reset timer
	_exit_ready_state()
	current_beats = 0
	_update_progress_display()

## Enter ready state (waiting for resources)
func _enter_ready_state() -> void:
	is_ready = true
	ready_state_entered.emit(self)
	
	# Visual feedback for ready state
	modulate = Color(1.2, 1.2, 1.2)  # Slight glow

## Exit ready state
func _exit_ready_state() -> void:
	is_ready = false
	ready_state_exited.emit(self)
	
	# Reset visual
	modulate = Color.WHITE

## Update the progress bar display
func _update_progress_display() -> void:
	if not %ProgressBar:
		return
		
	if production_interval_beats > 0:
		%ProgressBar.value = pct(current_beats, production_interval_beats)
	else:
		%ProgressBar.value = 0

## Get progress as percentage
func get_progress_percentage() -> float:
	if production_interval_beats <= 0:
		return 0.0
	return float(current_beats) / float(production_interval_beats) * 100.0

## Reset state for new complication
func reset() -> void:
	current_beats = 0
	is_ready = false
	force_consumption.clear()
	force_production.clear()
	_update_progress_display()
	modulate = Color.WHITE

## Get Escapement Order priority (for sorting)
func get_escapement_priority() -> int:
	# Convert 2D position to linear priority
	# Top-to-bottom, left-to-right
	return grid_position.y * 100 + grid_position.x