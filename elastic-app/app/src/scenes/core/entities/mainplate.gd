extends Entity
class_name Mainplate

## Core entity representing the Tourbillon mainplate (gear grid)
## Manages the logical grid state and slot positions

## Inner class to track card state
class CardState:
	var current_beats: int = 0
	var is_ready: bool = false
	var card_ref: Card
	
	func _init(card: Card) -> void:
		card_ref = card
		current_beats = card.starting_progress if card.has_meta("starting_progress") else 0

static func _get_type_string():
	return "Mainplate"

func _get_type() -> Entity.EntityType:
	return Entity.EntityType.MAINPLATE

var grid_size: Vector2i = Vector2i(4, 4)  # Current active grid size
var max_grid_size: Vector2i = Vector2i(8, 8)  # Maximum possible size
var slots: Dictionary[Vector2i, Card] = {}  # Position -> Card mapping
var card_states: Dictionary[String, CardState] = {}  # Card instance_id -> CardState mapping
var bonus_squares: Dictionary[Vector2i, String] = {}  # Position -> bonus type mapping
var expansions_used: int = 0
var max_expansions: int = 4

func __generate_instance_id() -> String:
	return "mainplate_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())

func __requires_template_id() -> bool:
	return false

## Check if a position is within the active grid
func is_valid_position(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < grid_size.x and pos.y >= 0 and pos.y < grid_size.y

## Check if a position has a card
func has_card_at(pos: Vector2i) -> bool:
	return slots.has(pos) and slots[pos] != null

## Get card at position
func get_card_at(pos: Vector2i) -> Card:
	if slots.has(pos):
		return slots[pos]
	return null

## Request card placement - handles ALL business logic for placing a card
func request_card_placement(card: Card, pos: Vector2i) -> bool:
	if not is_valid_position(pos):
		push_warning("Invalid position for card placement: " + str(pos))
		return false
	
	# Check if card can be placed (cost satisfaction happens in ActivationLogic)
	# Here we just handle the placement logic
	
	# Handle replacement if needed (Overbuild)
	if has_card_at(pos):
		var old_card = slots[pos]
		print("[OVERBUILD] Replacing ", old_card.display_name, " with ", card.display_name)
		
		# Process replacement effects on the old card
		if not old_card.on_replace_effect.is_empty():
			# Import SimpleEffectProcessor at top of file if needed
			var SimpleEffectProcessor = preload("res://src/scenes/core/effects/simple_effect_processor.gd")
			SimpleEffectProcessor.process_effects(old_card.on_replace_effect, old_card)
		
		# Move old card to graveyard
		if GlobalGameManager.library:
			GlobalGameManager.library.move_card_to_zone2(old_card.instance_id, Library.Zone.SLOTTED, Library.Zone.GRAVEYARD)
		
		# Signal old card was discarded
		GlobalSignals.signal_core_card_discarded(old_card.instance_id)
		
		# Transfer state if Overbuild tag
		if card.tags.has("Overbuild") and card_states.has(old_card.instance_id):
			var old_state = card_states[old_card.instance_id]
			card_states[card.instance_id] = old_state
			card_states.erase(old_card.instance_id)
		else:
			card_states[card.instance_id] = CardState.new(card)
		
		# Signal replacement for UI update
		GlobalSignals.signal_core_card_replaced(old_card.instance_id, card.instance_id)
	else:
		# New placement
		card_states[card.instance_id] = CardState.new(card)
		
		# Check and trigger bonus square
		if bonus_squares.has(pos):
			var bonus_type = bonus_squares[pos]
			__trigger_bonus(bonus_type)
			bonus_squares.erase(pos)
	
	# Move card to slotted zone
	if GlobalGameManager.library:
		GlobalGameManager.library.move_card_to_zone2(card.instance_id, Library.Zone.HAND, Library.Zone.SLOTTED)
	
	# Store card in slot
	slots[pos] = card
	
	# Process on_place_effect if it exists
	if not card.on_place_effect.is_empty():
		var SimpleEffectProcessor = preload("res://src/scenes/core/effects/simple_effect_processor.gd")
		SimpleEffectProcessor.process_effects(card.on_place_effect, null)
	
	# Signal successful placement (for UI and stats)
	GlobalSignals.signal_core_card_slotted(card.instance_id)
	GlobalSignals.signal_core_card_played(card.instance_id)
	GlobalSignals.signal_core_card_removed_from_hand(card.instance_id)
	
	return true

## Legacy place_card for backwards compatibility - delegates to request_card_placement
func place_card(card: Card, pos: Vector2i) -> bool:
	return request_card_placement(card, pos)

## Remove card from position
func remove_card(pos: Vector2i) -> Card:
	if not slots.has(pos):
		return null
	
	var card = slots[pos]
	slots.erase(pos)
	# Clean up card state
	if card_states.has(card.instance_id):
		card_states.erase(card.instance_id)
	return card

## Expand the grid
func expand_grid(direction: String) -> bool:
	if expansions_used >= max_expansions:
		return false
	
	match direction:
		"right":
			if grid_size.x < max_grid_size.x:
				grid_size.x += 1
				expansions_used += 1
				return true
		"down":
			if grid_size.y < max_grid_size.y:
				grid_size.y += 1
				expansions_used += 1
				return true
		"left":
			if grid_size.x < max_grid_size.x:
				# Shift all existing cards right
				var new_slots: Dictionary[Vector2i, Card] = {}
				for pos in slots:
					new_slots[pos + Vector2i(1, 0)] = slots[pos]
				slots = new_slots
				grid_size.x += 1
				expansions_used += 1
				return true
		"up":
			if grid_size.y < max_grid_size.y:
				# Shift all existing cards down
				var new_slots: Dictionary[Vector2i, Card] = {}
				for pos in slots:
					new_slots[pos + Vector2i(0, 1)] = slots[pos]
				slots = new_slots
				grid_size.y += 1
				expansions_used += 1
				return true
	
	return false

## Get all cards in Escapement Order (top-to-bottom, left-to-right)
func get_cards_in_order() -> Array[Card]:
	var cards: Array[Card] = []
	
	for pos in __get_positions_in_order():
		if has_card_at(pos):
			cards.append(get_card_at(pos))
	
	return cards

## Get all positions in Escapement Order
func __get_positions_in_order() -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			positions.append(Vector2i(x, y))
	
	return positions

## Process all gears for a beat
func process_beat(context: BeatContext) -> void:
	# Process each card in Escapement Order
	for pos in __get_positions_in_order():
		if has_card_at(pos):
			var card = get_card_at(pos)
			# Increment beat counter for cards with production
			if card_states.has(card.instance_id) and card.production_interval > 0:
				var state = card_states[card.instance_id]
				state.current_beats += 1
				
				# Check if card is ready (before potential activation)
				var interval_in_beats = card.production_interval * 10
				state.is_ready = state.current_beats >= interval_in_beats
			
			# Signal UI update BEFORE activation (so it sees the full progress)
			GlobalSignals.signal_core_gear_process_beat(card.instance_id, context)
			
			# Check if card should activate on this beat
			if __should_card_activate(card, pos, context):
				__activate_card(card, pos, context)

## Count cards with a specific tag
func count_cards_with_tag(tag: String) -> int:
	var count: int = 0
	for card in get_cards_in_order():
		if card.tags.has(tag):
			count += 1
	return count

## Get adjacent positions to a given position
func get_adjacent_positions(pos: Vector2i) -> Array[Vector2i]:
	var adjacent: Array[Vector2i] = []
	
	var offsets: Array[Vector2i] = [
		Vector2i(-1, 0),  # Left
		Vector2i(1, 0),   # Right
		Vector2i(0, -1),  # Up
		Vector2i(0, 1)    # Down
	]
	
	for offset in offsets:
		var adj_pos = pos + offset
		if is_valid_position(adj_pos):
			adjacent.append(adj_pos)
	
	return adjacent

## Check if a position is isolated (no adjacent cards)
func is_isolated(pos: Vector2i) -> bool:
	for adj_pos in get_adjacent_positions(pos):
		if has_card_at(adj_pos):
			return false
	return true

## Check if card should activate on this beat (pure check, no side effects)
func __should_card_activate(card: Card, pos: Vector2i, context: BeatContext) -> bool:
	if not card_states.has(card.instance_id):
		return false
		
	var state = card_states[card.instance_id]
	
	# Non-producing cards don't activate
	if card.production_interval <= 0:
		return false
	
	# Check if ready to activate
	var interval_in_beats = card.production_interval * 10  # Convert ticks to beats
	if state.current_beats >= interval_in_beats:
		# Check force requirements
		if GlobalGameManager.hero and not card.force_consumption.is_empty():
			return GlobalGameManager.hero.has_forces(card.force_consumption)
		return true
	
	return false

## Activate a card's effect
func __activate_card(card: Card, pos: Vector2i, context: BeatContext) -> void:
	if not card_states.has(card.instance_id):
		return
		
	var state = card_states[card.instance_id]
	
	# Process on_fire_effect - this handles all production, consumption, and other effects
	if not card.on_fire_effect.is_empty():
		pass
		#TODO FIX
		#TourbillonEffectProcessor.process_effect(card.on_fire_effect, self, null)
	
	# Legacy support: Check old force_consumption if effect doesn't exist
	# TODO: Remove once all cards are migrated to effects
	elif GlobalGameManager.hero and not card.force_consumption.is_empty():
		if not GlobalGameManager.hero.consume_forces(card.force_consumption):
			return  # Can't consume, stay ready
	
	# Signal activation for stats/UI
	GlobalSignals.signal_core_slot_activated(card.instance_id)
	
	# Reset timer
	state.current_beats = 0

## Set a position as a bonus square
func set_bonus_square(pos: Vector2i, bonus_type: String) -> void:
	if is_valid_position(pos) and not has_card_at(pos):
		bonus_squares[pos] = bonus_type

## Check if a position is a bonus square
func is_bonus_square(pos: Vector2i) -> bool:
	return bonus_squares.has(pos)

## Get bonus type at position
func get_bonus_type(pos: Vector2i) -> String:
	if bonus_squares.has(pos):
		return bonus_squares[pos]
	return ""

## Clear all bonus squares
func clear_bonus_squares() -> void:
	bonus_squares.clear()

## Assign random bonus squares to empty slots
func assign_random_bonus_squares() -> void:
	# Get all empty positions
	var empty_positions: Array[Vector2i] = []
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var pos: Vector2i = Vector2i(x, y)
			if not has_card_at(pos):
				empty_positions.append(pos)
	
	if empty_positions.is_empty():
		return
	
	# Calculate how many bonus squares (1/3 of empty slots, minimum 1)
	var bonus_count = max(1, empty_positions.size() / 3)
	
	# Shuffle positions
	empty_positions.shuffle()
	
	# Assign bonuses
	for i in range(min(bonus_count, empty_positions.size())):
		var pos = empty_positions[i]
		# First bonus is special (draws 2), rest draw 1
		if i == 0:
			set_bonus_square(pos, "draw_two_cards")
			print("[Mainplate] Special bonus square at ", pos)
		else:
			set_bonus_square(pos, "draw_one_card")
			print("[Mainplate] Bonus square at ", pos)

## Trigger bonus effect
func __trigger_bonus(bonus_type: String) -> void:
	match bonus_type:
		"draw_one_card":
			if GlobalGameManager.library:
				GlobalGameManager.library.draw_card(1)
				print("[Mainplate] Bonus triggered: Draw 1 card")
		"draw_two_cards":
			if GlobalGameManager.library:
				GlobalGameManager.library.draw_card(2)
				print("[Mainplate] SPECIAL bonus triggered: Draw 2 cards")

class MainplateBuilder extends Entity.EntityBuilder:
	var __grid_size: Vector2i = Vector2i(4, 4)
	var __max_grid_size: Vector2i = Vector2i(8, 8)
	
	func with_grid_size(size: Vector2i) -> MainplateBuilder:
		__grid_size = size
		return self
	
	func with_max_grid_size(size: Vector2i) -> MainplateBuilder:
		__max_grid_size = size
		return self
	
	func build() -> Mainplate:
		var mainplate: Mainplate = Mainplate.new()
		super.build_entity(mainplate)
		mainplate.grid_size = __grid_size
		mainplate.max_grid_size = __max_grid_size
		return mainplate
