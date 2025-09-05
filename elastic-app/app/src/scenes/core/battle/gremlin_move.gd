extends RefCounted
class_name GremlinMove

## Represents a single move that a gremlin can perform
## Each move has its own timing and effect

# Move properties
var move_index: int = 0          # Which move slot this is (1-6)
var effect_string: String = ""   # e.g., "drain_random=1" or "card_cost_penalty=2"
var interval_beats: int = 0      # How often this move triggers (in beats, 10 beats = 1 tick)
var beats_until_trigger: int = 0 # Countdown to next trigger

# Progress tracking
var is_passive: bool = false      # True if this move is always active (interval_beats == 0)
var times_triggered: int = 0      # How many times this move has triggered

# Visual/UI properties  
var display_name: String = ""     # User-friendly name like "Drain" or "Summon"
var display_color: Color = Color.WHITE  # Color for UI representation

func _init(index: int = 0, effect: String = "", interval_ticks: int = 0) -> void:
	move_index = index
	effect_string = effect
	
	# Convert ticks to beats (1 tick = 10 beats)
	if interval_ticks == 0:
		is_passive = true
		interval_beats = -1  # Passive moves don't have intervals
		beats_until_trigger = -1
	else:
		is_passive = false
		interval_beats = interval_ticks * 10
		beats_until_trigger = interval_beats
	
	# Parse display name and color from effect
	_parse_display_properties()

## Reset the move countdown (used when gremlin is created)
func reset() -> void:
	times_triggered = 0
	if not is_passive:
		beats_until_trigger = interval_beats

## Update this move's progress for one beat
## Returns true if the move triggered this beat
func process_beat() -> bool:
	if is_passive:
		return false  # Passive moves don't trigger on beats
	
	if beats_until_trigger <= 0:
		return false  # Shouldn't happen but safety check
	
	# Count down
	beats_until_trigger -= 1
	
	# Check if we should trigger
	if beats_until_trigger == 0:
		times_triggered += 1
		beats_until_trigger = interval_beats  # Reset countdown
		return true  # Signal that this move triggered
	
	return false

## Get the current progress toward the next trigger (0.0 to 1.0)
func get_progress_percent() -> float:
	if is_passive or interval_beats <= 0:
		return 0.0
	
	return float(interval_beats - beats_until_trigger) / float(interval_beats)

## Get the effect type and value from the effect string
func get_effect_parts() -> Dictionary:
	if effect_string.is_empty():
		return {}
	
	var parts = effect_string.split("=")
	if parts.size() != 2:
		return {"type": effect_string, "value": ""}
	
	return {
		"type": parts[0].strip_edges(),
		"value": parts[1].strip_edges()
	}

## Parse display properties based on effect type
func _parse_display_properties() -> void:
	var parts = get_effect_parts()
	if parts.is_empty():
		return
	
	var effect_type = parts.get("type", "")
	
	# Set display name and color based on effect type
	match effect_type:
		# Resource caps
		"heat_soft_cap", "red_soft_cap", "heat_hard_cap", "red_hard_cap":
			display_name = "Heat Cap"
			display_color = Color(1.0, 0.3, 0.3)  # Red
		"precision_soft_cap", "white_soft_cap", "precision_hard_cap", "white_hard_cap":
			display_name = "Precision Cap"
			display_color = Color(0.95, 0.95, 0.95)  # White
		"momentum_soft_cap", "green_soft_cap", "momentum_hard_cap", "green_hard_cap":
			display_name = "Momentum Cap"
			display_color = Color(0.3, 0.8, 0.3)  # Green
		"balance_soft_cap", "blue_soft_cap", "balance_hard_cap", "blue_hard_cap":
			display_name = "Balance Cap"
			display_color = Color(0.3, 0.3, 1.0)  # Blue
		"entropy_soft_cap", "black_soft_cap", "entropy_hard_cap", "black_hard_cap":
			display_name = "Entropy Cap"
			display_color = Color(0.3, 0.3, 0.3)  # Dark gray
		"max_resource_soft_cap", "max_resource_hard_cap":
			display_name = "All Caps"
			display_color = Color(0.8, 0.8, 0.8)  # Gray
		
		# Drains
		"drain_random":
			display_name = "Random Drain"
			display_color = Color(0.9, 0.6, 0.9)  # Purple
		"drain_all_types":
			display_name = "Drain All"
			display_color = Color(0.7, 0.5, 0.9)  # Purple
		"drain_heat", "drain_red":
			display_name = "Drain Heat"
			display_color = Color(1.0, 0.3, 0.3)  # Red
		"drain_precision", "drain_white":
			display_name = "Drain Precision"
			display_color = Color(0.95, 0.95, 0.95)  # White
		"drain_momentum", "drain_green":
			display_name = "Drain Momentum"
			display_color = Color(0.3, 0.8, 0.3)  # Green
		"drain_balance", "drain_blue":
			display_name = "Drain Balance"
			display_color = Color(0.3, 0.3, 1.0)  # Blue
		"drain_entropy", "drain_black":
			display_name = "Drain Entropy"
			display_color = Color(0.3, 0.3, 0.3)  # Dark gray
		"drain_largest":
			display_name = "Drain Largest"
			display_color = Color(0.8, 0.4, 0.8)  # Purple
		"drain_highest": # Alias
			display_name = "Drain Highest"
			display_color = Color(0.8, 0.4, 0.8)  # Purple
			
		# Card effects
		"card_cost_penalty":
			display_name = "Cost Penalty"
			display_color = Color(1.0, 0.8, 0.3)  # Yellow
		"force_discard":
			display_name = "Discard"
			display_color = Color(1.0, 0.5, 0.3)  # Orange
			
		# Summons
		"summon":
			display_name = "Summon"
			display_color = Color(0.5, 1.0, 0.5)  # Light green
			
		# Self buffs
		"self_gain_armor":
			display_name = "Gain Armor"
			display_color = Color(0.6, 0.6, 0.7)  # Steel gray
		"self_gain_shields":
			display_name = "Gain Shields"
			display_color = Color(0.3, 0.7, 1.0)  # Light blue
		"all_gremlins_gain_shields":
			display_name = "Group Shields"
			display_color = Color(0.3, 0.9, 1.0)  # Cyan
		"all_gremlins_gain_armor":
			display_name = "Group Armor"
			display_color = Color(0.7, 0.7, 0.8)  # Light steel
			
		_:
			display_name = _humanize_effect_type(effect_type)
			display_color = Color.WHITE

