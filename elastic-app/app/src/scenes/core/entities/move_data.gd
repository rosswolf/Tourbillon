extends Resource
class_name MoveData

## Data structure for a single gremlin move

@export var effect_type: String = ""  # "attack", "drain_random", "heat_soft_cap", etc.
@export var effect_value: int = 0     # Damage amount, drain amount, cap value
@export var tick_duration: int = 0    # Ticks until this move completes/triggers
@export var is_background: bool = false  # True if tick_duration == 0 (always active)

func _init(type: String = "", value: int = 0, duration: int = 0) -> void:
	effect_type = type
	effect_value = value
	tick_duration = duration
	is_background = (duration == 0)

## Get a display string for this move
func get_display_text() -> String:
	match effect_type:
		"attack":
			return "Attack: " + str(effect_value) + " damage"
		"drain_random":
			return "Drain: " + str(effect_value) + " random"
		"drain_all_types", "drain_all":
			return "Drain: " + str(effect_value) + " all"
		"drain_heat", "drain_red":
			return "Drain: " + str(effect_value) + " heat"
		"drain_precision", "drain_white":
			return "Drain: " + str(effect_value) + " precision"
		"drain_momentum", "drain_green":
			return "Drain: " + str(effect_value) + " momentum"
		"drain_balance", "drain_blue":
			return "Drain: " + str(effect_value) + " balance"
		"drain_entropy", "drain_black":
			return "Drain: " + str(effect_value) + " entropy"
		"drain_largest":
			return "Drain: " + str(effect_value) + " largest"
		
		"heat_soft_cap", "red_soft_cap":
			return "Heat cap: " + str(effect_value)
		"precision_soft_cap", "white_soft_cap":
			return "Precision cap: " + str(effect_value)
		"momentum_soft_cap", "green_soft_cap":
			return "Momentum cap: " + str(effect_value)
		"balance_soft_cap", "blue_soft_cap":
			return "Balance cap: " + str(effect_value)
		"entropy_soft_cap", "black_soft_cap":
			return "Entropy cap: " + str(effect_value)
		"max_resource_soft_cap":
			return "All forces cap: " + str(effect_value)
		
		"heat_hard_cap", "red_hard_cap":
			return "Heat HARD cap: " + str(effect_value)
		"precision_hard_cap", "white_hard_cap":
			return "Precision HARD cap: " + str(effect_value)
		"momentum_hard_cap", "green_hard_cap":
			return "Momentum HARD cap: " + str(effect_value)
		"balance_hard_cap", "blue_hard_cap":
			return "Balance HARD cap: " + str(effect_value)
		"entropy_hard_cap", "black_hard_cap":
			return "Entropy HARD cap: " + str(effect_value)
		"max_resource_hard_cap":
			return "All forces HARD cap: " + str(effect_value)
		
		"card_cost_penalty":
			return "Cards cost +" + str(effect_value)
		"force_discard":
			return "Force discard " + str(effect_value)
		"summon":
			return "Summons " + effect_type.split("=")[1] if "=" in effect_type else "Summons"
		
		_:
			return effect_type + ": " + str(effect_value)

## Check if this is a triggered action (fires once) vs persistent effect
func is_triggered_action() -> bool:
	return effect_type in ["attack", "drain_random", "drain_all_types", "drain_heat", 
		"drain_precision", "drain_momentum", "drain_balance", "drain_entropy", 
		"drain_largest", "force_discard", "summon"]

## Check if this is a persistent effect (active for duration)
func is_persistent_effect() -> bool:
	return not is_triggered_action() and not is_background