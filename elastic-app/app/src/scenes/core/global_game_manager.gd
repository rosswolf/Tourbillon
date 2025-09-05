extends Node

# SimpleEffectProcessor is available via class_name

# Game state properties
var hero_template_id: String = "knight" # Default hero for testing
var world_seed: int = 0

var instance_catalog: InstanceCatalog = null
var library: Library = null
var hero: Hero = null
var relic_manager: RelicManager = null
# Goal system removed - use gremlins instead
var stats_manager: StatsManager = null

# Tourbillon system integration
var timeline_manager: TimelineManager = null
# BeatProcessor is now owned by TimelineManager - access via timeline_manager.get_beat_processor()
var mainplate: Mainplate = null  # Core mainplate entity
var starting_deck_size: int = 15
var starting_hand_size: int = 5

# Beat/tick tracking
var current_beat: int = 0  # Current beat count
var current_tick: int = 0  # Current tick = current_beat / 10
var is_paused: bool = false
var beat_speed_ms: float = 50.0  # Milliseconds between beats for smooth playback

var hand_size: int = 5
var current_act: int = 1
var __activations_allowed: bool = false



# Core functionality
# Signal connections moved to _init() for immediate availability
func _init() -> void:
	# Connect signals immediately on creation
	GlobalSignals.ui_started_game.connect(__on_start_game)
	GlobalSignals.ui_started_battle.connect(__on_start_battle)
	GlobalSignals.ui_execute_selected_onto_hovered.connect(__handle_activation)
	GlobalSignals.core_card_discarded.connect(__on_card_discarded)
	GlobalSignals.core_card_played.connect(__on_card_played)
	GlobalSignals.core_card_destroyed.connect(__on_card_destroyed)
	GlobalSignals.core_slot_activated.connect(__on_core_slot_activated)
	# Air meter signals removed - no longer used
	GlobalSignals.core_card_drawn.connect(__on_core_card_drawn)


func __setup_starting_deck() -> void:
	assert(library != null, "Library must be initialized before setting up starting deck")
	
	# Load all STARTING rarity cards from StaticData
	print("Loading starter deck...")
	var starter_count: int = 0
	
	for card_id in StaticData.card_data:
		var card_entry: Dictionary = StaticData.card_data[card_id]
		
		# Check if this is a starter card by looking at keywords
		var keywords: String = card_entry.get("keywords", "") as String
		var is_starter: bool = keywords.contains("starter")
		
		# Alternative: check rarity (in case we want to use rarity-based selection later)
		# var rarity: Variant = card_entry.get("card_rarity", Card.RarityType.UNKNOWN)
		# is_starter = (rarity == Card.RarityType.COMMON) if rarity is int else ("COMMON" in str(rarity))
		
		if is_starter:
			var group_id: String = card_entry.get("group_template_id", "tourbillon") as String
			var card: Card = Card.load_card(group_id, card_id as String)
			if card:
				library.add_card_to_deck(card)
				starter_count += 1
				print("  Added starter card: ", card.display_name)
			else:
				push_warning("Failed to load starter card: " + card_id)
	
	print("Loaded ", starter_count, " starter cards into deck")
	
	# Shuffle deck  
	library.shuffle_libraries()
	
	# Draw random cards for starting hand
	library.draw_card(starting_hand_size)
	
	print("Drew ", starting_hand_size, " cards for starting hand")

func __load_hand() -> void:
	library.deck.shuffle()
	library.draw_new_hand(hand_size)
		
func __handle_activation(source_instance_id: String, target_instance_id: String) -> void:
	GlobalGameManager.activate(source_instance_id, target_instance_id)


func __on_start_game() -> void:
	reset_game_state()
	
	#world_seed = StaticData.get_int("world_seed")
	world_seed = int(Time.get_unix_time_from_system())
	seed(world_seed)
	GlobalUtilities.set_seed(world_seed)
	
	instance_catalog = InstanceCatalog.new()
	library = Library.new()
	relic_manager = RelicManager.new()
	# Use HeroBuilder for proper instance ID registration
	hero = Hero.HeroBuilder.new() \
		.with_template_id("knight") \
		.build()
	# Goal system removed
	stats_manager = StatsManager.new()
	
	# Initialize Tourbillon systems directly
	print("Initializing Tourbillon systems...")
	__initialize_tourbillon_systems()
	
	# Load card data and setup deck
	__setup_starting_deck()
	
	print("Tourbillon systems initialized")
	
	# Start battle
	__on_start_battle()
	
func __on_start_battle() -> void:
	library.deck.shuffle()
	
	if hero:
		hero.reset_start_of_battle()
	__load_hand()
	
	#battleground.spawn_new_stage(1)
	allow_activations()
	GlobalSignals.signal_core_begin_turn()
	