## Get a formatted countdown string
func get_countdown_text() -> String:
	if is_passive:
		return "(Passive)"
	
	if beats_until_trigger <= 0:
		return "(NOW!)"
	
	# Convert beats to ticks.beats format
	var ticks = beats_until_trigger / 10
	var beats = beats_until_trigger % 10
	return "(in %d.%d)" % [ticks, beats]

## Get the full display text for UI
func get_display_text() -> String:
	var parts = get_effect_parts()
	var value = parts.get("value", "")
	
	# Add value to display name if applicable
	var text = display_name
	if value != "" and value != "0":
		# Special formatting for certain types
		var effect_type = parts.get("type", "")
		if effect_type == "summon":
			text = display_name + " " + _humanize_effect_type(value)
		elif effect_type.ends_with("_cap"):
			text = display_name + " (" + value + ")"
		else:
			text = display_name + " " + value
	
	# Add countdown
	if not is_passive:
		text += " " + get_countdown_text()
	
	return text

## Get description of what this move does
func get_description() -> String:
	var parts = get_effect_parts()
	if parts.is_empty():
		return "Unknown effect"
	
	var effect_type = parts.get("type", "")
	var value = parts.get("value", "")
	
	# Generate description based on effect
	var desc = _describe_effect(effect_type, value)
	
	# Add timing info
	if not is_passive:
		var ticks = interval_beats / 10
		desc += " every %d ticks" % ticks
	
	return desc

## Helper to describe an effect in plain language
func _describe_effect(effect_type: String, value: String) -> String:
	match effect_type:
		# Caps
		"heat_soft_cap", "red_soft_cap":
			return "Limits Heat to %s" % value
		"heat_hard_cap", "red_hard_cap":
			return "Hard caps Heat at %s" % value
		"max_resource_soft_cap":
			return "Limits all resources to %s" % value
		"max_resource_hard_cap":
			return "Hard caps all resources at %s" % value
			
		# Drains
		"drain_random":
			return "Drains %s random resource" % value
		"drain_all_types":
			return "Drains %s from all resources" % value
		"drain_largest", "drain_highest":
			return "Drains %s from largest resource" % value
		"drain_heat", "drain_red":
			return "Drains %s Heat" % value
			
		# Card effects
		"card_cost_penalty":
			return "Cards cost +%s ticks" % value
		"force_discard":
			return "Discard %s card(s)" % value
			
		# Summons
		"summon":
			return "Summons %s" % _humanize_effect_type(value)
			
		# Self buffs
		"self_gain_armor":
			return "Gains %s armor" % value
		"self_gain_shields":
			return "Gains %s shields" % value
		"all_gremlins_gain_shields":
			return "All gremlins gain %s shields" % value
		"all_gremlins_gain_armor":
			return "All gremlins gain %s armor" % value
			
		_:
			return "%s: %s" % [_humanize_effect_type(effect_type), value]

## Convert snake_case to Title Case
func _humanize_effect_type(effect_type: String) -> String:
	var words = effect_type.split("_")
	var result = ""
	for word in words:
		if result != "":
			result += " "
		result += word.capitalize()
	return result