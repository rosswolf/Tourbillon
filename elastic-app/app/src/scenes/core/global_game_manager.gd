extends Node

# Game state properties
var hero_template_id: String # Set from character selection screen
var world_seed: int

var instance_catalog: InstanceCatalog
var library: Library
var hero: Hero
var relic_manager: RelicManager
# Goal system removed - use gremlins instead
var stats_manager: StatsManager

# Tourbillon system integration
var timeline_manager: TimelineManager
var beat_processor: BeatProcessor
var mainplate: Mainplate  # Core mainplate entity
var starting_deck_size: int = 15
var starting_hand_size: int = 5

# Beat/tick tracking
var current_beat: int = 0  # Current beat count
var current_tick: int = 0  # Current tick = current_beat / 10
var is_paused: bool = false

var hand_size: int = 5
var current_act: int = 1
var __activations_allowed: bool = false



# Core functionality
func _ready():
	GlobalSignals.ui_started_game.connect(__on_start_game)
	GlobalSignals.ui_started_battle.connect(__on_start_battle)
	GlobalSignals.ui_execute_selected_onto_hovered.connect(__handle_activation)
	GlobalSignals.core_card_discarded.connect(__on_card_discarded)
	GlobalSignals.core_card_played.connect(__on_card_played)
	GlobalSignals.core_card_destroyed.connect(__on_card_destroyed)
	GlobalSignals.core_slot_activated.connect(__on_core_slot_activated)
	# Air meter signals removed - no longer used
	GlobalSignals.core_card_drawn.connect(__on_core_card_drawn)
	
	# Enable process for debug input
	set_process(true)

func _process(_delta: float) -> void:
	# Debug input for testing
	if Input.is_action_just_pressed("ui_page_down"):  # PageDown key
		print("[DEBUG] PageDown pressed - Advancing time by 1 tick (10 beats)")
		if timeline_manager:
			print("[DEBUG] Current tick before: ", timeline_manager.get_current_tick())
			timeline_manager.advance_time(1)
			print("[DEBUG] Current tick after: ", timeline_manager.get_current_tick())
		else:
			push_error("[DEBUG] No timeline_manager available!")
	
	if Input.is_action_just_pressed("ui_page_up"):  # PageUp key  
		print("[DEBUG] PageUp pressed - Drawing a card")
		if library:
			library.draw_card(1)
	
	if Input.is_action_just_pressed("ui_end"):  # End key
		print("[DEBUG] End pressed - Spawning test gremlin")
		__spawn_test_gremlin()

func __setup_starting_deck() -> void:
	if not library:
		push_warning("Library not initialized")
		return
	
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
		
func __handle_activation(source_instance_id: String, target_instance_id: String):
	GlobalGameManager.activate(source_instance_id, target_instance_id)


func __on_start_game():
	reset_game_state()
	
	#world_seed = StaticData.get_int("world_seed")
	world_seed = int(Time.get_unix_time_from_system())
	seed(world_seed)
	GlobalUtilities.set_seed(world_seed)
	
	instance_catalog = InstanceCatalog.new()
	library = Library.new()
	relic_manager = RelicManager.new()
	hero = Hero.load_hero(hero_template_id)
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
	
func __on_start_battle():
	library.deck.shuffle()
	
	hero.reset_start_of_battle()
	__load_hand()
	
	#battleground.spawn_new_stage(1)
	allow_activations()
	GlobalSignals.signal_core_begin_turn()
	
# Air meter expired handler removed - no longer used
	
# Air meter time bump handler removed - no longer used
		
		
func __on_card_played(card_instance_id: String):
	var card: Card = instance_catalog.get_instance(card_instance_id) as Card
	if card == null:
		assert(false, "Card was null when retrieving from instance catalog: " + card_instance_id)
		return	
	GlobalSignals.signal_stats_cards_played(1)
	if card.durability.amount > 0:
		card.durability.decrement(1)
		
func __on_card_discarded(card_instance_id: String):
	var card: Card = instance_catalog.get_instance(card_instance_id) as Card
	if card == null:
		assert(false, "Card was null when retrieving from instance catalog: " + card_instance_id)
		return
		
func __on_card_destroyed(card_instance_id: String):
	var card: Card = instance_catalog.get_instance(card_instance_id) as Card
	if card == null:
		assert(false, "Card was null when retrieving from instance catalog: " + card_instance_id)
		return
	
	GlobalSignals.signal_stats_cards_popped(1)
	GlobalGameManager.library.move_card_to_zone2(card.instance_id, Library.Zone.ANY, Library.Zone.EXILED)
			
func __on_core_slot_activated(card_instance_id: String):
	var card: Card = instance_catalog.get_instance(card_instance_id) as Card
	if card == null:
		assert(false, "Card was null when retrieving from instance catalog: " + card_instance_id)
		return
	GlobalSignals.signal_stats_slots_activated(1)
	# Don't decrement durability for Tourbillon cards - they stay on the mainplate
	# card.durability.decrement(1)  # DISABLED - cards should persist

func __on_core_card_drawn(card_instance_id: String):
	GlobalSignals.signal_stats_cards_drawn(1)

func allow_activations():
	__activations_allowed = true
	
func disallow_activations():
	__activations_allowed = false
	
func reset_game_state():
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
	
func activate(source_id: String, target_id: String):	
	if not __activations_allowed:
		return
		
	var source: Entity = GlobalGameManager.instance_catalog.get_instance(source_id)
	var target: Entity = GlobalGameManager.instance_catalog.get_instance(target_id)
	
	if source == null:
		assert(false, "Null source specified on activate")
		return
	
	var result: bool = ActivationLogic.activate(source, target)
	print("Result of execute: " + str(result))
	
