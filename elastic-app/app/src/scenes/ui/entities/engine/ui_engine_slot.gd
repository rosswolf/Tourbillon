extends UiTextureButton
class_name EngineSlot

@onready var top_container: HBoxContainer = $MarginContainer/MainPanel/VBoxContainer/TopBoxContainer
@onready var bottom_container: HBoxContainer = $MarginContainer/MainPanel/VBoxContainer/BottomBoxContainer


# Tourbillon beat-based timing
var production_interval_beats: int = 30  # Default 3 ticks
var current_beats: int = 0
var is_ready: bool = false
var grid_position: Vector2i = Vector2i(-1, -1)  # Position in the grid
var is_active_slot: bool = false  # Whether this slot is within valid grid
var is_bonus_square: bool = false  # Whether this slot gives a bonus when played on
var bonus_type: String = ""  # Type of bonus (e.g., "draw_card")

var card_preview: CardUI

var CARD_UI = preload("res://src/scenes/ui/hand/card_ui.tscn")

func _ready() -> void:
	super._ready()
	
	create_button_entity(self, false)
	
	self.pressed.connect(__on_refresh_slot_manually)
	
	# Hide nodes we don't need yet
	await get_tree().process_frame
	top_container.visible = true
	bottom_container.visible = false
	
	GlobalSignals.core_card_slotted.connect(__on_card_slotted)
	GlobalSignals.core_card_unslotted.connect(__on_card_unslotted)
	GlobalSignals.core_gear_process_beat.connect(__on_gear_process_beat)
	
	# Initialize progress bar
	%ProgressBar.value = 0
	%ProgressBar.visible = true
	
func create_card_ui():	
	if card_preview:  # Already exists, don't create again
		return
		
	card_preview = CARD_UI.instantiate()
	card_preview.set_card_data(__button_entity.card)
	
	card_preview.position = Vector2(-170, 0)
	card_preview.visible = true  # Make sure it's visible
	# Make the card preview less transparent for better visibility
	card_preview.modulate = Color(1.0, 1.0, 1.0, 0.95)  # Almost fully opaque
	add_child(card_preview)
	# Start invisible and scale up
	var tween = create_tween()
	tween.tween_property(card_preview, "scale", Vector2(1.25, 1.25), 0.17)

func destroy_card_ui():	
	if not card_preview:  # Nothing to destroy
		return
		
	var tween = create_tween()
	tween.tween_property(card_preview, "scale", Vector2(.75,.75), 0.15)
	tween.tween_callback(card_preview.queue_free)
	card_preview = null
	
func __on_card_slotted(target_slot_id: String):
	if target_slot_id == __button_entity.instance_id:
		# Don't create card UI here - only on hover
		if __button_entity.card:
			print("[EngineSlot] Card slotted: ", __button_entity.card.display_name, " at position ", grid_position)
			%Name.text = __button_entity.card.display_name
			%MainPanel.visible = true
			# Make sure inner panel is visible too
			var inner_panel = %MainPanel.get_node_or_null("PanelContainer")
			if inner_panel:
				inner_panel.visible = true
				# Make the panel more opaque when a card is placed
				inner_panel.modulate = Color(1.0, 1.0, 1.0, 1.0)  # Fully opaque
			# Setup the card's production timing
			setup_from_card(__button_entity.card)
			
			# Trigger bonus effect if this is a bonus square
			if is_bonus_square and bonus_type != "":
				__trigger_bonus_effect()
		else:
			push_warning("Card slotted signal received but no card on button entity!")
	
func __on_card_unslotted(target_slot_id: String):
	if target_slot_id == __button_entity.instance_id:
		%Name.text = ""
		%MainPanel.visible = false
		%ProgressBar.value = 0
		current_beats = 0
		is_ready = false
		if card_preview:
			destroy_card_ui()

func _process(delta):
	# Progress bar is updated in __update_progress_display() instead
	pass

# Cooldown system removed - using beat-based production instead

func pct(numerator: float, denominator: float):
	if denominator <= 0.001:
		return 0.0
	else:
		return 100.0 * numerator / denominator	
	

							
# Activation states removed - production state handled by is_ready

func __on_refresh_slot_manually() -> void:
	if __button_entity.card != null:
		# Manual activation fires the production immediately
		__fire_production()
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

## Handle beat processing signal from core
func __on_gear_process_beat(card_instance_id: String, context: BeatContext) -> void:
	# Only process if this beat is for our card
	if not __button_entity or not __button_entity.card:
		return
		
	if __button_entity.card.instance_id != card_instance_id:
		return
		
	# Check if we should fire (orchestrator will handle visual updates)
	process_beat_logic(context)

## Process beat logic without visual updates (orchestrator handles visuals)
func process_beat_logic(context: BeatContext) -> void:
	if not __button_entity or not __button_entity.card:
		return
	
	# Skip processing for non-producing cards (production_interval == -1)
	if production_interval_beats <= 0:
		return
	
	# The orchestrator will handle incrementing beats and visual updates
	# We just check if ready to fire
	if is_ready and __can_produce():
		# Let orchestrator handle the visual effect
		var orchestrator = UIBeatOrchestrator.get_instance()
		if orchestrator:
			orchestrator.orchestrate_gear_fire(self)
		else:
			__fire_production()

