extends Node
class_name EndlessWaveManager

## Manages endless wave progression, difficulty, and rewards
## Spawns waves of gremlins with increasing difficulty
## Handles card selection rewards between waves

signal wave_started(wave_number: int, difficulty_tier: String)
signal wave_completed(wave_number: int)
signal reward_card_selected(card: Card)
signal game_over()

var current_wave: int = 0
var current_difficulty_tier: String = "easy"
var waves_completed: int = 0

# 3 waves per difficulty tier as requested
var wave_compositions: Dictionary = {
	"easy": [
		"dust_mite",
		"dust_mite|dust_mite",
		"dust_mite|oil_thief"
	],
	"medium": [
		"oil_thief|oil_thief",
		"dust_mite|dust_mite|oil_thief",
		"dust_mite|gear_grinder"
	],
	"hard": [
		"gear_grinder|gear_grinder",
		"oil_thief|oil_thief|gear_grinder",
		"dust_mite|oil_thief|gear_grinder"
	],
	"extreme": [
		"gear_grinder|gear_grinder|gear_grinder",
		"time_devourer",
		"time_devourer|gear_grinder"
	]
}

func _ready() -> void:
	# Connect to gremlin spawn controller
	if GremlinSpawnController.instance:
		GremlinSpawnController.instance.all_gremlins_defeated.connect(_on_all_gremlins_defeated)
	
	# Connect to GlobalGameManager
	GlobalSignals.core_game_over.connect(_on_game_over)

## Start a new run
func start_new_run() -> void:
	current_wave = 0
	waves_completed = 0
	current_difficulty_tier = "easy"
	start_next_wave()

## Start the next wave
func start_next_wave() -> void:
	current_wave += 1
	
	# Determine difficulty tier based on wave number
	# 3 waves per tier: 1-3 easy, 4-6 medium, 7-9 hard, 10+ extreme
	if current_wave <= 3:
		current_difficulty_tier = "easy"
	elif current_wave <= 6:
		current_difficulty_tier = "medium"
	elif current_wave <= 9:
		current_difficulty_tier = "hard"
	else:
		current_difficulty_tier = "extreme"
	
	print("[WaveManager] Starting wave ", current_wave, " (", current_difficulty_tier, " difficulty)")
	
	# Clear any remaining gremlins
	if GremlinSpawnController.instance:
		GremlinSpawnController.instance.clear_all_gremlins()
	
	# Get wave composition based on difficulty tier
	var composition = _get_wave_composition()
	
	# Spawn the wave (no stat scaling needed - difficulty comes from enemy types)
	if GremlinSpawnController.instance:
		var gremlins = GremlinSpawnController.instance.spawn_wave(composition)
		print("[WaveManager] Spawned ", gremlins.size(), " gremlins for wave ", current_wave)
	
	wave_started.emit(current_wave, current_difficulty_tier)

## Get wave composition based on current difficulty tier
func _get_wave_composition() -> String:
	var compositions = wave_compositions[current_difficulty_tier]
	
	# Pick the appropriate wave within the tier
	# Wave 1-3 use index 0-2 of easy, 4-6 use index 0-2 of medium, etc.
	var wave_in_tier = (current_wave - 1) % 3
	
	# Make sure we don't go out of bounds
	if wave_in_tier >= compositions.size():
		wave_in_tier = randi() % compositions.size()
	
	return compositions[wave_in_tier]

## Handle all gremlins defeated
func _on_all_gremlins_defeated() -> void:
	waves_completed += 1
	print("[WaveManager] Wave ", current_wave, " completed!")
	
	wave_completed.emit(current_wave)
	
	# Show card selection reward
	_show_card_reward()

