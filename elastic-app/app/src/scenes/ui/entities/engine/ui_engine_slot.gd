extends UiTextureButton
class_name EngineSlot

@onready var top_container: HBoxContainer = $MarginContainer/MainPanel/VBoxContainer/TopBoxContainer
@onready var bottom_container: HBoxContainer = $MarginContainer/MainPanel/VBoxContainer/BottomBoxContainer


var is_activatable: bool
var timer_duration: float

# Tourbillon beat-based timing
var production_interval_beats: int = 30  # Default 3 ticks
var current_beats: int = 0
var is_ready: bool = false

var card_preview: CardUI

var CARD_UI = preload("res://src/scenes/ui/hand/card_ui.tscn")

func _ready() -> void:
	super._ready()
	
	deactivate_slot()
	create_button_entity(self, false)
	
	self.pressed.connect(__on_refresh_slot_manually)
	
	# Hide nodes we don't need yet
	await get_tree().process_frame
	top_container.visible = true
	bottom_container.visible = false
	
	GlobalSignals.core_slot_add_cooldown.connect(__on_cooldown)
	
	GlobalSignals.core_card_slotted.connect(__on_card_slotted)
	GlobalSignals.core_card_unslotted.connect(__on_card_unslotted)
	
func create_card_ui():	
	card_preview = CARD_UI.instantiate()
	card_preview.set_card_data(__button_entity.card)
	
	card_preview.position = Vector2(-170, 0)
	add_child(card_preview)
	# Start invisible and scale up
	var tween = create_tween()
	tween.tween_property(card_preview, "scale", Vector2(1.25, 1.25), 0.17)

func destroy_card_ui():	
	var tween = create_tween()
	tween.tween_property(card_preview, "scale", Vector2(.75,.75), 0.15)
	tween.tween_callback(card_preview.queue_free)
	card_preview = null
	
func __on_card_slotted(target_slot_id: String):
	if target_slot_id == __button_entity.instance_id:
		create_card_ui()
		%Name.text = __button_entity.card.display_name
		%MainPanel.visible = true
		reactivate_slot()
	
func __on_card_unslotted(target_slot_id: String):
	if target_slot_id == __button_entity.instance_id:
		%Name.text = ""
		%MainPanel.visible = false
		deactivate_slot()
		%Timer.stop()
		%ProgressBar.value = 0
		if card_preview:
			destroy_card_ui()

func _process(delta):
	if %Timer.time_left != 0:
		%ProgressBar.value = pct(%Timer.time_left, timer_duration)

func __on_cooldown(instance_id: String, duration: float):
	if instance_id == __button_entity.get_card_instance_id():
	
		deactivate_slot()
		timer_duration = duration
		%Timer.one_shot = true
		%Timer.timeout.connect(func():reactivate_slot())
		%Timer.start(timer_duration)
		%ProgressBar.value = pct(%Timer.time_left, timer_duration)

func pct(numerator: float, denominator: float):
	if denominator <= 0.001:
		return 0.0
	else:
		return 100.0 * numerator / denominator	
	

							
func deactivate_slot() -> void:	
	is_activatable = false
	# Gray out the slot image
	

func reactivate_slot() -> void:	
	is_activatable = true
	# Restore normal colors

func __on_refresh_slot_manually() -> void:
	if is_activatable and __button_entity.card != null:
		# Manual activation fires the production immediately
		__fire_production()
		if card_preview:
			card_preview.refresh()
		
func _on_mouse_entered() -> void:
	super._on_mouse_entered()
	if __button_entity.get_card_instance_id() != "":
		create_card_ui()
		
func _on_mouse_exited() -> void:
	super._on_mouse_exited()
	if card_preview:
		destroy_card_ui()

## Tourbillon beat processing - called by BeatProcessor
func process_beat(context: BeatContext) -> void:
	if not __button_entity or not __button_entity.card:
		return
	
	# Skip processing for non-producing cards (production_interval == -1)
	if production_interval_beats <= 0:
		return
	
	# Update timer progress
	if not is_ready:
		current_beats += 1
		__update_progress_display()
		
		if current_beats >= production_interval_beats:
			__enter_ready_state()
	
	# Try to fire if ready
	if is_ready and __can_produce():
		__fire_production()

## Setup gear from card data
func setup_from_card(card: Card) -> void:
	if not card:
		return
		
	# Get timing from card (-1 means no production)
	if card.production_interval > 0:
		production_interval_beats = card.production_interval * 10  # Convert ticks to beats
	else:
		production_interval_beats = -1  # No production
	
	# Reset state
	current_beats = 0
	is_ready = false
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
	modulate = Color(1.2, 1.2, 1.2)  # Slight glow

## Exit ready state
func __exit_ready_state() -> void:
	is_ready = false
	# Reset visual
	modulate = Color.WHITE

## Update the progress bar display
func __update_progress_display() -> void:
	if not %ProgressBar:
		return
		
	if production_interval_beats > 0:
		%ProgressBar.value = pct(current_beats, production_interval_beats)
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