# Air meter expired handler removed - no longer used
	
# Air meter time bump handler removed - no longer used
		
		
func __on_card_played(card_instance_id: String) -> void:
	var card: Card = instance_catalog.get_instance(card_instance_id) as Card
	if card == null:
		assert(false, "Card was null when retrieving from instance catalog: " + card_instance_id)
		return	
	GlobalSignals.signal_stats_cards_played(1)
		
func __on_card_discarded(card_instance_id: String) -> void:
	var card: Card = instance_catalog.get_instance(card_instance_id) as Card
	if card == null:
		assert(false, "Card was null when retrieving from instance catalog: " + card_instance_id)
		return
		
func __on_card_destroyed(card_instance_id: String) -> void:
	var card: Card = instance_catalog.get_instance(card_instance_id) as Card
	if card == null:
		assert(false, "Card was null when retrieving from instance catalog: " + card_instance_id)
		return
	
	GlobalSignals.signal_stats_cards_popped(1)
	GlobalGameManager.library.move_card_to_zone2(card.instance_id, Library.Zone.ANY, Library.Zone.EXILED)
			
func __on_core_slot_activated(card_instance_id: String) -> void:
	var card: Card = instance_catalog.get_instance(card_instance_id) as Card
	if card == null:
		assert(false, "Card was null when retrieving from instance catalog: " + card_instance_id)
		return
	GlobalSignals.signal_stats_slots_activated(1)

func __on_core_card_drawn(card_instance_id: String) -> void:
	GlobalSignals.signal_stats_cards_drawn(1)

func allow_activations() -> void:
	__activations_allowed = true
	
func disallow_activations() -> void:
	__activations_allowed = false
	
func reset_game_state() -> void:
	# Clean up existing objects if they exist
	if instance_catalog:
		instance_catalog.queue_free()
	if hero:
		hero.queue_free()
	if relic_manager:
		relic_manager.queue_free()
	
	instance_catalog = null
	library = null
	hero = null
	relic_manager = null
	# goal_manager = null # Removed
	
func activate(source_id: String, target_id: String) -> bool:	
	assert(__activations_allowed, "Activations must be allowed to handle activation")
	if not __activations_allowed:
		return false
		
	var source: Entity = GlobalGameManager.instance_catalog.get_instance(source_id)
	var target: Entity = GlobalGameManager.instance_catalog.get_instance(target_id)
	
	if source == null:
		assert(false, "Null source specified on activate")
		return false
	
	var result: bool = ActivationLogic.activate(source, target)
	print("Result of execute: " + str(result))
	return result
	
func get_selected_card() -> Card:
	if not GlobalSelectionManager.is_card_selected():
		printerr("Attempted to get selected card when a card was not selected - this should not happen")
		
	return instance_catalog.get_instance(
		GlobalSelectionManager.get_selected()) as Card

	
func end_turn() -> void:
	GlobalSignals.signal_core_end_turn()
	disallow_activations()
	library.draw_new_hand(hand_size)
	if hero:
		hero.reset_turn_resources()
	allow_activations()
	GlobalSignals.signal_core_begin_turn()


func end_game() -> void:
	GlobalSignals.signal_core_game_over()

## Initialize Tourbillon time systems
func __initialize_tourbillon_systems() -> void:
	# Create timeline manager (not as child since it's RefCounted)
	timeline_manager = TimelineManager.new()
	timeline_manager.set_beat_delay(beat_speed_ms)
	
	# Create mainplate entity (4x4 grid)
	# The builder will automatically register it in the instance catalog
	mainplate = Mainplate.MainplateBuilder.new() \
		.with_grid_size(Vector2i(4, 4)) \
		.with_max_grid_size(Vector2i(8, 8)) \
		.build()
	# Note: Core objects are not added to scene tree - they exist as pure data/logic
	
	# Connect mainplate to timeline's beat processor
	timeline_manager.set_mainplate(mainplate)
	
	# If we have gremlin manager, connect it (will be created later)
	# timeline_manager.set_gremlin_manager(gremlin_manager)
	
	# Connect timeline signals
	timeline_manager.time_changed.connect(__on_time_changed)
	timeline_manager.card_ticks_complete.connect(__on_card_ticks_complete)
	
	# Connect to card playing signals
	GlobalSignals.core_card_played.connect(__on_tourbillon_card_played)
	# Removed __on_card_slotted - this is handled by the UI layer reacting to signals
	GlobalSignals.core_slot_activated.connect(__on_slot_activated)

