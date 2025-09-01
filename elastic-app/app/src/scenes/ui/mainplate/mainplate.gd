extends UiBattleground
class_name Mainplate

## Tourbillon mainplate - the grid where complications are placed
## Adapts the existing battleground for Tourbillon's needs

@export var initial_grid_size: Vector2i = Vector2i(4, 4)
@export var max_expansions: int = 4

var current_grid_size: Vector2i
var expansions_used: int = 0
var complication_slots: Dictionary = {}  # Vector2i -> ComplicationSlot

signal complication_placed(slot: ComplicationSlot, card: Complication)
signal complication_replaced(old_card: Complication, new_card: Complication, slot: ComplicationSlot)
signal mainplate_expanded(new_size: Vector2i)

func _ready() -> void:
	# Don't call super._ready() to avoid default battleground setup
	GlobalSignals.ui_started_game.connect(__on_start_game_tourbillon)
	current_grid_size = initial_grid_size

func __on_start_game_tourbillon() -> void:
	set_entity_data(BattlegroundEntity.BattlegroundEntityBuilder.new().build())
	_setup_mainplate_grid()

## Setup the initial mainplate grid
func _setup_mainplate_grid() -> void:
	# Clear any existing slots
	for child in %SlotGridContainer.get_children():
		child.queue_free()
	complication_slots.clear()
	
	# Configure grid container
	%SlotGridContainer.columns = current_grid_size.x
	
	# Create slots for initial grid
	for y in range(current_grid_size.y):
		for x in range(current_grid_size.x):
			var slot = _create_complication_slot(Vector2i(x, y))
			%SlotGridContainer.add_child(slot)
			complication_slots[Vector2i(x, y)] = slot

## Create a single complication slot
func _create_complication_slot(position: Vector2i) -> ComplicationSlot:
	var slot_scene = preload("res://src/scenes/ui/entities/mainplate/complication_slot.tscn")
	var slot: ComplicationSlot = slot_scene.instantiate()
	slot.grid_position = position
	slot.production_fired.connect(_on_slot_production_fired)
	return slot

## Get all complications in Escapement Order (top-to-bottom, left-to-right)
func get_complications_in_escapement_order() -> Array[ComplicationSlot]:
	var positions = complication_slots.keys()
	
	# Sort positions by Escapement Order
	positions.sort_custom(_escapement_compare)
	
	var ordered_slots: Array[ComplicationSlot] = []
	for pos in positions:
		var slot = complication_slots[pos]
		if slot and slot.__button_entity and slot.__button_entity.card:
			ordered_slots.append(slot)
	
	return ordered_slots

## Compare function for Escapement Order
func _escapement_compare(a: Vector2i, b: Vector2i) -> bool:
	# First compare rows (y), then columns (x)
	if a.y != b.y:
		return a.y < b.y  # Top rows first
	return a.x < b.x  # Left columns first

## Place a complication on the mainplate
func place_complication(card: Complication, position: Vector2i) -> bool:
	if not complication_slots.has(position):
		push_error("Invalid mainplate position: " + str(position))
		return false
	
	var slot: ComplicationSlot = complication_slots[position]
	
	# Handle replacement if slot is occupied
	if slot.__button_entity and slot.__button_entity.card:
		var old_card = slot.__button_entity.card as Complication
		complication_replaced.emit(old_card, card, slot)
		
		# Handle Overbuild keyword
		if card.is_overbuild():
			# Inherit timer progress from replaced complication
			var old_progress = slot.current_beats
			slot.setup_from_card(card)
			slot.current_beats = old_progress
		else:
			slot.setup_from_card(card)
	else:
		slot.setup_from_card(card)
		complication_placed.emit(slot, card)
	
	# Trigger slot's card placement logic
	GlobalSignals.core_card_slotted.emit(slot.__button_entity.instance_id)
	
	return true

## Expand the mainplate (between combats or via effects)
func expand_mainplate(expansion_type: String = "row") -> bool:
	if expansions_used >= max_expansions:
		return false
	
	var new_size = current_grid_size
	
	match expansion_type:
		"row":
			new_size.y += 1
		"column":
			new_size.x += 1
		"both":
			new_size.x += 1
			new_size.y += 1
		_:
			push_error("Invalid expansion type: " + expansion_type)
			return false
	
	# Add new slots
	_expand_to_size(new_size)
	current_grid_size = new_size
	expansions_used += 1
	
	mainplate_expanded.emit(new_size)
	return true

## Internal expansion logic
func _expand_to_size(new_size: Vector2i) -> void:
	# Reconfigure grid container
	%SlotGridContainer.columns = new_size.x
	
	# Add new slots only for new positions
	for y in range(new_size.y):
		for x in range(new_size.x):
			var pos = Vector2i(x, y)
			if not complication_slots.has(pos):
				var slot = _create_complication_slot(pos)
				%SlotGridContainer.add_child(slot)
				complication_slots[pos] = slot

## Get slot at specific position
func get_slot_at(position: Vector2i) -> ComplicationSlot:
	return complication_slots.get(position, null)

## Check if position is valid
func is_valid_position(position: Vector2i) -> bool:
	return position.x >= 0 and position.x < current_grid_size.x and \
		   position.y >= 0 and position.y < current_grid_size.y

## Get all occupied slots
func get_occupied_slots() -> Array[ComplicationSlot]:
	var occupied: Array[ComplicationSlot] = []
	for slot in complication_slots.values():
		if slot.__button_entity and slot.__button_entity.card:
			occupied.append(slot)
	return occupied

## Count complications with specific tag
func count_complications_with_tag(tag: String) -> int:
	var count = 0
	for slot in get_occupied_slots():
		var card = slot.__button_entity.card as Complication
		if card and card.has_tag(tag):
			count += 1
	return count

## Reset mainplate for new combat
func reset() -> void:
	for slot in complication_slots.values():
		slot.reset()
	
	# Reset to initial size if expanded
	if current_grid_size != initial_grid_size:
		current_grid_size = initial_grid_size
		expansions_used = 0
		_setup_mainplate_grid()

## Handle production fired from a slot
func _on_slot_production_fired(slot: ComplicationSlot) -> void:
	# Could add visual effects or sound here
	pass