func get_selected_card() -> Card:
	if not GlobalSelectionManager.is_card_selected():
		printerr("Attempted to get selected card when a card was not selected - this should not happen")
		
	return instance_catalog.get_instance(
		GlobalSelectionManager.get_selected()) as Card

	
func end_turn():
	GlobalSignals.signal_core_end_turn()
	disallow_activations()
	library.draw_new_hand(hand_size)
	hero.reset_turn_resources()
	allow_activations()
	GlobalSignals.signal_core_begin_turn()


func end_game():
	GlobalSignals.signal_core_game_over()

## Initialize Tourbillon time systems
func __initialize_tourbillon_systems() -> void:
	# Create and add timeline manager (which creates its own beat processor)
	timeline_manager = TimelineManager.new()
	add_child(timeline_manager)
	
	# Get the beat processor from timeline manager
	beat_processor = timeline_manager.beat_processor
	
	# Create mainplate entity (4x4 grid)
	# The builder will automatically register it in the instance catalog
	mainplate = Mainplate.MainplateBuilder.new() \
		.with_grid_size(Vector2i(4, 4)) \
		.with_max_grid_size(Vector2i(8, 8)) \
		.build()
	add_child(mainplate)
	
	# CRITICAL: Connect the mainplate to the beat processor!
	if beat_processor:
		beat_processor.set_mainplate(mainplate)
	else:
		push_error("BeatProcessor not found in TimelineManager!")
	
	# Connect timeline signals
	timeline_manager.time_changed.connect(__on_time_changed)
	timeline_manager.card_ticks_complete.connect(__on_card_ticks_complete)
	
	# Connect to card playing signals
	GlobalSignals.core_card_played.connect(__on_tourbillon_card_played)
	GlobalSignals.core_card_slotted.connect(__on_card_slotted)
	GlobalSignals.core_slot_activated.connect(__on_slot_activated)

## Called when a card is played (Tourbillon time advancement)
func __on_tourbillon_card_played(card_id: String) -> void:
	print("[DEBUG] Card played signal received for ID: ", card_id)
	var card: Card = library.get_card(card_id)
	if not card:
		print("[DEBUG] Card not found in library for ID: ", card_id)
		# Try to get from instance catalog
		card = instance_catalog.get_instance(card_id) as Card
		if not card:
			print("[ERROR] Card not found anywhere for ID: ", card_id)
			return
	
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
		TourbillonEffectProcessor.process_effect(card.on_play_effect, null, null)

## Called when a card is slotted on the mainplate
func __on_card_slotted(slot_id: String) -> void:
	var slot: EngineSlot = __find_slot_by_id(slot_id)
	if not slot:
		return
	
	var card: Card = slot.__button_entity.card if slot.__button_entity else null
	if not card:
		return
	
	# Setup the gear from card data
	assert(slot != null, "Slot must exist for card setup")
	# Slots should implement setup_from_card if they accept cards
	slot.setup_from_card(card)
	
	# Process on_place_effect if it exists
	if not card.on_place_effect.is_empty():
		TourbillonEffectProcessor.process_effect(card.on_place_effect, slot, null)
	
	print("Gear placed: ", card.display_name, " - Interval: ", card.production_interval, " ticks")

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
	var time_display: String = "%d.%d" % [ticks, beats]
	print("Updating time display: ", time_display, " (total beats: ", total_beats, ")")
	GlobalSignals.signal_ui_time_updated(time_display)

## Called when card's time cost is fully processed
func __on_card_ticks_complete() -> void:
	# Signal UI that card processing is done
	GlobalSignals.signal_ui_card_ticks_resolved()

## Process all gears on the mainplate
func __process_mainplate_gears(context: BeatContext) -> void:
	if not mainplate:
		return
	
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

## Find a slot by its ID
func __find_slot_by_id(slot_id: String) -> EngineSlot:
	# TODO: This needs to access the UI mainplate, not the core entity
	# For now, return null - slots should be found through the UI layer
	return null

## Get the current tick from Tourbillon system
func get_current_tick() -> int:
	return current_tick

## Get the current beat from Tourbillon system
func get_current_beat() -> int:
	if timeline_manager:
		return timeline_manager.get_current_beats()
	return 0
		
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
	var gremlin_types = [
		"dust_mite",  # Heat soft cap
		"drain_gnat",  # Drains random resources
		"constricting_barrier_gnat",  # Max resource soft cap
		"gear_tick",  # Precision soft cap
		"oil_thief"  # Drains all types
	]
	var chosen_type = gremlin_types.pick_random()
	
	if chosen_type in mob_data:
		var data = mob_data[chosen_type]
		var gremlin = Gremlin.new()
		gremlin.gremlin_name = data.get("display_name", "Unknown Gremlin")
		gremlin.max_hp = data.get("max_health", 10)
		gremlin.current_hp = gremlin.max_hp
		gremlin.shields = data.get("max_shields", 0)
		gremlin.moves_string = data.get("moves", "")  # Set moves/downsides
		
		# The disruption timing will be set by the moves processor
		# Don't set it manually here anymore
		
		# Register and signal
		instance_catalog.register_instance(gremlin)
		add_child(gremlin)  # Add to scene tree
		GlobalSignals.signal_core_mob_created(gremlin.instance_id)
		
		print("[DEBUG] Spawned gremlin: ", gremlin.gremlin_name, " with ", gremlin.current_hp, " HP")
	
