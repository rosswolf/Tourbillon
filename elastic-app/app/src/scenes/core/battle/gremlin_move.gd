extends Resource
class_name GremlinMove

## Represents a single move in a gremlin's move cycle
## Moves define passive constraints, timed triggers, and transition conditions

# ============================================================================
# PUBLIC INTERFACE
# ============================================================================

## Move identification
@export var move_id: String = ""
@export var move_name: String = ""

## Move timing
@export var duration_ticks: int = 0  # 0 = permanent/until triggered
@export var trigger_interval: int = 0  # Ticks between triggers (0 = passive only)
@export var max_triggers: int = 0  # Max times can trigger (0 = unlimited)

## Transition control
@export var next_move: String = ""  # ID of next move (empty = cycle or end)
@export var transition_condition: String = ""  # Condition type
@export var transition_value: int = 0  # Threshold for condition

## Effects (all use simple effect string format)
@export var passive_effects: String = ""  # Always active during this move
@export var trigger_effects: String = ""  # Effects on each trigger
@export var on_enter_effects: String = ""  # When move starts
@export var on_exit_effects: String = ""  # When move ends

## Display information
@export var description: String = ""
@export var icon_path: String = ""

# Internal tracking (not exported)
var __current_duration: int = 0
var __trigger_count: int = 0
var __ticks_until_trigger: int = 0
var __is_active: bool = false

# ============================================================================
# PUBLIC METHODS
# ============================================================================

## Activate this move
func activate(gremlin: Gremlin) -> void:
	if __is_active:
		return
	
	__is_active = true
	__current_duration = 0
	__trigger_count = 0
	__ticks_until_trigger = trigger_interval
	
	# Process enter effects
	if not on_enter_effects.is_empty():
		__process_effects(on_enter_effects, gremlin)
	
	# Apply passive effects immediately
	if not passive_effects.is_empty():
		__apply_passive_effects(passive_effects, gremlin)

## Deactivate this move
func deactivate(gremlin: Gremlin) -> void:
	if not __is_active:
		return
	
	__is_active = false
	
	# Process exit effects
	if not on_exit_effects.is_empty():
		__process_effects(on_exit_effects, gremlin)
	
	# Remove passive effects
	if not passive_effects.is_empty():
		__remove_passive_effects(passive_effects, gremlin)

## Process a tick for this move
func process_tick(gremlin: Gremlin) -> bool:
	if not __is_active:
		return false
	
	__current_duration += 1
	
	# Check if move duration expired
	if duration_ticks > 0 and __current_duration >= duration_ticks:
		return true  # Signal transition needed
	
	# Process triggers
	if trigger_interval > 0:
		__ticks_until_trigger -= 1
		if __ticks_until_trigger <= 0:
			__execute_trigger(gremlin)
			__ticks_until_trigger = trigger_interval
			
			# Check max triggers
			if max_triggers > 0 and __trigger_count >= max_triggers:
				return true  # Signal transition needed
	
	# Check transition conditions
	return __check_transition_condition(gremlin)

## Get display text for this move's effects
func get_effect_description() -> String:
	var parts: Array[String] = []
	
	if not passive_effects.is_empty():
		parts.append("Passive: " + __describe_effects(passive_effects))
	
	if not trigger_effects.is_empty() and trigger_interval > 0:
		var trigger_text = "Every " + str(trigger_interval) + " ticks: " + __describe_effects(trigger_effects)
		if max_triggers > 0:
			trigger_text += " (x" + str(max_triggers) + ")"
		parts.append(trigger_text)
	
	if not description.is_empty():
		parts.append(description)
	
	return "\n".join(parts)

## Check if this move is currently active
func is_active() -> bool:
	return __is_active

## Get progress towards next trigger
func get_trigger_progress() -> float:
	if trigger_interval <= 0:
		return 0.0
	return 1.0 - (float(__ticks_until_trigger) / float(trigger_interval))

# ============================================================================
# PRIVATE METHODS
# ============================================================================

## Execute a trigger
func __execute_trigger(gremlin: Gremlin) -> void:
	__trigger_count += 1
	
	if not trigger_effects.is_empty():
		__process_effects(trigger_effects, gremlin)
	
	# Signal for UI update
	if gremlin:
		gremlin.disruption_triggered.emit(gremlin)

## Process effect string through SimpleEffectProcessor
func __process_effects(effects: String, gremlin: Gremlin) -> void:
	# Add gremlin context to effects
	var contextualized = __add_gremlin_context(effects, gremlin)
	
	const SimpleEffectProcessor = preload("res://src/scenes/core/effects/simple_effect_processor.gd")
	SimpleEffectProcessor.process_effects(contextualized, gremlin)

