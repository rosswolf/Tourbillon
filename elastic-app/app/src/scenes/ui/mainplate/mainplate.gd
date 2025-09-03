extends UiBattleground
class_name Mainplate

## UI representation of the Tourbillon mainplate
## Renders the core MainplateEntity state

@export var max_display_size: Vector2i = Vector2i(8, 8)  # Maximum display grid

var mainplate_entity: MainplateEntity  # Reference to core entity
var gear_slots: Dictionary[Vector2i, EngineSlot] = {}  # Position -> UI Slot mapping

signal gear_placed(slot: EngineSlot, card: Card)
signal gear_replaced(old_card: Card, new_card: Card, slot: EngineSlot)
signal mainplate_expanded(new_size: Vector2i)

func _ready() -> void:
	# Don't call super._ready() to avoid default battleground setup
	GlobalSignals.ui_started_game.connect(__on_start_game_tourbillon)
	GlobalSignals.ui_card_played_to_slot.connect(__on_card_played_to_slot)

func __on_start_game_tourbillon() -> void:
	# Get the mainplate entity from GlobalGameManager
	if GlobalGameManager.mainplate_entity:
		mainplate_entity = GlobalGameManager.mainplate_entity
		__setup_mainplate_grid()
	else:
		push_error("MainplateEntity not found in GlobalGameManager!")

func __on_card_played_to_slot(card_id: String, slot_pos: Vector2i) -> void:
	# Validate placement against core entity
	if not mainplate_entity or not mainplate_entity.is_valid_position(slot_pos):
		push_warning("Invalid slot position: ", slot_pos)
		return
	
	var card: Card = GlobalGameManager.library.get_card(card_id)
	if card:
		mainplate_entity.place_card(card, slot_pos)
		__update_slot_visuals()

## Setup the initial mainplate grid
func __setup_mainplate_grid() -> void:
	# Clear any existing slots
	for child in %SlotGridContainer.get_children():
		child.queue_free()
	gear_slots.clear()
	
	# Configure grid container for maximum display size
	%SlotGridContainer.columns = max_display_size.x
	
	# Create ALL display slots up front
	for y in range(max_display_size.y):
		for x in range(max_display_size.x):
			var pos: Vector2i = Vector2i(x, y)
			var slot: EngineSlot = __create_gear_slot(pos)
			%SlotGridContainer.add_child(slot)
			gear_slots[pos] = slot
	
	# Update visual state based on mainplate entity
	__update_slot_visuals()

## Create a single gear slot
func __create_gear_slot(position: Vector2i) -> EngineSlot:
	var slot_scene: PackedScene = preload("res://src/scenes/ui/entities/engine/ui_engine_slot.tscn")
	var slot: EngineSlot = slot_scene.instantiate()
	slot.set_grid_position(position)
	slot.set_active(false)  # Start inactive
	return slot

## Update visual state of slots based on mainplate entity
func __update_slot_visuals() -> void:
	if not mainplate_entity:
		return
	
	# Update all slots based on whether they're within the valid grid
	for pos in gear_slots:
		var slot: EngineSlot = gear_slots[pos]
		var is_active: bool = mainplate_entity.is_valid_position(pos)
		__set_slot_active(slot, is_active)

## Set a slot's active state with visual feedback
func __set_slot_active(slot: EngineSlot, active: bool) -> void:
	slot.set_active(active)
	
	if active:
		# Reset modulation for active slots
		slot.modulate = Color.WHITE
		slot.modulate.a = 1.0
		
		# Add strong white outline to the button itself
		var stylebox = StyleBoxFlat.new()
		stylebox.bg_color = Color(0.1, 0.1, 0.15, 0.8)  # Dark background for contrast
		stylebox.border_color = Color(1.0, 1.0, 1.0, 1.0)  # Strong white border
		stylebox.set_border_width_all(3)  # Thick border for visibility
		stylebox.set_corner_radius_all(5)
		slot.add_theme_stylebox_override("normal", stylebox)
		slot.add_theme_stylebox_override("hover", stylebox)
		slot.add_theme_stylebox_override("pressed", stylebox)
		slot.add_theme_stylebox_override("disabled", stylebox)
	else:
		# Dim inactive slots
		slot.modulate = Color(0.3, 0.3, 0.3, 0.3)
		
		# Remove border from inactive slots
		var stylebox = StyleBoxFlat.new()
		stylebox.bg_color = Color(0.05, 0.05, 0.05, 0.2)  # Very dark and transparent
		stylebox.border_color = Color(0.2, 0.2, 0.2, 0.2)  # Very dim border
		stylebox.set_border_width_all(1)
		stylebox.set_corner_radius_all(5)
		slot.add_theme_stylebox_override("normal", stylebox)
		slot.add_theme_stylebox_override("hover", stylebox)
		slot.add_theme_stylebox_override("pressed", stylebox)
		slot.add_theme_stylebox_override("disabled", stylebox)

