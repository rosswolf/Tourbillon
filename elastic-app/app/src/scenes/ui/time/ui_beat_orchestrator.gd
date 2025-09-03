extends Node
class_name UIBeatOrchestrator

## Orchestrates UI updates to happen in sync with beat ticks
## Creates a rhythmic, clockwork-like visual experience

signal ui_beat_tick(beat_number: int)
signal ui_progress_update(progress_percent: float)
signal ui_gear_ready(slot_positions: Array)
signal ui_gear_fire(slot_position: Vector2i)

# Visual timing constants
const BEAT_DURATION: float = 0.1  # Time per beat for UI updates
const CASCADE_DELAY: float = 0.05  # Delay between cascading effects
const PULSE_DURATION: float = 0.2  # Duration of visual pulses

var is_processing_beats: bool = false
var pending_beats: int = 0
var current_beat_display: int = 0
var registered_slots: Array[EngineSlot] = []

func _ready() -> void:
	# Connect to time advancement signals
	if GlobalGameManager.timeline_manager:
		GlobalGameManager.timeline_manager.time_changed.connect(__on_time_changed)
		print("[UIBeatOrchestrator] Connected to timeline_manager")
	else:
		push_error("[UIBeatOrchestrator] No timeline_manager found!")
	
	# This will be the single source of truth for UI beat updates
	set_process(false)

## Register a slot to receive orchestrated updates
func register_slot(slot: EngineSlot) -> void:
	if slot not in registered_slots:
		registered_slots.append(slot)
		slot.set_process(false)  # Disable individual processing

## Unregister a slot
func unregister_slot(slot: EngineSlot) -> void:
	registered_slots.erase(slot)

## Handle time changes from the timeline manager
func __on_time_changed(total_beats: int) -> void:
	print("[UIBeatOrchestrator] Time changed signal received. Total beats: ", total_beats, " Current display: ", current_beat_display)
	# Calculate how many beats to animate
	var beats_to_animate = total_beats - current_beat_display
	if beats_to_animate > 0:
		pending_beats += beats_to_animate
		print("[UIBeatOrchestrator] Beats to animate: ", beats_to_animate, " Pending: ", pending_beats)
		if not is_processing_beats:
			__process_pending_beats()

## Process pending beats with visual orchestration
func __process_pending_beats() -> void:
	if pending_beats <= 0:
		is_processing_beats = false
		return
	
	is_processing_beats = true
	
	# Process one beat with orchestrated visuals
	await __orchestrate_single_beat()
	
	current_beat_display += 1
	pending_beats -= 1
	
	# Continue processing remaining beats
	if pending_beats > 0:
		__process_pending_beats()
	else:
		is_processing_beats = false

## Orchestrate a single beat's visual updates
func __orchestrate_single_beat() -> void:
	# 1. Emit the beat tick for all listeners
	ui_beat_tick.emit(current_beat_display + 1)
	
	# Create a visual beat indicator (temporary flash on screen)
	__show_beat_flash()
	
	# 2. Update all progress bars simultaneously
	await __update_all_progress_bars()
	
	# 3. Check for ready gears and pulse them
	await __check_and_pulse_ready_gears()
	
	# 4. Small pause for the "tick" feel
	await get_tree().create_timer(BEAT_DURATION).timeout

## Update all registered slots' progress bars in sync
func __update_all_progress_bars() -> void:
	var tweens: Array[Tween] = []
	print("[UIBeatOrchestrator] Updating progress bars for ", registered_slots.size(), " slots")
	
	for slot in registered_slots:
		if not is_instance_valid(slot):
			continue
			
		# Check if slot has a card
		if slot.__button_entity and slot.__button_entity.card:
			# Skip non-producing cards
			if slot.production_interval_beats <= 0:
				continue
				
			# Calculate progress for this slot
			slot.current_beats = min(slot.current_beats + 1, slot.production_interval_beats)
			var progress = slot.pct(slot.current_beats, slot.production_interval_beats)
			print("[UIBeatOrchestrator] Slot at ", slot.grid_position, " progress: ", slot.current_beats, "/", slot.production_interval_beats)
			
			# Update the display manually first
			slot.__update_progress_display()
			
			# Create synchronized tween
			var tween = create_tween()
			tween.set_parallel(true)
			
			# Animate progress bar
			if slot.get_node_or_null("%ProgressBar"):
				var progress_bar = slot.get_node("%ProgressBar")
				progress_bar.visible = true  # Ensure it's visible
				tween.tween_property(progress_bar, "value", progress, BEAT_DURATION * 0.8)
			
			# Add subtle scale pulse for visual feedback
			tween.tween_property(slot, "scale", Vector2(1.02, 1.02), BEAT_DURATION * 0.4)
			tween.chain().tween_property(slot, "scale", Vector2(1.0, 1.0), BEAT_DURATION * 0.4)
			
			tweens.append(tween)
	
	# Emit progress update signal for other UI elements
	ui_progress_update.emit(100.0 / 30.0)  # Approximate progress per beat
	
	# Wait for all tweens to complete
	if tweens.size() > 0:
		await tweens[0].finished