## Tourbillon beat processing - now handled by orchestrator
func process_beat(context: BeatContext) -> void:
	# Deprecated - orchestrator handles this now
	process_beat_logic(context)

## Setup gear from card data
func setup_from_card(card: Card) -> void:
	if not card:
		return
		
	# Get timing from card (-1 means no production)
	if card.production_interval > 0:
		production_interval_beats = card.production_interval * 10  # Convert ticks to beats
		print("[EngineSlot] Card ", card.display_name, " interval: ", card.production_interval, " ticks = ", production_interval_beats, " beats")
	else:
		production_interval_beats = -1  # No production
		print("[EngineSlot] Card ", card.display_name, " has no production")
	
	# Reset state
	current_beats = card.starting_progress  # Use card's starting progress if any
	is_ready = false
	modulate = Color.WHITE
	__update_progress_display()

## Check if we have required forces to produce
func __can_produce() -> bool:
	var card = __button_entity.card
	if not card or card.force_consumption.is_empty():
		return true  # No requirements, always can produce
	
	# Check each required force
	for force_type in card.force_consumption:
		var required_amount = card.force_consumption[force_type]
		# TODO: Check GlobalGameManager.hero for forces
		# For now, return true to allow testing
	
	return true

## Fire production effect
func __fire_production() -> void:
	var card = __button_entity.card
	if not card:
		return
	
	# Consume required forces
	if GlobalGameManager.hero and not card.force_consumption.is_empty():
		if not GlobalGameManager.hero.consume_forces(card.force_consumption):
			# Can't consume, stay in ready state
			return
	
	# Produce forces
	if GlobalGameManager.hero and not card.force_production.is_empty():
		GlobalGameManager.hero.add_forces(card.force_production)
	
	# Process on_fire effect string
	if not card.on_fire_effect.is_empty():
		TourbillonEffectProcessor.process_effect(card.on_fire_effect, self, null)
	
	# Signal that the slot was activated (for stats tracking)
	GlobalSignals.signal_core_slot_activated(card.instance_id)
	
	# Reset timer
	__exit_ready_state()
	current_beats = 0
	__update_progress_display()

## Enter ready state (waiting for resources)
func __enter_ready_state() -> void:
	is_ready = true
	# Visual feedback for ready state
	modulate = Color(1.1, 1.2, 1.1)  # Slight green glow
	__update_progress_display()  # Update to show green progress bar

## Exit ready state  
func __exit_ready_state() -> void:
	is_ready = false
	# Reset visual
	modulate = Color.WHITE
	__update_progress_display()  # Update to show white progress bar

## Update the progress bar display
func __update_progress_display() -> void:
	if not %ProgressBar:
		push_error("[EngineSlot] No ProgressBar node found!")
		return
		
	if production_interval_beats > 0:
		%ProgressBar.visible = true
		var target_value = pct(current_beats, production_interval_beats)
		print("[EngineSlot] Progress update: ", current_beats, "/", production_interval_beats, " = ", target_value, "%")
		
		# Make progress bar more visible
		%ProgressBar.self_modulate = Color.WHITE  # Ensure base color is white
		%ProgressBar.z_index = 10  # Bring to front
		
		# Animate the progress bar smoothly
		var tween = create_tween()
		tween.tween_property(%ProgressBar, "value", target_value, 0.2)  # Smooth 0.2s animation
		
		# Color code the progress bar with stronger colors
		if is_ready:
			%ProgressBar.modulate = Color(0.0, 1.0, 0.0, 1.0)  # Bright green when ready
		else:
			%ProgressBar.modulate = Color(1.0, 1.0, 0.0, 1.0)  # Yellow when charging
	else:
		# -1 or invalid value - hide progress bar for non-producing cards
		%ProgressBar.value = 0
		%ProgressBar.visible = false

## Reset state for new gear
func reset() -> void:
	current_beats = 0
	is_ready = false
	__update_progress_display()
	modulate = Color.WHITE

## Set the grid position for this slot
func set_grid_position(pos: Vector2i) -> void:
	grid_position = pos

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
func set_as_bonus_square(type: String = "draw_card") -> void:
	is_bonus_square = true
	bonus_type = type
	
	# Add visual indicator for bonus square
	if type == "draw_card":
		# Create a card icon or colored overlay with stronger yellow tint
		modulate = Color(1.2, 1.2, 0.8)  # More noticeable yellow tint
		
		# Add a visual marker - could be a label or icon
		# For now, we'll rely on the border and background color differences
		# set in UIMainplate's __set_slot_active method

## Trigger the bonus effect
func __trigger_bonus_effect() -> void:
	match bonus_type:
		"draw_card":
			print("Bonus: Drawing a card!")
			if GlobalGameManager.library:
				GlobalGameManager.library.draw_card(1)
				
				# Visual feedback
				var tween = create_tween()
				tween.tween_property(self, "modulate", Color(1.5, 1.5, 0.8), 0.2)
				tween.tween_property(self, "modulate", Color(1.0, 1.1, 0.9), 0.3)
		_:
			pass
