extends Node

# Game state properties
var hero_template_id: String # Set from character selection screen
var world_seed: int

var instance_catalog: InstanceCatalog
var library: Library
var hero: Hero
var relic_manager: RelicManager
var goal_manager: GoalManager
var stats_manager: StatsManager

# Tourbillon system integration
var timeline_manager: TimelineManager
var beat_processor: BeatProcessor
var mainplate: Mainplate
var starting_deck_size: int = 15
var starting_hand_size: int = 5

# Beat/tick tracking
var current_beat: int = 0  # Current beat count
var current_tick: int = 0  # Current tick = current_beat / 10
var is_paused: bool = false

var hand_size: int = 5
var current_act = 1
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
	
	
	

func __setup_starting_deck() -> void:
	if not library:
		push_warning("Library not initialized")
		return
	
	# Load all STARTING rarity cards from StaticData
	print("Loading starter deck...")
	var starter_count = 0
	
	for card_id in StaticData.card_data:
		var card_entry = StaticData.card_data[card_id]
		# Check if this is a STARTING rarity card
		if card_entry.has("card_rarity"):
			var rarity = card_entry["card_rarity"]
			# Check for STARTING rarity (handles both enum value and string)
			if rarity == Card.RarityType.STARTING or (rarity is String and "STARTING" in rarity):
				var group_id = card_entry.get("group_template_id", "tourbillon")
				var card = Card.load_card(group_id, card_id)
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
	goal_manager = GoalManager.new()
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
	card.durability.decrement(1)

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
	goal_manager = null
	
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
	# Create and add timeline manager
	timeline_manager = TimelineManager.new()
	add_child(timeline_manager)
	
	# Create and add beat processor
	beat_processor = BeatProcessor.new()
	add_child(beat_processor)
	
	# Connect timeline signals
	timeline_manager.time_changed.connect(__on_time_changed)
	timeline_manager.card_ticks_complete.connect(__on_card_ticks_complete)
	
	# Connect to card playing signals
	GlobalSignals.core_card_played.connect(__on_tourbillon_card_played)
	GlobalSignals.core_card_slotted.connect(__on_card_slotted)
	GlobalSignals.core_slot_activated.connect(__on_slot_activated)

## Called when a card is played (Tourbillon time advancement)
func __on_tourbillon_card_played(card_id: String) -> void:
	var card = library.get_card(card_id)
	if not card:
		return
	
	# Check if card has time cost
	if card.time_cost > 0:
		# Advance time by the card's time cost
		print("Card played: ", card.display_name, " - Advancing ", card.time_cost, " ticks")
		timeline_manager.advance_time(card.time_cost)
	
	# Process on_play_effect if it exists
	if not card.on_play_effect.is_empty():
		TourbillonEffectProcessor.process_effect(card.on_play_effect, null, null)

## Called when a card is slotted on the mainplate
func __on_card_slotted(slot_id: String) -> void:
	var slot = __find_slot_by_id(slot_id)
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
func __on_slot_activated(slot_id: String) -> void:
	# Manual activation could advance time slightly
	# For now, just log it
	print("Slot manually activated: ", slot_id)

## Called when time changes
func __on_time_changed(total_beats: int) -> void:
	current_beat = total_beats
	current_tick = total_beats / 10
	
	# Update UI with formatted time display
	var ticks = total_beats / 10
	var beats = total_beats % 10
	GlobalSignals.signal_ui_time_updated("%d.%d" % [ticks, beats])

## Called when card's time cost is fully processed
func __on_card_ticks_complete() -> void:
	# Signal UI that card processing is done
	GlobalSignals.signal_ui_card_ticks_resolved()

## Process all gears on the mainplate
func __process_mainplate_gears(context: BeatContext) -> void:
	if not mainplate:
		return
	
	# Get all gears in Escapement Order
	var gears = mainplate.get_gears_in_order()
	
	for gear in gears:
		if gear.has_method("process_beat"):
			gear.process_beat(context)

## Advance time by a number of ticks
func __advance_time_by_ticks(ticks: int) -> void:
	if timeline_manager:
		timeline_manager.advance_ticks(ticks)

## Advance time by a number of beats
func __advance_time_by_beats(beats: int) -> void:
	if timeline_manager:
		timeline_manager.advance_beats(beats)

## Find a slot by its ID
func __find_slot_by_id(slot_id: String) -> EngineSlot:
	if not mainplate:
		return null
	
	var slots = mainplate.get_all_engine_slots()
	for slot in slots:
		if slot.__button_entity and slot.__button_entity.instance_id == slot_id:
			return slot
	
	return null

## Get the current tick from Tourbillon system
func get_current_tick() -> int:
	return current_tick

## Get the current beat from Tourbillon system
func get_current_beat() -> int:
	if timeline_manager:
		return timeline_manager.current_beat
	return 0
		
# Convenience Functions for checking resource state
# Resources should be checked via hero.has_force() or hero.has_forces() methods
	
