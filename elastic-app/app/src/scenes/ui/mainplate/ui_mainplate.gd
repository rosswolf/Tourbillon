extends UiBattleground
class_name UIMainplate

## UI representation of the Tourbillon mainplate
## Renders the core Mainplate state

@export var max_display_size: Vector2i = Vector2i(8, 8)  # Maximum display grid
@export var initial_grid_size: Vector2i = Vector2i(4, 4)  # Starting logical grid size
@export var max_expansions: int = 3  # Maximum number of grid expansions allowed

var mainplate: Mainplate  # Reference to core entity
var gear_slots: Dictionary[Vector2i, EngineSlot] = {}  # Physical position -> UI Slot mapping
var grid_mapper: GridMapper  # Maps logical to physical positions
var expansions_used: int = 0  # Track number of expansions used

signal gear_placed(slot: EngineSlot, card: Card)
signal gear_replaced(old_card: Card, new_card: Card, slot: EngineSlot)
signal mainplate_expanded(new_size: Vector2i)

var ui_orchestrator: UIBeatOrchestrator

func _ready() -> void:
	# Don't call super._ready() to avoid default battleground setup
	GlobalSignals.ui_started_game.connect(__on_start_game_tourbillon)
	# Card placement is handled through ui_execute_selected_onto_hovered and the activation system
	
	# Create the UI beat orchestrator for synchronized updates
	ui_orchestrator = UIBeatOrchestrator.new()
	ui_orchestrator.name = "UIBeatOrchestrator"
	add_child(ui_orchestrator)
	ui_orchestrator.add_to_group("ui_beat_orchestrator")

func __on_start_game_tourbillon() -> void:
	# Get the mainplate entity from GlobalGameManager
	if GlobalGameManager.mainplate:
		mainplate = GlobalGameManager.mainplate
		# Initialize GridMapper with mainplate's logical size and our display size
		grid_mapper = GridMapper.new(mainplate.grid_size, max_display_size)
		__setup_mainplate_grid()
	else:
		push_error("Mainplate not found in GlobalGameManager!")


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
	
	# Register with orchestrator for synchronized updates
	if ui_orchestrator:
		ui_orchestrator.register_slot(slot)
	
	return slot

## Update visual state of slots based on mainplate
func __update_slot_visuals() -> void:
	if not mainplate or not grid_mapper:
		return
	
	# Update all slots based on whether they map to valid logical positions
	var active_slots: Array[EngineSlot] = []
	for physical_pos in gear_slots:
		var slot: EngineSlot = gear_slots[physical_pos]
		var is_active: bool = grid_mapper.is_active_physical(physical_pos)
		if is_active:
			active_slots.append(slot)
			
	# Randomly assign bonus squares to 1/3 of active slots BEFORE setting visual state
	__assign_bonus_squares(active_slots)
	
	# Now set the visual state with bonus square styling applied
	for physical_pos in gear_slots:
		var slot: EngineSlot = gear_slots[physical_pos]
		var is_active: bool = grid_mapper.is_active_physical(physical_pos)
		__set_slot_active(slot, is_active)