## Get all gears in Escapement Order (top-to-bottom, left-to-right)
func get_gears_in_escapement_order() -> Array[EngineSlot]:
	var active_positions: Array[Vector2i] = grid_mapper.get_active_physical_positions()
	
	# Sort positions by Escapement Order
	active_positions.sort_custom(__escapement_compare)
	
	var ordered_slots: Array[EngineSlot] = []
	for physical_pos in active_positions:
		if gear_slots.has(physical_pos):
			var slot: EngineSlot = gear_slots[physical_pos]
			if slot and slot.__button_entity and slot.__button_entity.card:
				ordered_slots.append(slot)
	
	return ordered_slots

## Compare function for Escapement Order
func __escapement_compare(a: Vector2i, b: Vector2i) -> bool:
	# First compare rows (y), then columns (x)
	if a.y != b.y:
		return a.y < b.y  # Top rows first
	return a.x < b.x  # Left columns first

## Place a gear (card) on the mainplate using logical position
func place_gear(card: Card, logical_position: Vector2i) -> bool:
	# First check if the logical position is valid
	if not grid_mapper.is_valid_logical(logical_position):
		push_error("Position outside active grid: " + str(logical_position))
		return false
	
	# Convert logical to physical position
	var physical_pos: Vector2i = grid_mapper.to_physical(logical_position)
	
	if not gear_slots.has(physical_pos):
		push_error("Invalid mainplate position: " + str(logical_position))
		return false
	
	var slot: EngineSlot = gear_slots[physical_pos]
	
	# Double-check the slot is active
	if not slot.get_meta("is_active", false):
		push_error("Cannot place card in inactive slot: " + str(logical_position))
		return false
	
	# Handle replacement if slot is occupied
	if slot.__button_entity and slot.__button_entity.card:
		var old_card: Card = slot.__button_entity.card
		gear_replaced.emit(old_card, card, slot)
		
		# Handle Overbuild keyword if present
		if card.get_meta("is_overbuild", false):
			# Inherit timer progress from replaced gear
			var old_progress: int = slot.get_meta("current_beats", 0) as int
			slot.set_meta("current_beats", old_progress)
	else:
		gear_placed.emit(slot, card)
	
	# Trigger slot's card placement logic
	GlobalSignals.core_card_slotted.emit(slot.__button_entity.instance_id)
	
	return true

## Expand the mainplate (between combats or via effects)
func expand_mainplate(expansion_type: String = "row") -> bool:
	if expansions_used >= max_expansions:
		return false
	
	# Try to expand using the grid mapper
	if not grid_mapper.expand(expansion_type):
		push_warning("Cannot expand grid: would exceed physical bounds")
		return false
	
	# Update visual state
	__update_slot_visuals()
	expansions_used += 1
	
	mainplate_expanded.emit(grid_mapper.get_logical_size())
	return true

## Check if logical position is valid
func is_valid_position(logical_position: Vector2i) -> bool:
	return grid_mapper.is_valid_logical(logical_position)

## Get slot at specific position
func get_slot_at(position: Vector2i) -> EngineSlot:
	return gear_slots.get(position, null)

## Get all occupied slots (only active ones)
func get_occupied_slots() -> Array[EngineSlot]:
	var occupied: Array[EngineSlot] = []
	var active_positions: Array[Vector2i] = grid_mapper.get_active_physical_positions()
	
	for physical_pos in active_positions:
		if gear_slots.has(physical_pos):
			var slot: EngineSlot = gear_slots[physical_pos]
			if slot.__button_entity and slot.__button_entity.card:
				occupied.append(slot)
	return occupied

## Count gears with specific tag
func count_gears_with_tag(tag: String) -> int:
	var count: int = 0
	for slot in get_occupied_slots():
		var card: Card = slot.__button_entity.card
		if card and card.has_meta("tags"):
			var tags: Array = card.get_meta("tags", []) as Array
			if tag in tags:
				count += 1
	return count

## Reset mainplate for new combat
func reset() -> void:
	for slot in gear_slots.values():
		if slot.has_method("reset"):
			slot.reset()
	
	# Reset grid mapper to initial size
	grid_mapper.reset(initial_grid_size)
	expansions_used = 0
	__update_slot_visuals()

