extends Node
class_name EndlessWaveManager

## Manages endless wave progression, difficulty, and rewards
## Spawns waves of gremlins with increasing difficulty
## Handles card selection rewards between waves

signal wave_started(wave_number: int, difficulty_value: int)
signal wave_completed(wave_number: int)
signal reward_card_selected(card: Card)
signal game_over()

var current_wave: int = 0
var current_difficulty_value: int = 0
var waves_completed: int = 0

# Waves sorted by numerical difficulty
var waves_by_difficulty: Array = []  # Array of wave_ids sorted by difficulty

# All wave data loaded from wave_data.json
var all_waves: Dictionary = {}

# Difficulty ranges for wave selection
var difficulty_per_wave: int = 10  # Increase difficulty target by 10 HP per wave

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
	all_waves.clear()
	waves_by_difficulty.clear()
	
	# Load from StaticData
	if StaticData.wave_data:
		for wave_id in StaticData.wave_data:
			var wave = StaticData.wave_data[wave_id]
			if not wave is Dictionary:
				continue
			var difficulty = wave.get("difficulty", 0)
			
			# Store wave data
			all_waves[wave_id] = wave
			
			# Add to sorted array
			waves_by_difficulty.append({"id": wave_id, "difficulty": difficulty})
	
	# Sort by difficulty
	waves_by_difficulty.sort_custom(func(a, b): return a.difficulty < b.difficulty)
	
	print("[EndlessWaveManager] Loaded ", all_waves.size(), " waves")
	print("  Difficulty range: ", 
		waves_by_difficulty[0].difficulty if waves_by_difficulty.size() > 0 else 0,
		" to ",
		waves_by_difficulty[-1].difficulty if waves_by_difficulty.size() > 0 else 0)

## Start a new run
func start_new_run() -> void:
	current_wave = 0
	waves_completed = 0
	current_difficulty_value = 0
	start_next_wave()

## Start the next wave
func start_next_wave() -> void:
	current_wave += 1
	
	# Calculate target difficulty for this wave
	# Start at 5 HP, increase by 10 HP per wave
	var target_difficulty = 5 + (current_wave - 1) * difficulty_per_wave
	
	# Allow a range of +/- 30% for variety
	var min_difficulty = int(target_difficulty * 0.7)
	var max_difficulty = int(target_difficulty * 1.3)
	
	print("[EndlessWaveManager] Wave ", current_wave, " - Target difficulty: ", target_difficulty, " (range: ", min_difficulty, "-", max_difficulty, ")")
	
	# Clear any remaining gremlins
	if GremlinSpawnController.instance:
		GremlinSpawnController.instance.clear_all_gremlins()
	
	# Select a wave within the difficulty range
	var wave_id = _select_wave_in_range(min_difficulty, max_difficulty)
	if not wave_id:
		print("[EndlessWaveManager] No waves available in range, expanding search...")
		# Expand range if no waves found
		wave_id = _select_wave_in_range(min_difficulty / 2, max_difficulty * 2)
	
	if not wave_id and waves_by_difficulty.size() > 0:
		# Fallback: pick closest wave to target
		wave_id = _select_closest_wave(target_difficulty)
	
	if not wave_id:
		print("[EndlessWaveManager] ERROR: No waves available!")
		return
		
	var wave_data = all_waves.get(wave_id, {})
	current_difficulty_value = wave_data.get("difficulty", 0)
	var gremlins_str = _get_gremlins_string(wave_data)
	
	print("[EndlessWaveManager] Selected: ", wave_data.get("display_name", wave_id), " (difficulty: ", current_difficulty_value, ")")
	
	# Spawn the wave
	if GremlinSpawnController.instance and not gremlins_str.is_empty():
		var gremlins = GremlinSpawnController.instance.spawn_wave(gremlins_str)
		print("[EndlessWaveManager] Spawned ", gremlins.size(), " gremlins")
	
	wave_started.emit(current_wave, current_difficulty_value)

## Select a random wave within a difficulty range
func _select_wave_in_range(min_diff: int, max_diff: int) -> String:
	var candidates = []
	
	for wave_data in waves_by_difficulty:
		if wave_data.difficulty >= min_diff and wave_data.difficulty <= max_diff:
			candidates.append(wave_data.id)
	
	if candidates.is_empty():
		return ""
	
	# Pick a random wave from candidates
	return candidates[randi() % candidates.size()]

## Select the wave closest to target difficulty
func _select_closest_wave(target_diff: int) -> String:
	if waves_by_difficulty.is_empty():
		return ""
	
	var best_wave = waves_by_difficulty[0]
	var best_distance = abs(best_wave.difficulty - target_diff)
	
	for wave_data in waves_by_difficulty:
		var distance = abs(wave_data.difficulty - target_diff)
		if distance < best_distance:
			best_distance = distance
			best_wave = wave_data
	
	return best_wave.id

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
	
	# Store cards for selection
	if GlobalGameManager.library:
		# For now, just add the first card directly to deck
		# TODO: Implement proper card selection UI
		if selected_cards.size() > 0:
			var chosen_card = selected_cards[0]
			GlobalGameManager.library.add_card_to_deck(chosen_card)
			reward_card_selected.emit(chosen_card)
			print("[EndlessWaveManager] Added reward card to deck: ", chosen_card.display_name)
	
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
		"difficulty_value": current_difficulty_value,
		"waves_completed": waves_completed
	}