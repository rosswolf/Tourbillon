extends Entity
class_name Mainplate

## Core entity representing the Tourbillon mainplate (gear grid)
## Manages the logical grid state and slot positions

## Inner class to track card state
class CardState:
	var current_beats: int = 0
	var is_ready: bool = false
	var card_ref: Card
	
	func _init(card: Card):
		card_ref = card
		current_beats = card.starting_progress if card.has_meta("starting_progress") else 0

static func _get_type_string():
	return "Mainplate"

func _get_type() -> Entity.EntityType:
	return Entity.EntityType.MAINPLATE

var grid_size: Vector2i = Vector2i(4, 4)  # Current active grid size
var max_grid_size: Vector2i = Vector2i(8, 8)  # Maximum possible size
var slots: Dictionary = {}  # Position -> Card mapping
var card_states: Dictionary = {}  # Card instance_id -> CardState mapping
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

## Place a card at position
func place_card(card: Card, pos: Vector2i) -> bool:
	if not is_valid_position(pos):
		return false
	
	# Handle replacement if needed
	if has_card_at(pos):
		var old_card = slots[pos]
		# Transfer state from old card if Overbuild
		if card.tags.has("Overbuild") and card_states.has(old_card.instance_id):
			var old_state = card_states[old_card.instance_id]
			card_states[card.instance_id] = old_state
			card_states.erase(old_card.instance_id)
		else:
			# Initialize new card state
			card_states[card.instance_id] = CardState.new(card)
		GlobalSignals.signal_core_card_replaced(old_card.instance_id, card.instance_id)
	else:
		# Initialize card state for new placement
		card_states[card.instance_id] = CardState.new(card)
	
	slots[pos] = card
	return true

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
				var new_slots = {}
				for pos in slots:
					new_slots[pos + Vector2i(1, 0)] = slots[pos]
				slots = new_slots
				grid_size.x += 1
				expansions_used += 1
				return true
		"up":
			if grid_size.y < max_grid_size.y:
				# Shift all existing cards down
				var new_slots = {}
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
	var count = 0
	for card in get_cards_in_order():
		if card.tags.has(tag):
			count += 1
	return count

## Get adjacent positions to a given position
func get_adjacent_positions(pos: Vector2i) -> Array[Vector2i]:
	var adjacent: Array[Vector2i] = []
	
	var offsets = [
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
	
	# Consume forces
	if GlobalGameManager.hero and not card.force_consumption.is_empty():
		if not GlobalGameManager.hero.consume_forces(card.force_consumption):
			return  # Can't consume, stay ready
	
	# Produce forces
	if GlobalGameManager.hero and not card.force_production.is_empty():
		GlobalGameManager.hero.add_forces(card.force_production)
	
	# Process effect
	if not card.on_fire_effect.is_empty():
		TourbillonEffectProcessor.process_effect(card.on_fire_effect, self, null)
	
	# Signal activation for stats/UI
	GlobalSignals.signal_core_slot_activated(card.instance_id)
	
	# Reset timer
	state.current_beats = 0

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
		var mainplate = Mainplate.new()
		super.build_entity(mainplate)
		mainplate.grid_size = __grid_size
		mainplate.max_grid_size = __max_grid_size
		return mainplate
