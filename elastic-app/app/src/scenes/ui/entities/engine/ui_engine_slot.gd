extends UiTextureButton
class_name EngineSlot

@onready var top_container: HBoxContainer = $MarginContainer/MainPanel/VBoxContainer/TopBoxContainer
@onready var bottom_container: HBoxContainer = $MarginContainer/MainPanel/VBoxContainer/BottomBoxContainer


# Pure UI state - no game logic
var grid_position: Vector2i = Vector2i(-1, -1)  # Position in the grid
var is_active_slot: bool = false  # Whether this slot is within valid grid
var is_bonus_square: bool = false  # Whether this slot gives a bonus when played on
var bonus_type: String = ""  # Type of bonus (e.g., "draw_card")

var card_preview: CardUI

var CARD_UI: PackedScene = preload("res://src/scenes/ui/hand/card_ui.tscn")

func _ready() -> void:
	super._ready()
	
	create_button_entity(self, false)
	
	self.pressed.connect(__on_refresh_slot_manually)
	
	# Hide nodes we don't need yet
	await get_tree().process_frame
	top_container.visible = true
	bottom_container.visible = false
	
	# Card slotting is now handled via update_card_display() called by UIMainplate
	GlobalSignals.core_card_unslotted.connect(__on_card_unslotted)
	GlobalSignals.core_gear_process_beat.connect(__on_gear_process_beat)
	
	# Initialize progress bar
	%ProgressBar.value = 0
	%ProgressBar.visible = true
	
func create_card_ui() -> void:	
	if card_preview:  # Already exists, don't create again
		return
		
	card_preview = CARD_UI.instantiate()
	card_preview.set_card_data(__button_entity.card)
	
	card_preview.position = Vector2(-170, 0)
	card_preview.visible = true  # Make sure it's visible
	# Make the card preview less transparent for better visibility
	card_preview.modulate = Color(1.0, 1.0, 1.0, 0.95)  # Almost fully opaque
	# Ensure preview is always on top
	card_preview.z_index = 100
	add_child(card_preview)
	# Start invisible and scale up
	var tween = create_tween()
	tween.tween_property(card_preview, "scale", Vector2(1.25, 1.25), 0.17)

func destroy_card_ui() -> void:	
	if not card_preview:  # Nothing to destroy
		return
		
	var tween = create_tween()
	tween.tween_property(card_preview, "scale", Vector2(.75,.75), 0.15)
	tween.tween_callback(card_preview.queue_free)
	card_preview = null
	
# Card slotting now handled via update_card_display() method called by UIMainplate
func __on_card_unslotted(target_slot_id: String) -> void:
	if target_slot_id == __button_entity.instance_id:
		var name_node = get_node_or_null("%Name")
		if name_node:
			name_node.text = ""
		
		var main_panel = get_node_or_null("%MainPanel")
		if main_panel:
			main_panel.visible = false
		
		var progress_bar = get_node_or_null("%ProgressBar")
		if progress_bar:
			progress_bar.value = 0
		
		if card_preview:
			destroy_card_ui()

func _process(delta: float) -> void:
	# Progress bar is updated in __update_progress_display() instead
	pass

# Cooldown system removed - using beat-based production instead

func pct(numerator: float, denominator: float) -> float:
	if denominator <= 0.001:
		return 0.0
	else:
		return 100.0 * numerator / denominator	
	

							
# Activation states removed - production state handled by is_ready

func __on_refresh_slot_manually() -> void:
	# Just emit signal for core to handle
	if __button_entity.card != null:
		GlobalSignals.signal_core_slot_activated(__button_entity.card.instance_id)
		if card_preview:
			card_preview.refresh()
		
func _on_mouse_entered() -> void:
	# Only register as hovered if this slot is active
	if is_active_slot:
		super._on_mouse_entered()
		if __button_entity.get_card_instance_id() != "":
			create_card_ui()
		
func _on_mouse_exited() -> void:
	# Only clear hover if we were actually hovered
	if is_active_slot:
		super._on_mouse_exited()
	if card_preview:
		destroy_card_ui()

## Handle beat processing signal from core - only visual updates
func __on_gear_process_beat(card_instance_id: String, context: BeatContext) -> void:
	# Only update visuals if this is our card
	if not __button_entity or not __button_entity.card:
		return
		
	if __button_entity.card.instance_id != card_instance_id:
		return
		
	# Just update visual progress - core handles logic
	__update_progress_display()





## Update the progress bar display based on external data
func update_progress_display(percent: float, is_ready: bool = false) -> void:
	if not %ProgressBar:
		push_error("[EngineSlot] No ProgressBar node found!")
		return
	
	# Skip progress updates for instant activation cards
	if __button_entity and __button_entity.card and __button_entity.card.production_interval == 0:
		return
	
	# Don't update if we're in the middle of activation animation
	if %ProgressBar.has_meta("activating") and %ProgressBar.get_meta("activating"):
		return
		
	%ProgressBar.visible = true
	
	# Make progress bar more visible
	%ProgressBar.self_modulate = Color.WHITE
	%ProgressBar.z_index = 10
	
	# Kill any existing update tweens to prevent conflicts
	if %ProgressBar.has_meta("update_tween"):
		var old_tween = %ProgressBar.get_meta("update_tween")
		if old_tween and old_tween.is_valid():
			old_tween.kill()
	
	# Animate smoothly
	var tween = create_tween()
	%ProgressBar.set_meta("update_tween", tween)
	tween.tween_property(%ProgressBar, "value", percent, 0.2)
	
	# Color code based on state
	if is_ready:
		%ProgressBar.modulate = Color(1.0, 0.8, 0.0, 1.0)  # Orange when ready
	else:
		%ProgressBar.modulate = Color(1.0, 1.0, 0.0, 1.0)  # Yellow when charging

