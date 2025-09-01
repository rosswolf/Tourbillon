extends Node
class_name TourbillonGameManager

## Manages the integration of all Tourbillon systems
## Connects TimelineManager, BeatProcessor, Mainplate, and card playing

# Core systems
var timeline_manager: TimelineManager
var beat_processor: BeatProcessor
var mainplate: Mainplate

# Game state
var current_tick: int = 0
var beats_per_tick: int = 10
var is_paused: bool = false

func _ready() -> void:
	_initialize_systems()
	_connect_signals()

func _initialize_systems() -> void:
	# Create and add timeline manager
	timeline_manager = TimelineManager.new()
	add_child(timeline_manager)
	
	# Create and add beat processor
	beat_processor = BeatProcessor.new()
	add_child(beat_processor)
	
	# Get or create mainplate
	if GlobalGameManager.has("mainplate"):
		mainplate = GlobalGameManager.get("mainplate")
	
	# Connect timeline to beat processor
	timeline_manager.beat_advanced.connect(_on_beat_advanced)
	timeline_manager.tick_completed.connect(_on_tick_completed)

func _connect_signals() -> void:
	# Connect to card playing signals
	GlobalSignals.core_card_played.connect(_on_card_played)
	GlobalSignals.core_card_slotted.connect(_on_card_slotted)
	
	# Connect to gear signals
	GlobalSignals.core_slot_activated.connect(_on_slot_activated)

## Called when a card is played from hand
func _on_card_played(card_id: String) -> void:
	var card = GlobalGameManager.library.get_card(card_id)
	if not card:
		return
	
	# Check if card has time cost
	if card.time_cost > 0:
		# Advance time by the card's time cost
		print("Card played: ", card.display_name, " - Advancing ", card.time_cost, " ticks")
		_advance_time_by_ticks(card.time_cost)
	
	# Process on_play_effect if it exists
	if not card.on_play_effect.is_empty():
		TourbillonEffectProcessor.process_effect(card.on_play_effect, null, null)

## Called when a card is slotted on the mainplate
func _on_card_slotted(slot_id: String) -> void:
	var slot = _find_slot_by_id(slot_id)
	if not slot:
		return
	
	var card = slot.__button_entity.card if slot.__button_entity else null
	if not card:
		return
	
	# Setup the gear from card data
	if slot.has_method("setup_from_card"):
		slot.setup_from_card(card)
	
	# Process on_place_effect if it exists
	if not card.on_place_effect.is_empty():
		TourbillonEffectProcessor.process_effect(card.on_place_effect, slot, null)
	
	print("Gear placed: ", card.display_name, " - Interval: ", card.production_interval, " ticks")

## Called when a slot is manually activated
func _on_slot_activated(slot_id: String) -> void:
	# Manual activation could advance time slightly
	# For now, just log it
	print("Slot manually activated: ", slot_id)

## Called each beat from TimelineManager
func _on_beat_advanced(beat_number: int) -> void:
	if is_paused:
		return
	
	# Create beat context
	var context = BeatContext.new()
	context.beat_number = beat_number
	context.tick_number = beat_number / beats_per_tick
	context.is_tick_boundary = (beat_number % beats_per_tick == 0)
	
	# Process all gears on mainplate
	_process_mainplate_gears(context)
	
	# Process any beat consumers (poison, burn, etc.)
	beat_processor.process_beat(context)

## Called when a tick is completed
func _on_tick_completed(tick_number: int) -> void:
	current_tick = tick_number
	print("Tick ", tick_number, " completed")
	
	# Update UI to show current tick
	GlobalSignals.signal_ui_tick_advanced(tick_number)

## Process all gears on the mainplate
func _process_mainplate_gears(context: BeatContext) -> void:
	if not mainplate:
		return
	
	# Get all gears in Escapement Order
	var gears = mainplate.get_gears_in_order()
	
	for gear in gears:
		if gear.has_method("process_beat"):
			gear.process_beat(context)

## Advance time by a number of ticks
func _advance_time_by_ticks(ticks: int) -> void:
	if timeline_manager:
		timeline_manager.advance_ticks(ticks)

## Advance time by a number of beats
func _advance_time_by_beats(beats: int) -> void:
	if timeline_manager:
		timeline_manager.advance_beats(beats)

## Find a slot by its ID
func _find_slot_by_id(slot_id: String) -> EngineSlot:
	if not mainplate:
		return null
	
	var slots = mainplate.get_all_engine_slots()
	for slot in slots:
		if slot.__button_entity and slot.__button_entity.instance_id == slot_id:
			return slot
	
	return null

## Pause/unpause the game
func set_paused(paused: bool) -> void:
	is_paused = paused
	if timeline_manager:
		timeline_manager.set_paused(paused)

## Get current game time
func get_current_tick() -> int:
	return current_tick

func get_current_beat() -> int:
	if timeline_manager:
		return timeline_manager.current_beat
	return 0

## Reset the game state
func reset_game() -> void:
	current_tick = 0
	if timeline_manager:
		timeline_manager.reset()
	if beat_processor:
		beat_processor.clear_consumers()