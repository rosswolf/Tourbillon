extends Node

# Game state properties
var hero_template_id: String # Set from character selection screen
var world_seed: int

var instance_catalog: InstanceCatalog
var library: Library
var hero: Hero
var relic_manager: RelicManager

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
	

func __load_cards() -> void:
	var rare_card_template_ids: Array[String] = []
	var uncommon_card_template_ids: Array[String] = []
	var common_card_template_ids: Array[String] = []
	var default_card_template_ids: Array[String] = []
	var starting_card_template_ids: Array[String] = []
	
	rare_card_template_ids.assign(StaticData.lookup_in_data(StaticData.card_data,"card_rarity",Card.RarityType.RARE,"card_template_id"))
	uncommon_card_template_ids.assign(StaticData.lookup_in_data(StaticData.card_data,"card_rarity",Card.RarityType.UNCOMMON,"card_template_id"))
	common_card_template_ids.assign(StaticData.lookup_in_data(StaticData.card_data,"card_rarity",Card.RarityType.COMMON,"card_template_id"))
	default_card_template_ids.assign(StaticData.lookup_in_data(StaticData.card_data,"card_rarity",Card.RarityType.DEFAULT,"card_template_id"))
	starting_card_template_ids.assign(StaticData.lookup_in_data(StaticData.card_data,"card_rarity",Card.RarityType.STARTING,"card_template_id"))
	
	library.initialize_cards(
		Card.load_cards(hero_template_id, rare_card_template_ids),
		Card.load_cards(hero_template_id, uncommon_card_template_ids),
		Card.load_cards(hero_template_id, common_card_template_ids),
		Card.load_cards(hero_template_id, default_card_template_ids),
		Card.load_cards(hero_template_id, starting_card_template_ids)
	)

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

	__load_cards()
	
	# TODO: temporary, will be called via signal
	__on_start_battle()
	
func __on_start_battle():
	library.deck.shuffle()
	
	hero.reset_start_of_battle()
	__load_hand()
	
	#battleground.spawn_new_stage(1)
	allow_activations()
	GlobalSignals.signal_core_begin_turn()
		
func __on_card_played(card_instance_id: String):
	var card: Card = instance_catalog.get_instance(card_instance_id) as Card
	if card == null:
		assert(false, "Card was null when retrieving from instance catalog: " + card_instance_id)
		return	
	card.durability.decrement(1)
		
func __on_card_discarded(card_instance_id: String):
	var card: Card = instance_catalog.get_instance(card_instance_id) as Card
	if card == null:
		assert(false, "Card was null when retrieving from instance catalog: " + card_instance_id)
		return
			
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

func end_battle():
	GlobalSignals.signal_core_arena_destroyed("junk")
	GlobalSignals.signal_core_card_selection()

func end_game():
	GlobalSignals.signal_core_game_over()
		
# Convenience Functions for checking resource state
func have_enough_gold(value: int):
	return GlobalGameManager.hero.gold.have_enough(value)	

func have_enough_training_points(value: int):
	return GlobalGameManager.hero.training_points.have_enough(value)
	
func have_enough_endurance(value: int):
	return GlobalGameManager.hero.endurance.have_enough(value)
	
func have_enough_instinct(value: int):
	return GlobalGameManager.hero.instinct.have_enough(value)
	
