extends Node
class_name Mainplate

## The mainplate is the grid where gears (cards) are placed
## Adapts the existing battleground system for Tourbillon's time-based mechanics

var battleground: BattlegroundEntity
var grid_width: int = 5
var grid_height: int = 3

func _ready() -> void:
	# Get or create battleground entity
	if GlobalGameManager.has("battleground"):
		battleground = GlobalGameManager.get("battleground")
	else:
		_create_battleground()
	
	# Register as mainplate in GlobalGameManager
	GlobalGameManager.set("mainplate", self)

func _create_battleground() -> void:
	# This would normally be created by the game setup
	# For now, just log that it's missing
	push_warning("Battleground not found in GlobalGameManager")

## Get all gears in Escapement Order (top-to-bottom, left-to-right)
func get_gears_in_order() -> Array[EngineSlot]:
	var gears: Array[EngineSlot] = []
	
	if not battleground:
		return gears
	
	# Process rows from top to bottom
	for y in range(grid_height):
		# Process columns from left to right
		for x in range(grid_width):
			var slot = _get_slot_at_position(x, y)
			if slot and slot.__button_entity and slot.__button_entity.card:
				gears.append(slot)
	
	return gears

## Get a specific slot at grid position
func _get_slot_at_position(x: int, y: int) -> EngineSlot:
	if not battleground:
		return null
	
	# Calculate slot index from grid position
	var index = y * grid_width + x
	
	var slots = get_all_engine_slots()
	if index < slots.size():
		return slots[index]
	
	return null

## Get all engine slots
func get_all_engine_slots() -> Array[EngineSlot]:
	var slots: Array[EngineSlot] = []
	
	if not battleground:
		return slots
	
	# Get slots from battleground UI
	# This assumes the battleground has a method or property to access slots
	# We'll need to check the actual battleground implementation
	
	# For now, return empty array
	# This will be implemented based on actual battleground structure
	push_warning("get_all_engine_slots not fully implemented - need battleground structure")
	
	return slots

## Place a gear (card) at a specific position
func place_gear(card: Card, x: int, y: int) -> bool:
	var slot = _get_slot_at_position(x, y)
	if not slot:
		return false
	
	# Check if slot is empty or can be overbuilt
	if slot.__button_entity.card and not card.keywords.has("OVERBUILD"):
		return false
	
	# Handle overbuild mechanics
	if card.keywords.has("OVERBUILD") and slot.__button_entity.card:
		var old_card = slot.__button_entity.card
		
		# Process on_replace_effect of old card
		if not old_card.on_replace_effect.is_empty():
			TourbillonEffectProcessor.process_effect(old_card.on_replace_effect, slot, null)
		
		# Transfer timer progress if applicable
		if slot.has_method("get_progress_beats"):
			var progress = slot.get_progress_beats()
			# This will be applied when the new card is set up
			card.starting_progress = progress
	
	# Place the card
	slot.__button_entity.card = card
	GlobalSignals.signal_core_card_slotted(slot.__button_entity.instance_id)
	
	return true

## Remove a gear from a position
func remove_gear(x: int, y: int) -> Card:
	var slot = _get_slot_at_position(x, y)
	if not slot or not slot.__button_entity.card:
		return null
	
	var card = slot.__button_entity.card
	
	# Process on_destroy_effect if it exists
	if not card.on_destroy_effect.is_empty():
		TourbillonEffectProcessor.process_effect(card.on_destroy_effect, slot, null)
	
	# Remove the card
	slot.__button_entity.card = null
	GlobalSignals.signal_core_card_unslotted(slot.__button_entity.instance_id)
	
	return card

## Get adjacent slots to a given slot
func get_adjacent_slots(slot: EngineSlot) -> Array[EngineSlot]:
	var adjacent: Array[EngineSlot] = []
	
	# Find the position of this slot
	var slot_position = _find_slot_position(slot)
	if slot_position == Vector2i(-1, -1):
		return adjacent
	
	var x = slot_position.x
	var y = slot_position.y
	
	# Check all four adjacent positions
	var positions = [
		Vector2i(x - 1, y),  # Left
		Vector2i(x + 1, y),  # Right
		Vector2i(x, y - 1),  # Up
		Vector2i(x, y + 1)   # Down
	]
	
	for pos in positions:
		if pos.x >= 0 and pos.x < grid_width and pos.y >= 0 and pos.y < grid_height:
			var adj_slot = _get_slot_at_position(pos.x, pos.y)
			if adj_slot and adj_slot.__button_entity and adj_slot.__button_entity.card:
				adjacent.append(adj_slot)
	
	return adjacent

## Find the grid position of a slot
func _find_slot_position(slot: EngineSlot) -> Vector2i:
	for y in range(grid_height):
		for x in range(grid_width):
			var test_slot = _get_slot_at_position(x, y)
			if test_slot == slot:
				return Vector2i(x, y)
	
	return Vector2i(-1, -1)

## Check if a slot is isolated (no adjacent gears)
func is_slot_isolated(slot: EngineSlot) -> bool:
	return get_adjacent_slots(slot).is_empty()

## Count gears with a specific tag
func count_gears_with_tag(tag: String) -> int:
	var count = 0
	var gears = get_gears_in_order()
	
	for gear in gears:
		if gear.__button_entity and gear.__button_entity.card:
			var card = gear.__button_entity.card
			if card.tags.has(tag):
				count += 1
	
	return count

## Get all gears with a specific tag
func get_gears_with_tag(tag: String) -> Array[EngineSlot]:
	var tagged_gears: Array[EngineSlot] = []
	var gears = get_gears_in_order()
	
	for gear in gears:
		if gear.__button_entity and gear.__button_entity.card:
			var card = gear.__button_entity.card
			if card.tags.has(tag):
				tagged_gears.append(gear)
	
	return tagged_gears