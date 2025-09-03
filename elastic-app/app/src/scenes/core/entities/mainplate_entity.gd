extends Entity
class_name MainplateEntity

## Core entity representing the Tourbillon mainplate (gear grid)
## Manages the logical grid state and slot positions

static func _get_type_string():
	return "MainplateEntity"

func _get_type() -> Entity.EntityType:
	return Entity.EntityType.MAINPLATE

var grid_size: Vector2i = Vector2i(4, 4)  # Current active grid size
var max_grid_size: Vector2i = Vector2i(8, 8)  # Maximum possible size
var slots: Dictionary = {}  # Position -> Card mapping
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
		GlobalSignals.signal_core_card_replaced(old_card.instance_id, card.instance_id)
	
	slots[pos] = card
	return true

## Remove card from position
func remove_card(pos: Vector2i) -> Card:
	if not slots.has(pos):
		return null
	
	var card = slots[pos]
	slots.erase(pos)
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
	
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var pos = Vector2i(x, y)
			if has_card_at(pos):
				cards.append(get_card_at(pos))
	
	return cards

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

class MainplateEntityBuilder extends Entity.EntityBuilder:
	var __grid_size: Vector2i = Vector2i(4, 4)
	var __max_grid_size: Vector2i = Vector2i(8, 8)
	
	func with_grid_size(size: Vector2i) -> MainplateEntityBuilder:
		__grid_size = size
		return self
	
	func with_max_grid_size(size: Vector2i) -> MainplateEntityBuilder:
		__max_grid_size = size
		return self
	
	func build() -> MainplateEntity:
		var mainplate = MainplateEntity.new()
		super.build_entity(mainplate)
		mainplate.grid_size = __grid_size
		mainplate.max_grid_size = __max_grid_size
		return mainplate