## Show card selection modal for reward
func _show_card_reward() -> void:
	print("[WaveManager] Showing card selection reward")
	
	# Get 3 random cards for selection
	var available_cards = _get_reward_card_pool()
	var selected_cards: Array[Card] = []
	
	# Pick 3 random cards
	for i in range(min(3, available_cards.size())):
		var index = randi() % available_cards.size()
		selected_cards.append(available_cards[index])
		available_cards.remove_at(index)
	
	# Store cards in library's selection zone
	if GlobalGameManager.library:
		# Clear any previous selection
		GlobalGameManager.library.clear_zone(Library.Zone.SELECTION)
		
		# Add cards to selection zone
		for card in selected_cards:
			GlobalGameManager.library.add_card_to_zone(card, Library.Zone.SELECTION)
		
		# Trigger the card selection modal
		# The modal will handle adding the selected card to deck
		GlobalSignals.signal_core_card_selection("wave_reward", Library.Zone.DECK)
	
	# After card is selected, the modal will close and we continue
	# Connect to know when selection is done
	if not GlobalSignals.core_card_drawn.is_connected(_on_reward_selected):
		GlobalSignals.core_card_drawn.connect(_on_reward_selected, CONNECT_ONE_SHOT)

## Get pool of cards available as rewards
func _get_reward_card_pool() -> Array[Card]:
	var cards: Array[Card] = []
	
	# Get cards from the common/uncommon/rare libraries
	if GlobalGameManager.library:
		# Weight by rarity
		var rarity_weights = {
			"common": 60,
			"uncommon": 30,
			"rare": 10
		}
		
		# Higher waves have better rewards
		if current_wave >= 5:
			rarity_weights["rare"] = 20
			rarity_weights["uncommon"] = 40
			rarity_weights["common"] = 40
		
		# Build weighted pool
		for i in range(3):  # We need 3 cards
			var roll = randi() % 100
			var card: Card
			
			if roll < rarity_weights["rare"]:
				# Get a rare card
				var rare_cards = GlobalGameManager.library.get_cards_in_zone(Library.Zone.RARE_LIBRARY)
				if rare_cards.size() > 0:
					card = _create_card_from_template(rare_cards[randi() % rare_cards.size()])
			elif roll < rarity_weights["rare"] + rarity_weights["uncommon"]:
				# Get an uncommon card
				var uncommon_cards = GlobalGameManager.library.get_cards_in_zone(Library.Zone.UNCOMMON_LIBRARY)
				if uncommon_cards.size() > 0:
					card = _create_card_from_template(uncommon_cards[randi() % uncommon_cards.size()])
			
			# Default to common
			if not card:
				var common_cards = GlobalGameManager.library.get_cards_in_zone(Library.Zone.COMMON_LIBRARY)
				if common_cards.size() > 0:
					card = _create_card_from_template(common_cards[randi() % common_cards.size()])
			
			if card:
				cards.append(card)
	
	# Fallback: create some basic cards if no library
	if cards.is_empty():
		for i in range(3):
			var card = Card.new()
			card.display_name = "Test Card " + str(i)
			card.rules_text = "Test effect"
			card.rarity = Card.RarityType.COMMON
			cards.append(card)
	
	return cards

## Create a new instance of a card from template
func _create_card_from_template(template_card: Card) -> Card:
	# Create a new instance with the same properties
	var new_card = Card.new()
	
	# Copy properties
	new_card.display_name = template_card.display_name
	new_card.rules_text = template_card.rules_text
	new_card.rarity = template_card.rarity
	new_card.time_cost = template_card.time_cost
	new_card.production_interval = template_card.production_interval
	new_card.on_play_effect = template_card.on_play_effect
	new_card.on_fire_effect = template_card.on_fire_effect
	new_card.tags = template_card.tags
	new_card.keywords = template_card.keywords
	
	return new_card

## Called when a reward card is selected
func _on_reward_selected(card_id: String) -> void:
	print("[WaveManager] Card reward selected, starting next wave")
	
	# Small delay before next wave
	await get_tree().create_timer(1.0).timeout
	
	# Start the next wave
	start_next_wave()

## Handle game over
func _on_game_over() -> void:
	print("[WaveManager] Game Over! Waves completed: ", waves_completed)
	game_over.emit()

## Get current difficulty info
func get_difficulty_info() -> Dictionary:
	return {
		"wave": current_wave,
		"difficulty_tier": current_difficulty_tier,
		"waves_completed": waves_completed
	}