func __update_progress_display() -> void:
	# Placeholder for compatibility
	pass

## Show activation feedback - full bar that holds then resets
func show_activation_feedback() -> void:
	if not %ProgressBar or not __button_entity or not __button_entity.card:
		return
	
	# Skip for instant activation cards (they have their own animation)
	if __button_entity.card.production_interval == 0:
		return
	
	# Mark that we're animating activation
	%ProgressBar.set_meta("activating", true)
	
	# Kill any existing tweens on the progress bar to prevent conflicts
	if %ProgressBar.has_meta("tween"):
		var old_tween = %ProgressBar.get_meta("tween")
		if old_tween and old_tween.is_valid():
			old_tween.kill()
	if %ProgressBar.has_meta("update_tween"):
		var old_tween = %ProgressBar.get_meta("update_tween")
		if old_tween and old_tween.is_valid():
			old_tween.kill()
	
	%ProgressBar.visible = true
	%ProgressBar.value = 100
	%ProgressBar.modulate = Color(1.0, 1.0, 1.0, 1.0)  # White/bright for activation
	
	# Create a tween sequence: hold full, then reset to empty
	var tween = create_tween()
	%ProgressBar.set_meta("tween", tween)
	tween.tween_interval(1.0)  # Hold at full for 1 second
	tween.tween_property(%ProgressBar, "value", 0, 0.3)  # Reset to 0 over 0.3 seconds
	tween.tween_property(%ProgressBar, "modulate", Color(1.0, 1.0, 0.0, 1.0), 0.1)  # Back to yellow
	tween.tween_callback(func(): %ProgressBar.set_meta("activating", false))  # Clear activation flag

## Reset visual state
func reset() -> void:
	var progress_bar = get_node_or_null("%ProgressBar")
	if progress_bar:
		progress_bar.value = 0
		progress_bar.visible = false
	
	modulate = Color.WHITE
	
	var name_node = get_node_or_null("%Name")
	if name_node:
		name_node.text = ""
	
	var main_panel = get_node_or_null("%MainPanel")
	if main_panel:
		main_panel.visible = false

## Set the grid position for this slot
func set_grid_position(pos: Vector2i) -> void:
	grid_position = pos

## Update the card display when a card is placed or replaced
func update_card_display(card: Card) -> void:
	if not card:
		# Clear the display
		var name_node = get_node_or_null("%Name")
		if name_node:
			name_node.text = ""
		
		var main_panel = get_node_or_null("%MainPanel")
		if main_panel:
			main_panel.visible = false
		
		%ProgressBar.value = 0
		%ProgressBar.visible = false
		return
	
	# Update the display with card info
	var name_node = get_node_or_null("%Name")
	if name_node:
		name_node.text = card.display_name
	
	var main_panel = get_node_or_null("%MainPanel")
	if main_panel:
		main_panel.visible = true
		
		var inner_panel = main_panel.get_node_or_null("PanelContainer")
		if inner_panel:
			inner_panel.visible = true
			inner_panel.modulate = Color(1.0, 1.0, 1.0, 1.0)  # Fully opaque
	
	# Handle progress bar for instant vs timed cards
	if card.production_interval == 0:
		# Instant activation - show full progress briefly
		%ProgressBar.value = 100
		%ProgressBar.visible = true
		%ProgressBar.modulate = Color(1.0, 1.0, 1.0, 1.0)  # White for instant
		
		# Animate fade out
		var tween = create_tween()
		tween.tween_interval(0.3)
		tween.tween_property(%ProgressBar, "modulate:a", 0.0, 0.3)
		tween.tween_callback(func(): %ProgressBar.visible = false; %ProgressBar.modulate.a = 1.0)
	else:
		# Normal progress starting from 0
		%ProgressBar.value = 0
		%ProgressBar.visible = true
		%ProgressBar.modulate = Color(1.0, 1.0, 0.0, 1.0)  # Yellow for charging

## Set whether this slot is active (can accept cards)
func set_active(active: bool) -> void:
	is_active_slot = active
	# Update visual appearance based on active state
	if active:
		mouse_filter = Control.MOUSE_FILTER_STOP
		disabled = false
	else:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		disabled = true

## Check if this slot can accept a card
func can_accept_card() -> bool:
	return is_active_slot

## Set this slot as a bonus square
func set_as_bonus_square(type: String = "draw_one_card") -> void:
	is_bonus_square = true
	bonus_type = type
	
	# Add visual indicator for bonus square
	if type == "draw_one_card":
		# Regular bonus - yellow tint
		modulate = Color(1.2, 1.2, 0.8)  # Yellow tint for draw 1
	elif type == "draw_two_cards":
		# Special bonus - purple/magenta tint for draw 2
		modulate = Color(1.3, 0.9, 1.3)  # Purple tint for draw 2
		
	# Add a visual marker - could be a label or icon
	# For now, we'll rely on the border and background color differences
	# set in UIMainplate's __set_slot_active method