## Called when a card is played (Tourbillon time advancement)
func __on_tourbillon_card_played(card_id: String) -> void:
	print("[DEBUG] Card played signal received for ID: ", card_id)
	var card: Card = library.get_card(card_id)
	if not card:
		print("[DEBUG] Card not found in library for ID: ", card_id)
		# Try to get from instance catalog
		card = instance_catalog.get_instance(card_id) as Card
		assert(card != null, "Card must exist: " + card_id)
	
	print("[DEBUG] Card found: ", card.display_name, ", time_cost: ", card.time_cost)
	
	# Check if card has time cost
	if card.time_cost > 0:
		# Advance time by the card's time cost
		print("Card played: ", card.display_name, " - Advancing ", card.time_cost, " ticks")
		timeline_manager.advance_time(card.time_cost)
	else:
		print("[DEBUG] Card has no time cost, not advancing time")
	
	# Process on_play_effect if it exists
	if not card.on_play_effect.is_empty():
		SimpleEffectProcessor.process_effects(card.on_play_effect, null)

# Card slotting is now handled entirely by the Mainplate entity
# The UI layer reacts to core_card_slotted signals for visual updates

## Called when a slot is manually activated
func __on_slot_activated(slot_id: String) -> void:
	# Manual activation could advance time slightly
	# For now, just log it
	print("Slot manually activated: ", slot_id)

## Called when time changes
func __on_time_changed(total_beats: int) -> void:
	current_beat = total_beats
	current_tick = total_beats / 10
	
	# Update UI with formatted time display
	var ticks: int = total_beats / 10
	var beats: int = total_beats % 10
	# Convert beats to milliseconds display (each beat = 100ms)
	var milliseconds: int = beats * 100
	var time_display: String = "%d.%03d" % [ticks, milliseconds]
	print("Updating time display: ", time_display, " (total beats: ", total_beats, ")")
	GlobalSignals.signal_ui_time_updated(time_display)

## Called when card's time cost is fully processed
func __on_card_ticks_complete() -> void:
	# Signal UI that card processing is done
	GlobalSignals.signal_ui_card_ticks_resolved()

## Process all gears on the mainplate
func __process_mainplate_gears(context: BeatContext) -> void:
	assert(mainplate != null, "Mainplate must exist to process beats")
	
	# Let the core mainplate process the beat
	# It will emit signals for each card that needs processing
	mainplate.process_beat(context)

## Advance time by a number of ticks
func __advance_time_by_ticks(ticks: int) -> void:
	if timeline_manager:
		timeline_manager.advance_time(ticks)  # advance_time takes ticks as float

## Advance time by a number of beats
func __advance_time_by_beats(beats: int) -> void:
	if timeline_manager:
		timeline_manager.advance_time(beats / 10.0)  # Convert beats to ticks

# Slot finding has been removed - UI layer handles all slot updates via signals from core

## Get the current tick from Tourbillon system
func get_current_tick() -> int:
	return current_tick

## Get the current beat from Tourbillon system
func get_current_beat() -> int:
	if timeline_manager:
		return timeline_manager.get_current_beats()
	return 0

## Get the beat processor (goes through timeline_manager)
func get_beat_processor() -> BeatProcessor:
	if timeline_manager:
		return timeline_manager.get_beat_processor()
	return null
		
# Convenience Functions for checking resource state
# Resources should be checked via hero.has_force() or hero.has_forces() methods

## Debug function to spawn a test gremlin
func __spawn_test_gremlin() -> void:
	if not instance_catalog:
		push_error("Instance catalog not initialized!")
		return
		
	# Load a gremlin from mob_data
	var mob_data = StaticData.mob_data
	if not mob_data:
		push_error("No mob data loaded!")
		return
	
	# Pick a random gremlin type with interesting downsides
	var gremlin_types: Array[String] = [
		"dust_mite",  # Heat soft cap
		"drain_gnat",  # Drains random resources
		"constricting_barrier_gnat",  # Max resource soft cap
		"gear_tick",  # Precision soft cap
		"oil_thief"  # Drains all types
	]
	var chosen_type = gremlin_types.pick_random()
	
	if chosen_type in mob_data:
		var data = mob_data[chosen_type]
		var gremlin: Gremlin = Gremlin.new()
		gremlin.gremlin_name = data.get("display_name", "Unknown Gremlin")
		gremlin.max_hp = data.get("max_health", 10)
		gremlin.current_hp = gremlin.max_hp
		gremlin.shields = data.get("max_shields", 0)
		gremlin.moves_string = data.get("moves", "")  # Set moves/downsides
		
		# The disruption timing will be set by the moves processor
		# Don't set it manually here anymore
		
		# Register and signal
		instance_catalog.set_instance(gremlin)
		# Note: Core objects are not added to scene tree - they exist as pure data/logic
		GlobalSignals.signal_core_mob_created(gremlin.instance_id)
		
		print("[DEBUG] Spawned gremlin: ", gremlin.gremlin_name, " with ", gremlin.current_hp, " HP")
	