## Check for ready gears and create pulsing effect
func __check_and_pulse_ready_gears() -> void:
	var ready_positions: Array = []
	var ready_slots: Array[EngineSlot] = []
	
	for slot in registered_slots:
		if not is_instance_valid(slot):
			continue
			
		# Check if slot has a card and is ready
		assert(slot != null, "Registered slot must exist")
		# All slots should implement get_card_instance_id
		if slot.get_card_instance_id() != "":
			# Check if this slot just became ready
			if slot.current_beats >= slot.production_interval_beats and not slot.is_ready:
				ready_positions.append(slot.grid_position)
				ready_slots.append(slot)
				# Slots should have __enter_ready_state for state management
				slot.__enter_ready_state()
	
	if ready_positions.size() > 0:
		ui_gear_ready.emit(ready_positions)
		
		# Create cascading pulse effect for ready gears
		for i in range(ready_slots.size()):
			var slot = ready_slots[i]
			await get_tree().create_timer(CASCADE_DELAY * i).timeout
			__pulse_slot(slot)

## Create a visual pulse effect on a slot
func __pulse_slot(slot: EngineSlot) -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Scale pulse
	tween.tween_property(slot, "scale", Vector2(1.15, 1.15), PULSE_DURATION * 0.5)
	tween.chain().tween_property(slot, "scale", Vector2(1.0, 1.0), PULSE_DURATION * 0.5)
	
	# Glow effect
	var original_modulate = slot.modulate
	tween.tween_property(slot, "modulate", Color(1.2, 1.3, 1.2), PULSE_DURATION * 0.5)
	tween.chain().tween_property(slot, "modulate", original_modulate, PULSE_DURATION * 0.5)

## Orchestrate a gear firing with visual effects
func orchestrate_gear_fire(slot: EngineSlot) -> void:
	ui_gear_fire.emit(slot.grid_position)
	
	# Create firing visual effect
	var tween = create_tween()
	
	# Flash effect
	tween.tween_property(slot, "modulate", Color(2.0, 2.0, 2.0), 0.1)
	tween.tween_property(slot, "modulate", Color.WHITE, 0.2)
	
	# Rotation for mechanical feel
	tween.parallel().tween_property(slot, "rotation", 0.1, 0.1)
	tween.tween_property(slot, "rotation", -0.1, 0.1)
	tween.tween_property(slot, "rotation", 0.0, 0.1)
	
	# Reset the slot's timer with visual feedback
	slot.current_beats = 0
	slot.__exit_ready_state()
	
	# Animate progress bar reset
	if slot.get_node_or_null("%ProgressBar"):
		var progress_bar = slot.get_node("%ProgressBar")
		var reset_tween = create_tween()
		reset_tween.tween_property(progress_bar, "value", 0, 0.3)

## Show a visual flash to indicate beat tick
func __show_beat_flash() -> void:
	# Update or create the persistent timer display
	if not persistent_timer_label:
		__create_persistent_timer()
	
	# Update the timer text
	var current_tick = (current_beat_display + 1) / 10
	var current_beat = (current_beat_display + 1) % 10
	var decimal_beat = current_beat * 100  # Convert beat to milliseconds representation
	persistent_timer_label.text = "%d.%03d" % [current_tick, decimal_beat]

## Create the persistent timer display above the battleground
func __create_persistent_timer() -> void:
	# Find the mainplate to position timer above it
	var mainplate = get_tree().get_first_node_in_group("mainplate")
	if not mainplate:
		push_error("Cannot find mainplate for timer positioning")
		return
	
	# Create container positioned above mainplate
	timer_container = Control.new()
	timer_container.set_anchors_preset(Control.PRESET_CENTER_TOP)
	timer_container.position = Vector2(0, -150)  # Position above mainplate
	timer_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Create panel background for visibility
	var panel_container = PanelContainer.new()
	panel_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_container.custom_minimum_size = Vector2(300, 100)
	
	# Style the panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.0, 0.0, 0.0, 0.8)  # Dark semi-transparent
	panel_style.set_corner_radius_all(20)
	panel_style.set_border_width_all(4)
	panel_style.border_color = Color(1.0, 0.8, 0.0, 1.0)  # Gold border
	panel_style.set_expand_margin_all(25)
	panel_container.add_theme_stylebox_override("panel", panel_style)
	
	# Create center container for the label
	var center_container = CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Create the timer label
	persistent_timer_label = Label.new()
	persistent_timer_label.text = "0.000"
	persistent_timer_label.add_theme_font_size_override("font_size", 96)  # Very large
	persistent_timer_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.0, 1.0))  # Bright yellow
	persistent_timer_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 1.0))
	persistent_timer_label.add_theme_constant_override("shadow_offset_x", 3)
	persistent_timer_label.add_theme_constant_override("shadow_offset_y", 3)
	
	# Assemble hierarchy
	center_container.add_child(persistent_timer_label)
	panel_container.add_child(center_container)
	timer_container.add_child(panel_container)
	
	# Add to mainplate's parent to keep it centered
	mainplate.get_parent().add_child(timer_container)
	
	# Center the timer horizontally relative to mainplate
	var mainplate_center = mainplate.global_position + mainplate.size / 2
	timer_container.global_position.x = mainplate_center.x - panel_container.custom_minimum_size.x / 2

## Get the singleton instance
static func get_instance() -> UIBeatOrchestrator:
	# This should be added to the scene tree as an autoload or singleton
	var tree = Engine.get_main_loop() as SceneTree
	if tree.has_group("ui_beat_orchestrator"):
		var nodes = tree.get_nodes_in_group("ui_beat_orchestrator")
		if nodes.size() > 0:
			return nodes[0] as UIBeatOrchestrator
	return null