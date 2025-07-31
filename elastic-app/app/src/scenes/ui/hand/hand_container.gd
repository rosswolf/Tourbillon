class_name HandContainer
extends Control

# Configuration properties
@export var spacing: float = 0.0  # Space between cards
@export var fan_arc_degrees: float = 25.0  # Arc angle for the fan effect
@export var hover_raise_amount: float = 60.0  # How much cards rise when hovered
@export var hover_scale: float = 1.5  # How much cards scale when hovered (1.5 = 150%)
@export var animation_speed: float = 0.2  # Animation duration in seconds
@export var max_cards_without_overlap: int = 1  # Max cards before they start overlapping
@export var vertical_offset: float = 15.0  # Vertical offset for the arc
@export var card_rotation_degrees: float = 10.0  # Max rotation for cards

# Internal variables
var __cards: Dictionary[String, CardUI]
var __tween_dict: Dictionary = {}  # Store tweens by card node
var __selected_card: CardUI = null  # Track currently selected/raised card

func _ready():
	# Make sure the container resizes properly
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL
	GlobalSignals.ui_selected_changed.connect(_on_selected_changed)
	# Remove the manual positioning entirely and use:
	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	anchor_top = 0.8  # Bottom 20% of screen
	anchor_left = 0.15  # 15% margin on each side
	anchor_right = 0.85
	
	
# Add a card to the hand
func add_card(card_ui: CardUI, card: Card) -> void:
	# Add the card as a child if it's not already
	# TODO: check that instance id is not already in dict
	add_child(card_ui)
	card_ui.set_card_data(card)
	
	__cards[card_ui.card_data.instance_id] = card_ui
	
	# Ensure card starts with normal scale
	card_ui.scale = Vector2.ONE
		
	# Connect to card signals if they exist
	if card_ui.has_signal("mouse_entered"):
		if not card_ui.mouse_entered.is_connected(_on_card_mouse_entered):
			card_ui.mouse_entered.connect(_on_card_mouse_entered.bind(card_ui))
	
	if card_ui.has_signal("mouse_exited"):
		if not card_ui.mouse_exited.is_connected(_on_card_mouse_exited):
			card_ui.mouse_exited.connect(_on_card_mouse_exited.bind(card_ui))
	
	# Arrange all cards in the hand
	arrange_cards()
	
	
# Remove a card from the hand
func remove_card(card_instance_id: String) -> CardUI:
	
	var card = __cards[card_instance_id]
	# Disconnect signals
	if card.has_signal("mouse_entered") and card.mouse_entered.is_connected(_on_card_mouse_entered):
		card.mouse_entered.disconnect(_on_card_mouse_entered)
		
	if card.has_signal("mouse_exited") and card.mouse_exited.is_connected(_on_card_mouse_exited):
		card.mouse_exited.disconnect(_on_card_mouse_exited)
	
	__cards.erase(card.card_data.instance_id)
	__tween_dict.erase(card)
	
	# Remove from scene if it's still a child
	if card.get_parent() == self:
		remove_child(card)
	
	# Rearrange remaining cards
	arrange_cards()
	
	return card
	
func _calculate_card_layout() -> Dictionary:
	if __cards.is_empty():
		return {}
	
	var effective_spacing = spacing
	
	# Get card width (assuming all cards are the same size)
	var card_width = 0
	if not __cards.is_empty():
		var first_card = __cards.values()[0]
		card_width = first_card.size.x
	
	# Calculate total width needed: all card widths + spacing between them
	var total_width_needed = (__cards.size() * card_width) + ((__cards.size() - 1) * spacing)
	var available_width = size.x
	
	# Only reduce spacing if we actually run out of space
	if total_width_needed > available_width:
		var available_spacing_width = available_width - (__cards.size() * card_width)
		effective_spacing = available_spacing_width / (__cards.size() - 1) if __cards.size() > 1 else spacing
		# Optional: Set a minimum spacing to prevent cards from getting too squished
		effective_spacing = max(effective_spacing, spacing * 0.3)
	
	# Calculate the total width for positioning (cards + spacing)
	var total_width = (__cards.size() * card_width) + ((__cards.size() - 1) * effective_spacing)
	
	# Center position (x-coordinate)
	var center_x = size.x / 2.0
	
	# For odd number of cards, center the middle card
	var middle_card_index = (__cards.size() - 1) / 2.0
	var middle_card_offset = middle_card_index * (card_width + effective_spacing)
	var start_x = center_x - middle_card_offset - (card_width / 2.0)
	
	return {
		"effective_spacing": effective_spacing,
		"card_width": card_width,
		"total_width": total_width,
		"start_x": start_x,
		"center_x": center_x
	}
