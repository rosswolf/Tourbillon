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
var tourbillon_manager: TourbillonGameManager
var starting_deck_size: int = 15
var starting_hand_size: int = 5

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
	
	
	

func __load_tourbillon_cards() -> void:
	# Load the Tourbillon card data
	var card_file = "res://src/scenes/data/tourbillon_cards.json"
	
	if not FileAccess.file_exists(card_file):
		push_warning("Tourbillon card data not found at: " + card_file)
		return
	
	var file = FileAccess.open(card_file, FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	
	if parse_result != OK:
		push_error("Failed to parse Tourbillon card data")
		return
	
	# Add to StaticData for Card.load_card to use
	var card_data = json.data
	for card_entry in card_data:
		var card_id = card_entry.get("card_template_id", "")
		if card_id:
			StaticData.card_data[card_id] = card_entry
	
	print("Loaded ", card_data.size(), " Tourbillon cards")

func __setup_starting_deck() -> void:
	if not library:
		push_warning("Library not initialized")
		return
	
	# Create starting deck
	var starting_cards = [
		"basic_chronometer",
		"basic_chronometer",
		"simple_mainspring_heat",
		"simple_mainspring_heat",
		"simple_mainspring_precision",
		"simple_mainspring_precision",
		"force_converter"
	]
	
	# Add some random common cards to reach deck size
	var common_cards = [
		"micro_forge",
		"beast_cage",
		"precision_lathe",
		"micro_calibrator",
		"dust_accumulator"
	]
	
	while starting_cards.size() < starting_deck_size:
		var random_card = common_cards[randi() % common_cards.size()]
		starting_cards.append(random_card)
	
	# Load cards into library
	for card_id in starting_cards:
		var card = Card.load_card("tourbillon_base", card_id)
		if card:
			library.add_card_to_deck(card)
	
	# Shuffle deck  
	library.shuffle_libraries()
	
	# Draw starting hand
	library.draw_card(starting_hand_size)
	
	print("Starting deck created with ", starting_cards.size(), " cards")

func __load_hand() -> void:
	library.deck.shuffle()
	library.draw_new_hand(5)
		
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
	
	# Initialize Tourbillon system directly
	print("Initializing Tourbillon systems...")
	tourbillon_manager = TourbillonGameManager.new()
	add_child(tourbillon_manager)
	
	# Load card data and setup deck
	__load_tourbillon_cards()
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

## Get the current tick from Tourbillon system
func get_current_tick() -> int:
	if tourbillon_manager:
		return tourbillon_manager.get_current_tick()
	return 0

## Get the current beat from Tourbillon system
func get_current_beat() -> int:
	if tourbillon_manager:
		return tourbillon_manager.get_current_beat()
	return 0
		
# Convenience Functions for checking resource state
func have_enough_gold(value: int):
	return GlobalGameManager.hero.gold.have_enough(value)	

func have_enough_training_points(value: int):
	return GlobalGameManager.hero.training_points.have_enough(value)
	
func have_enough_endurance(value: int):
	return GlobalGameManager.hero.endurance.have_enough(value)
	
func have_enough_instinct(value: int):
	return GlobalGameManager.hero.instinct.have_enough(value)
	
