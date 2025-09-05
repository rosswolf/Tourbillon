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
	elif GremlinSpawnController.instance == null:
		print("[ERROR] [EndlessWaveManager] GremlinSpawnController.instance is null!")
	elif gremlins_str.is_empty():
		print("[ERROR] [EndlessWaveManager] Empty gremlins string!")
	
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
	if gremlins is String and not gremlins.is_empty():
		return gremlins
	elif gremlins is Array and gremlins.size() > 0:
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
	
	# Get 3 cards for selection
	var reward_cards = _get_reward_card_pool()
	
	if reward_cards.is_empty():
		print("[WARNING] No reward cards generated, starting next wave")
		start_next_wave()
		return
	
	# Show card selection UI with the 3 cards
	# The UI will call back to us when selection is made
	GlobalSignals.signal_ui_show_card_selection(reward_cards)
	print("[EndlessWaveManager] Showing card selection with ", reward_cards.size(), " cards")
	
	# Connect to handle the selection result
	if not GlobalSignals.ui_card_selection_made.is_connected(_on_reward_selected):
		GlobalSignals.ui_card_selection_made.connect(_on_reward_selected, CONNECT_ONE_SHOT)

## Get pool of cards available as rewards
func _get_reward_card_pool() -> Array[Card]:
	var cards: Array[Card] = []
	
	# Get cards directly from StaticData instead of library zones
	if StaticData.card_data.is_empty():
		print("[ERROR] No card data loaded!")
		return cards
	
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
		
		var target_rarity: String
		if roll < rarity_weights["rare"]:
			target_rarity = "RARE"
		elif roll < rarity_weights["rare"] + rarity_weights["uncommon"]:
			target_rarity = "UNCOMMON"  
		else:
			target_rarity = "COMMON"
		
		# Get all cards of target rarity from StaticData
		var matching_cards: Array[String] = []
		for card_id in StaticData.card_data:
			var card_entry: Dictionary = StaticData.card_data[card_id]
			var rarity = card_entry.get("card_rarity", "COMMON")
			
			# Handle both string and enum formats
			var rarity_str = str(rarity).to_upper()
			if rarity_str.contains(target_rarity):
				matching_cards.append(card_id)
		
		# Pick a random card from matching ones
		if matching_cards.size() > 0:
			var chosen_id = matching_cards[randi() % matching_cards.size()]
			var group_id = StaticData.card_data[chosen_id].get("group_template_id", "tourbillon")
			card = Card.load_card(group_id, chosen_id)
			
			if card:
				cards.append(card)
			else:
				print("[WARNING] Failed to load card: ", chosen_id)
	
	# If we couldn't get 3 cards, fill remaining slots with any available cards
	while cards.size() < 3:
		var all_card_ids = StaticData.card_data.keys()
		if all_card_ids.size() > 0:
			var random_id = all_card_ids[randi() % all_card_ids.size()]
			var group_id = StaticData.card_data[random_id].get("group_template_id", "tourbillon")
			var fallback_card = Card.load_card(group_id, random_id)
			if fallback_card:
				cards.append(fallback_card)
			else:
				break  # Avoid infinite loop if card loading is broken
		else:
			break
	
	print("[DEBUG] Generated ", cards.size(), " reward cards")
	for card in cards:
		print("  - ", card.display_name, " (", card.rarity, ")")
	
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
func _on_reward_selected(selected_card: Card) -> void:
	print("[WaveManager] Card reward selected: ", selected_card.display_name)
	
	# Add the selected card to the player's deck
	if GlobalGameManager.library and selected_card:
		GlobalGameManager.library.add_card_to_deck(selected_card)
		reward_card_selected.emit(selected_card)
		print("[EndlessWaveManager] Added reward card to deck: ", selected_card.display_name)
	
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