func arrange_cards() -> void:
	if __cards.is_empty():
		return
	
	var layout = _calculate_card_layout()
	if layout.is_empty():
		return
	
	# Calculate total arc angle based on number of cards
	var total_angle = min(fan_arc_degrees, fan_arc_degrees * (__cards.size() / max_cards_without_overlap))
	
	# Angle between each card
	var angle_step = 0.0
	if __cards.size() > 1:
		angle_step = total_angle / (__cards.size() - 1)
	
	# Starting angle
	var start_angle = -total_angle / 2.0
	
	# Arrange each card
	var i = 0
	for key in __cards.keys():
		var card = __cards[key]
		
		# Skip if card doesn't exist
		if not is_instance_valid(card):
			continue
		
		# Calculate position (center of each card)
		var middle_index = (__cards.size() - 1) / 2.0
		var offset_from_center = (i - middle_index) * (layout.card_width + layout.effective_spacing)
		var card_x = layout.center_x + offset_from_center - (layout.card_width / 2.0)		
		
		# Calculate rotation angle (in radians for math, but we'll apply in degrees)
		var angle = start_angle + (i * angle_step)
		
		# Calculate y-position offset based on arc (higher in the middle, lower at edges)
		var normalized_position = (i / float(__cards.size() - 1)) if __cards.size() > 1 else 0.5
		var arc_factor = sin(PI * normalized_position)
		var y_offset = -arc_factor * vertical_offset
		
		# Calculate final position
		var target_pos = Vector2(card_x, y_offset)
		
		#print("Card ", i, " position: ", target_pos, " Container size: ", size)
		
		# Calculate rotation (cards at edges are rotated more)
		var rotation_factor = 2.0 * (normalized_position - 0.5)  # -1 to 1
		var target_rotation = rotation_factor * card_rotation_degrees
		
		# Increment even if we skip the selected card
		i = i + 1
		
		# If this is the currently selected card, don't rearrange it
		if card == __selected_card:
			continue
			
		# If we're hovering this card, dont rearrange it
		if GlobalSelectionManager.get_hovered() in __cards and __cards[GlobalSelectionManager.get_hovered()] == card:
			continue
		
		# Animate the card to its new position
		_animate_card_to_position(card, target_pos, target_rotation)


# Animate card to a position with rotation
func _animate_card_to_position(card: CardUI, target_pos: Vector2, target_rotation: float) -> void:
	# Cancel any existing tween
	if __tween_dict.has(card) and __tween_dict[card] != null:
		__tween_dict[card].kill()
	
	# Create a new tween
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	
	# Animate position and rotation, and reset scale to normal
	tween.tween_property(card, "position", target_pos, animation_speed)
	tween.parallel().tween_property(card, "rotation_degrees", target_rotation, animation_speed)
	tween.parallel().tween_property(card, "scale", Vector2.ONE, animation_speed)
	
	# Store the tween
	__tween_dict[card] = tween

