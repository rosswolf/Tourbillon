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
		__button_entity.activate_slot_effect(__button_entity.card, null)
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
	
	# Update timer progress
	if not is_ready:
		current_beats += 1
		_update_progress_display()
		
		if current_beats >= production_interval_beats:
			_enter_ready_state()
	
	# Try to fire if ready
	if is_ready and _can_produce():
		_fire_production()

## Setup gear from card data
func setup_from_card(card: Card) -> void:
	if not card:
		return
		
	# Get timing from card
	production_interval_beats = card.production_interval * 10  # Convert ticks to beats
	
	# Reset state
	current_beats = 0
	is_ready = false
	_update_progress_display()

## Check if we have required forces to produce
func _can_produce() -> bool:
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
func _fire_production() -> void:
	var card = __button_entity.card
	if not card:
		return
	
	# TODO: Consume and produce forces via GlobalGameManager.hero
	
	# Fire any additional card effects
	__button_entity.activate_slot_effect(card, null)
	
	# Reset timer
	_exit_ready_state()
	current_beats = 0
	_update_progress_display()

## Enter ready state (waiting for resources)
func _enter_ready_state() -> void:
	is_ready = true
	# Visual feedback for ready state
	modulate = Color(1.2, 1.2, 1.2)  # Slight glow

## Exit ready state
func _exit_ready_state() -> void:
	is_ready = false
	# Reset visual
	modulate = Color.WHITE

## Update the progress bar display
func _update_progress_display() -> void:
	if not %ProgressBar:
		return
		
	if production_interval_beats > 0:
		%ProgressBar.value = pct(current_beats, production_interval_beats)
	else:
		%ProgressBar.value = 0

## Reset state for new gear
func reset() -> void:
	current_beats = 0
	is_ready = false
	_update_progress_display()
	modulate = Color.WHITE