## Set a slot's active state with visual feedback
func __set_slot_active(slot: EngineSlot, active: bool) -> void:
	slot.set_active(active)
	
	if active:
		# For active slots, ensure they're visible
		# Don't override modulate if it's a bonus square - preserve the yellow tint
		if not slot.is_bonus_square:
			slot.modulate = Color.WHITE
		slot.visible = true
		
		# Find the MainPanel and make it visible with a background
		var main_panel = slot.get_node_or_null("%MainPanel")
		if main_panel:
			# Create a visible background for empty slots
			var panel_stylebox = StyleBoxFlat.new()
			# Use different color for bonus squares
			if slot.is_bonus_square:
				if slot.bonus_type == "draw_two_cards":
					panel_stylebox.bg_color = Color(0.25, 0.15, 0.25, 0.7)  # Purplish background for draw 2
				else:
					panel_stylebox.bg_color = Color(0.25, 0.25, 0.15, 0.7)  # Yellowish background for draw 1
			else:
				panel_stylebox.bg_color = Color(0.2, 0.2, 0.25, 0.7)  # Dark semi-transparent background
			panel_stylebox.border_color = Color(0.0, 0.0, 0.0, 1.0)  # Black border
			panel_stylebox.set_border_width_all(2)
			panel_stylebox.set_corner_radius_all(8)
			main_panel.add_theme_stylebox_override("panel", panel_stylebox)
			
			# Keep MainPanel visible for empty slots too
			main_panel.visible = true
			
			# Show the inner PanelContainer (it contains the card info when placed)
			var inner_panel = main_panel.get_node_or_null("PanelContainer")
			if inner_panel:
				inner_panel.visible = true
		
		# Also style the button itself for better visibility
		var button_stylebox = StyleBoxFlat.new()
		# Different styling for bonus squares
		if slot.is_bonus_square:
			if slot.bonus_type == "draw_two_cards":
				button_stylebox.bg_color = Color(0.25, 0.15, 0.25, 0.5)  # Purple tint for draw 2
				button_stylebox.border_color = Color(0.8, 0.4, 0.8, 1.0)  # Purple border for draw 2
				button_stylebox.set_border_width_all(4)  # Thicker border for special square
			else:
				button_stylebox.bg_color = Color(0.2, 0.2, 0.15, 0.5)  # Yellowish tint for draw 1
				button_stylebox.border_color = Color(0.6, 0.6, 0.0, 1.0)  # Golden border for draw 1
				button_stylebox.set_border_width_all(3)
		else:
			button_stylebox.bg_color = Color(0.15, 0.15, 0.2, 0.4)  # Subtle background
			button_stylebox.border_color = Color(0.0, 0.0, 0.0, 0.8)  # Black border
			button_stylebox.set_border_width_all(2)
		button_stylebox.set_corner_radius_all(10)
		
		slot.add_theme_stylebox_override("normal", button_stylebox)
		
		# Hover state
		var hover_stylebox = button_stylebox.duplicate()
		if slot.is_bonus_square:
			if slot.bonus_type == "draw_two_cards":
				hover_stylebox.border_color = Color(1.0, 0.6, 1.0, 1.0)  # Bright purple on hover
			else:
				hover_stylebox.border_color = Color(0.8, 0.8, 0.2, 1.0)  # Bright golden on hover
		else:
			hover_stylebox.border_color = Color(0.2, 0.2, 0.2, 1.0)  # Lighter border on hover
		hover_stylebox.set_border_width_all(3)
		slot.add_theme_stylebox_override("hover", hover_stylebox)
		slot.add_theme_stylebox_override("pressed", hover_stylebox)
	else:
		# Inactive slots - make them nearly invisible
		slot.modulate = Color(0.3, 0.3, 0.3, 0.1)
		
		# Remove all style overrides for inactive slots
		slot.remove_theme_stylebox_override("normal")
		slot.remove_theme_stylebox_override("hover") 
		slot.remove_theme_stylebox_override("pressed")
		
		# Hide MainPanel for inactive slots
		var main_panel = slot.get_node_or_null("%MainPanel")
		if main_panel:
			main_panel.visible = false

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

## Remove a gear from a slot at physical position
func remove_gear_at_physical(physical_pos: Vector2i) -> Card:
	var logical_pos = grid_mapper.to_logical(physical_pos)
	if logical_pos == null:
		return null
	return remove_gear_at_logical(logical_pos)

## Remove a gear from a slot at logical position
func remove_gear_at_logical(logical_pos: Vector2i) -> Card:
	if not mainplate:
		return null
	
	# Remove from core entity
	var card: Card = mainplate.remove_card(logical_pos)
	if not card:
		return null
	
	# Update UI slot
	var physical_pos: Vector2i = grid_mapper.to_physical(logical_pos)
	if gear_slots.has(physical_pos):
		var slot: EngineSlot = gear_slots[physical_pos]
		# Signal the slot is now empty
		GlobalSignals.core_card_unslotted.emit(slot.__button_entity.instance_id)
		# Reset the slot's visual state
		assert(slot != null, "Slot must exist for reset")
		slot.reset()
	
	return card

## Check if a slot can accept a card (is active and optionally empty)
func can_accept_card_at_physical(physical_pos: Vector2i, require_empty: bool = false) -> bool:
	var logical_pos = grid_mapper.to_logical(physical_pos)
	if logical_pos == null:
		return false
	
	if not mainplate or not mainplate.is_valid_position(logical_pos):
		return false
	
	if require_empty:
		return not mainplate.has_card_at(logical_pos)
	
	return true

## Get the card at a physical position
func get_card_at_physical(physical_pos: Vector2i) -> Card:
	var logical_pos = grid_mapper.to_logical(physical_pos)
	if logical_pos == null:
		return null
	
	if not mainplate:
		return null
	
	return mainplate.get_card_at(logical_pos)

## Assign bonus squares randomly to active slots
func __assign_bonus_squares(active_slots: Array[EngineSlot]) -> void:
	if active_slots.is_empty():
		return
		
	# Calculate how many bonus squares (1/3 of active slots)
	var bonus_count: int = max(1, active_slots.size() / 3)
	
	# Shuffle the slots and pick the first N for bonuses
	var shuffled_slots = active_slots.duplicate()
	shuffled_slots.shuffle()
	
	for i in range(min(bonus_count, shuffled_slots.size())):
		var slot: EngineSlot = shuffled_slots[i]
		# First bonus square draws 2 cards, rest draw 1
		if i == 0:
			slot.set_as_bonus_square("draw_two_cards")
			print("SPECIAL bonus square (draws 2) at position: ", slot.grid_position)
		else:
			slot.set_as_bonus_square("draw_one_card")
			print("Bonus square (draws 1) at position: ", slot.grid_position)

## Reset mainplate for new combat
func reset() -> void:
	for slot in gear_slots.values():
		assert(slot != null, "All slots must exist for reset")
		slot.reset()
	
	# Reset grid mapper to initial size
	grid_mapper.reset(initial_grid_size)
	expansions_used = 0
	__update_slot_visuals()