# Handle card hover effect (raise card up)
func _on_card_mouse_entered(card: CardUI) -> void:
	# If this is already the selected card, don't do anything
	if __selected_card != null:
		return
		
	# Cancel any existing tween
	if __tween_dict.has(card) and __tween_dict[card] != null:
		__tween_dict[card].kill()
	
	# Calculate what the base position of this card should be
	var base_position = _calculate_base_position_for_card(card)
	
	# Calculate raised position based on base position, not current position
	var raised_position = base_position - Vector2(0, hover_raise_amount)
	
	# Create hover effect tween
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	
	# Animate position, scale, and rotation
	tween.tween_property(card, "position", raised_position, animation_speed * 0.7)
	tween.parallel().tween_property(card, "scale", Vector2(hover_scale, hover_scale), animation_speed * 0.7)
	tween.parallel().tween_property(card, "rotation_degrees", 0.0, animation_speed * 0.7)
	
	# Move card to front (higher z-index)
	card.z_index = 1
	
	# Store the tween
	__tween_dict[card] = tween

# Handle card hover exit (return to normal position)
func _on_card_mouse_exited(card: CardUI) -> void:
	# If this is the selected card, keep it raised
	if card == __selected_card:
		return
		
	# Reset z-index
	card.z_index = 0
	
	# Trigger a rearrangement of all cards
	arrange_cards()
	
func _on_selected_changed(card_instance_id: String):
	if card_instance_id == "":
		deselect_current_card()
	elif card_instance_id in __cards.keys():
		toggle_card_selection_on(__cards[card_instance_id])
	
# New function to toggle card selection state
func toggle_card_selection_off(card: CardUI) -> void:
	# If this card is already selected, deselect it
	if __selected_card == card:
		deselect_current_card()

# New function to toggle card selection state
func toggle_card_selection_on(card: CardUI) -> void:
	if __selected_card == card:
		return
	
	# If another card is selected, deselect it first
	if __selected_card != null:
		deselect_current_card()
	
	# Set this card as the selected one
	__selected_card = card
	
	# Make sure it's raised and scaled
	_raise_card(card)	
	
# Deselect the currently selected card
func deselect_current_card() -> void:
	if __selected_card != null:
		# Reset z-index
		__selected_card.z_index = 0
		
		# Store a reference before nullifying
		var previous_card = __selected_card
		__selected_card = null
		# Trigger a rearrangement of all cards
		arrange_cards()
		
# Helper function to raise a card (separate from hover effect)
func _raise_card(card: CardUI) -> void:
	# Cancel any existing tween
	if __tween_dict.has(card) and __tween_dict[card] != null:
		__tween_dict[card].kill()
	
	# Calculate what the base position of this card should be
	var base_position = _calculate_base_position_for_card(card)
	
	# Calculate raised position based on base position, not current position
	var raised_position = base_position - Vector2(0, hover_raise_amount)
	
	# Create selection effect tween
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	
	# Animate position and scale
	tween.tween_property(card, "position", raised_position, animation_speed * 0.7)
	#tween.parallel().tween_property(card, "scale", Vector2(hover_scale, hover_scale), animation_speed * 0.7)
	
	# Move card to front (higher z-index)
	card.z_index = 1
	
	# Store the tween
	__tween_dict[card] = tween

# Helper function to calculate the base position for a card (without any raise effect)
func _calculate_base_position_for_card(card: CardUI) -> Vector2:
	if __cards.is_empty():
		return Vector2.ZERO
		
	# Find index of this card
	var i = 0
	var card_index = -1
	for key in __cards.keys():
		if __cards[key] == card:
			card_index = i
			break
		i += 1
		
	if card_index == -1:
		return card.position  # Card not found in our cards dictionary
	
	var layout = _calculate_card_layout()
	if layout.is_empty():
		return Vector2.ZERO
	
	# Calculate card's x position (center of the card)
	var middle_index = (__cards.size() - 1) / 2.0
	var offset_from_center = (i - middle_index) * (layout.card_width + layout.effective_spacing)
	var card_x = layout.center_x + offset_from_center - (layout.card_width / 2.0)	
	
	# Calculate normalized position for arc
	var normalized_position = (card_index / float(__cards.size() - 1)) if __cards.size() > 1 else 0.5
	var arc_factor = sin(PI * normalized_position)
	var y_offset = -arc_factor * vertical_offset
	
	return Vector2(card_x, y_offset)

# Call this when container is resized
func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		arrange_cards()
