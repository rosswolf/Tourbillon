extends Node

# Game state properties
var hero_template_id: String # Set from character selection screen
var world_seed: int

var instance_catalog: InstanceCatalog
var hand_size: int = 5
var current_act = 1
var __activations_allowed: bool = false



# Core functionality
func _ready():
	GlobalSignals.ui_started_game.connect(__on_start_game)
	GlobalSignals.ui_started_battle.connect(__on_start_battle)
	GlobalSignals.ui_execute_selected_onto_hovered.connect(__handle_activation)
	GlobalSignals.core_card_drawn.connect(__on_core_card_drawn)
	
	
	

func __load_cards() -> void:
	var rare_card_template_ids: Array[String] = []
	var uncommon_card_template_ids: Array[String] = []
	var common_card_template_ids: Array[String] = []
	var default_card_template_ids: Array[String] = []
	var starting_card_template_ids: Array[String] = []

func __handle_activation(source_instance_id: String, target_instance_id: String):
	GlobalGameManager.activate(source_instance_id, target_instance_id)


func __on_start_game():
	reset_game_state()
	
	#world_seed = StaticData.get_int("world_seed")
	world_seed = int(Time.get_unix_time_from_system())
	seed(world_seed)
	GlobalUtilities.set_seed(world_seed)
	
	instance_catalog = InstanceCatalog.new()

	__load_cards()
	
	# TODO: temporary, will be called via signal
	__on_start_battle()
	
func __on_start_battle():
	
	#battleground.spawn_new_stage(1)
	allow_activations()
	GlobalSignals.signal_core_begin_turn()
	
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
	
	
	instance_catalog = null
	
	
	
func end_turn():
	GlobalSignals.signal_core_end_turn()
	disallow_activations()
	allow_activations()
	GlobalSignals.signal_core_begin_turn()


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
	
