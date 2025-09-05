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

# Wave pools by difficulty tier, loaded from wave_data.json
var wave_pools: Dictionary = {
	"Trivial": [],
	"Easy": [],
	"Medium": [],
	"Hard": [],
	"Nightmare": [],
	"Nightmare+": []
}

# All wave data loaded from wave_data.json
var all_waves: Dictionary = {}

func _ready() -> void:
	# Load wave data from StaticData
	_load_wave_data()
	
	# Connect to gremlin spawn controller
	if GremlinSpawnController.instance:
		GremlinSpawnController.instance.all_gremlins_defeated.connect(_on_all_gremlins_defeated)
	
	# Connect to GlobalGameManager
	GlobalSignals.core_game_over.connect(_on_game_over)

## Load wave data from StaticData
func _load_wave_data() -> void:
	# Clear existing pools
	for tier in wave_pools:
		wave_pools[tier].clear()
	all_waves.clear()
	
	# Load from StaticData
	if StaticData.wave_data:
		for wave in StaticData.wave_data:
			var wave_id = wave.get("wave_id", "")
			var difficulty_tier = wave.get("difficulty_tier", "Unknown")
			
			# Store wave data
			all_waves[wave_id] = wave
			
			# Add to appropriate difficulty pool
			if difficulty_tier in wave_pools:
				wave_pools[difficulty_tier].append(wave_id)
	
	print("[EndlessWaveManager] Loaded ", all_waves.size(), " waves")
	for tier in wave_pools:
		print("  ", tier, ": ", wave_pools[tier].size(), " waves")

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
	# Progressive difficulty: Trivial -> Easy -> Medium -> Hard -> Nightmare -> Nightmare+
	if current_wave <= 2:
		current_difficulty_tier = "Trivial"
	elif current_wave <= 4:
		current_difficulty_tier = "Easy"
	elif current_wave <= 6:
		current_difficulty_tier = "Medium"
	elif current_wave <= 9:
		current_difficulty_tier = "Hard"
	elif current_wave <= 12:
		current_difficulty_tier = "Nightmare"
	else:
		current_difficulty_tier = "Nightmare+"
	
	print("[EndlessWaveManager] Starting wave ", current_wave, " (", current_difficulty_tier, " difficulty)")
	
	# Clear any remaining gremlins
	if GremlinSpawnController.instance:
		GremlinSpawnController.instance.clear_all_gremlins()
	
	# Get a wave from the appropriate difficulty pool
	var wave_id = _select_wave_for_tier(current_difficulty_tier)
	if not wave_id:
		print("[EndlessWaveManager] No waves available for tier ", current_difficulty_tier)
		return
		
	var wave_data = all_waves.get(wave_id, {})
	var gremlins_str = _get_gremlins_string(wave_data)
	
	print("[EndlessWaveManager] Selected wave: ", wave_data.get("display_name", wave_id))
	
	# Spawn the wave
	if GremlinSpawnController.instance and not gremlins_str.is_empty():
		var gremlins = GremlinSpawnController.instance.spawn_wave(gremlins_str)
		print("[EndlessWaveManager] Spawned ", gremlins.size(), " gremlins")
	
	wave_started.emit(current_wave, current_difficulty_tier)

## Select a wave ID from the given difficulty tier
func _select_wave_for_tier(tier: String) -> String:
	var available_waves = wave_pools.get(tier, [])
	if available_waves.is_empty():
		# Fallback to easier tier if no waves available
		if tier == "Nightmare+":
			return _select_wave_for_tier("Nightmare")
		elif tier == "Nightmare":
			return _select_wave_for_tier("Hard")
		elif tier == "Hard":
			return _select_wave_for_tier("Medium")
		elif tier == "Medium":
			return _select_wave_for_tier("Easy")
		elif tier == "Easy":
			return _select_wave_for_tier("Trivial")
		return ""
	
	# Pick a random wave from the pool
	return available_waves[randi() % available_waves.size()]

## Convert wave data to gremlins spawn string
func _get_gremlins_string(wave_data: Dictionary) -> String:
	var gremlins = wave_data.get("gremlins", "")
	
	# Handle both string and array format
	if gremlins is String:
		return gremlins
	elif gremlins is Array:
		# Join array elements with pipe separator
		var gremlin_names: Array[String] = []
		for g in gremlins:
			gremlin_names.append(str(g))
		return "|".join(gremlin_names)
	
	return ""

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