## Apply passive effects (constraints)
func __apply_passive_effects(effects: String, gremlin: Gremlin) -> void:
	# Parse and apply constraints
	var parts = effects.split(",")
	for part in parts:
		var effect = part.strip_edges()
		if effect.is_empty():
			continue
		
		# Store constraint on gremlin for later removal
		if not gremlin.has_meta("active_constraints"):
			gremlin.set_meta("active_constraints", [])
		var constraints: Array = gremlin.get_meta("active_constraints")
		constraints.append(effect)
		
		# Apply through processor
		__process_effects(effect, gremlin)

## Remove passive effects when move ends
func __remove_passive_effects(effects: String, gremlin: Gremlin) -> void:
	# This requires the constraint manager to track and remove
	# For now, mark for recalculation
	if gremlin.has_meta("active_constraints"):
		gremlin.remove_meta("active_constraints")
	
	# Trigger global constraint recalculation
	GremlinDownsideProcessor.recalculate_all_downsides()

## Check if transition condition is met
func __check_transition_condition(gremlin: Gremlin) -> bool:
	if transition_condition.is_empty():
		return false
	
	match transition_condition:
		"health_below":
			return gremlin.current_hp < transition_value
		"health_percent":
			var percent = float(gremlin.current_hp) / float(gremlin.max_hp) * 100.0
			return percent < float(transition_value)
		"shields_depleted":
			return gremlin.shields <= 0
		"trigger_count":
			return __trigger_count >= transition_value
		"duration":
			return __current_duration >= transition_value
		_:
			return false

## Add gremlin-specific context to effects
func __add_gremlin_context(effects: String, gremlin: Gremlin) -> String:
	# Replace placeholders with actual values
	var result = effects
	
	if gremlin:
		result = result.replace("{hp}", str(gremlin.current_hp))
		result = result.replace("{max_hp}", str(gremlin.max_hp))
		result = result.replace("{slot}", str(gremlin.slot_index))
		result = result.replace("{name}", gremlin.gremlin_name)
	
	return result

## Generate human-readable effect descriptions
func __describe_effects(effects: String) -> String:
	var descriptions: Array[String] = []
	var parts = effects.split(",")
	
	for part in parts:
		var effect = part.strip_edges()
		if effect.is_empty():
			continue
		
		# Parse effect type and value
		var kv = effect.split("=")
		if kv.size() == 2:
			var type = kv[0]
			var value = kv[1]
			
			match type:
				"heat_cap", "red_cap":
					descriptions.append("Heat capped at " + value)
				"precision_cap", "white_cap":
					descriptions.append("Precision capped at " + value)
				"momentum_cap", "green_cap":
					descriptions.append("Momentum capped at " + value)
				"drain_heat", "drain_red":
					descriptions.append("Drain " + value + " Heat")
				"drain_all":
					descriptions.append("Drain " + value + " from all")
				"card_tax":
					descriptions.append("Cards cost +" + value + " ticks")
				"force_discard":
					descriptions.append("Discard " + value + " cards")
				"summon":
					descriptions.append("Summons " + value)
				"damage":
					descriptions.append("Deal " + value + " damage")
				"heal":
					descriptions.append("Heal " + value + " HP")
				"shield":
					descriptions.append("Gain " + value + " shields")
				_:
					descriptions.append(effect)
		else:
			descriptions.append(effect)
	
	return ", ".join(descriptions)

# ============================================================================
# STATIC FACTORY METHODS
# ============================================================================

## Create a move from a simple string format
static func from_string(move_string: String, move_id: String = "") -> GremlinMove:
	var move = GremlinMove.new()
	
	if move_id.is_empty():
		move.move_id = "move_" + str(Time.get_unix_time_from_system())
	else:
		move.move_id = move_id
	
	# Parse format: "passive:effect1,effect2|tick=N:effect3,effect4"
	var sections = move_string.split("|")
	
	for section in sections:
		var parts = section.split(":")
		if parts.size() < 2:
			continue
		
		var timing = parts[0].strip_edges()
		var effects = parts[1].strip_edges()
		
		if timing == "passive":
			move.passive_effects = effects
			move.trigger_interval = 0
		elif timing.begins_with("tick="):
			var tick_str = timing.substr(5)
			move.trigger_interval = int(tick_str)
			move.trigger_effects = effects
		elif timing == "enter":
			move.on_enter_effects = effects
		elif timing == "exit":
			move.on_exit_effects = effects
	
	return move

## Create a simple passive constraint move
static func create_constraint(constraint_type: String, value: int) -> GremlinMove:
	var move = GremlinMove.new()
	move.move_id = constraint_type + "_constraint"
	move.move_name = constraint_type.capitalize() + " Constraint"
	move.passive_effects = constraint_type + "=" + str(value)
	move.trigger_interval = 0
	return move

## Create a simple drain move
static func create_drain(force_type: String, amount: int, interval_ticks: int) -> GremlinMove:
	var move = GremlinMove.new()
	move.move_id = "drain_" + force_type
	move.move_name = "Drain " + force_type.capitalize()
	move.trigger_interval = interval_ticks
	move.trigger_effects = "drain_" + force_type + "=" + str(amount)
	return move