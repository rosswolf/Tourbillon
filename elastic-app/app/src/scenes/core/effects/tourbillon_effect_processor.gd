extends Node
class_name TourbillonEffectProcessor

## Processes effect strings for Tourbillon cards
## Effects use key=value syntax, separated by commas

# Parse and execute an effect string
static func process_effect(effect_string: String, source: Node = null, target: Node = null) -> void:
	if effect_string.is_empty():
		return
	
	var effects = effect_string.split(",")
	for effect in effects:
		var trimmed = effect.strip_edges()
		if trimmed.is_empty():
			continue
		
		_process_single_effect(trimmed, source, target)

# Process a single effect
static func _process_single_effect(effect: String, source: Node, target: Node) -> void:
	# Check for conditional effects first
	if effect.begins_with("if_"):
		_process_conditional_effect(effect, source, target)
		return
	elif effect.begins_with("per_"):
		_process_per_effect(effect, source, target)
		return
	
	# Parse key=value
	var parts = effect.split("=")
	if parts.size() != 2:
		push_warning("Invalid effect format: " + effect)
		return
	
	var effect_type = parts[0].strip_edges()
	var value_str = parts[1].strip_edges()
	var value = _parse_value(value_str)
	
	# Execute the effect
	match effect_type:
		# Card effects
		"draw_card":
			_effect_draw_cards(value)
		"discard":
			_effect_discard_cards(value)
		"mill":
			_effect_mill_cards(value)
		
		# Force effects
		"add_heat", "produce_heat":
			_effect_add_force(GameResource.Type.HEAT, value)
		"add_precision", "produce_precision":
			_effect_add_force(GameResource.Type.PRECISION, value)
		"add_momentum", "produce_momentum":
			_effect_add_force(GameResource.Type.MOMENTUM, value)
		"add_balance", "produce_balance":
			_effect_add_force(GameResource.Type.BALANCE, value)
		"add_entropy", "produce_entropy":
			_effect_add_force(GameResource.Type.ENTROPY, value)
		"consume_max":
			_effect_consume_max_force(value)
		
		# Combat effects
		"damage":
			_effect_damage(value, "topmost")
		"damage_all":
			_effect_damage_all(value)
		"damage_weakest":
			_effect_damage(value, "weakest")
		"damage_strongest":
			_effect_damage(value, "strongest")
		"damage_random":
			_effect_damage(value, "random")
		"damage_bottom":
			_effect_damage(value, "bottommost")
		"poison":
			_effect_apply_poison(value)
		"burn":
			_effect_apply_burn(value)
		"shield", "shield_self":
			_effect_add_shields(value)
		"heal":
			_effect_heal(value)
		
		# Cost modifiers
		"tool_cost_reduction":
			_effect_modify_tag_cost("TOOL", -value)
		"micro_interval_reduction":
			_effect_modify_tag_interval("MICRO", -value)
		"next_card_cost":
			_effect_set_next_card_cost(value)
		
		# Timing effects
		"haste":
			_effect_apply_haste(value)
		"slow":
			_effect_apply_slow(value)
		
		_:
			push_warning("Unknown effect type: " + effect_type)

# Parse value string to appropriate type
static func _parse_value(value_str: String):
	if value_str.is_valid_int():
		return int(value_str)
	elif value_str.is_valid_float():
		return float(value_str)
	else:
		return value_str

# Card effects
static func _effect_draw_cards(amount: int) -> void:
	if GlobalGameManager.library:
		for i in amount:
			GlobalGameManager.library.draw_card()

static func _effect_discard_cards(amount: int) -> void:
	# TODO: Implement discard selection UI
	push_warning("Discard effect not yet implemented")

static func _effect_mill_cards(amount: int) -> void:
	if GlobalGameManager.library:
		for i in amount:
			GlobalGameManager.library.mill_card()

# Force effects
static func _effect_add_force(force_type: GameResource.Type, amount: int) -> void:
	if GlobalGameManager.hero:
		var force_resource = GlobalGameManager.hero.get_force_resource(force_type)
		if force_resource:
			force_resource.add(amount)

static func _effect_consume_max_force(amount: int) -> void:
	if not GlobalGameManager.hero:
		return
	
	# Build list of forces with their current amounts
	var force_amounts: Array[Dictionary] = []
	var force_types = [
		GameResource.Type.HEAT,
		GameResource.Type.PRECISION,
		GameResource.Type.MOMENTUM,
		GameResource.Type.BALANCE,
		GameResource.Type.ENTROPY
	]
	
	for force_type in force_types:
		var force_resource = GlobalGameManager.hero.get_force_resource(force_type)
		if force_resource:
			force_amounts.append({
				"type": force_type,
				"amount": force_resource.current
			})
	
	# Sort by amount (highest first)
	force_amounts.sort_custom(func(a, b): return a.amount > b.amount)
	
	# Consume from the highest available forces first
	var consumed = 0
	for force_data in force_amounts:
		if consumed >= amount:
			break
		
		var force_type = force_data.type
		var available = force_data.amount
		var to_consume = min(amount - consumed, available)
		
		if to_consume > 0:
			var force_resource = GlobalGameManager.hero.get_force_resource(force_type)
			if force_resource:
				force_resource.subtract(to_consume)
				consumed += to_consume

# Combat effects
static func _effect_damage(amount: int, target_type: String) -> void:
	if not GlobalGameManager.has("gremlin_manager"):
		return
	
	var gremlin_manager = GlobalGameManager.get("gremlin_manager")
	if gremlin_manager:
		gremlin_manager.deal_damage_to_target(amount, target_type)

static func _effect_damage_all(amount: int) -> void:
	if not GlobalGameManager.has("gremlin_manager"):
		return
	
	var gremlin_manager = GlobalGameManager.get("gremlin_manager")
	if gremlin_manager:
		gremlin_manager.deal_damage_to_target(amount, "all")

static func _effect_apply_poison(stacks: int) -> void:
	if not GlobalGameManager.has("gremlin_manager"):
		return
	
	var gremlin_manager = GlobalGameManager.get("gremlin_manager")
	if gremlin_manager:
		gremlin_manager.apply_poison_to_target(stacks, "topmost")

static func _effect_apply_burn(duration: int) -> void:
	if not GlobalGameManager.has("gremlin_manager"):
		return
	
	var gremlin_manager = GlobalGameManager.get("gremlin_manager")
	if gremlin_manager:
		var target = gremlin_manager.get_topmost_gremlin()
		if target:
			target.apply_burn(duration)

static func _effect_add_shields(amount: int) -> void:
	# TODO: Implement hero shields
	push_warning("Shield effect not yet implemented")

static func _effect_heal(amount: int) -> void:
	# TODO: Implement hero healing
	push_warning("Heal effect not yet implemented")

# Cost modifier effects
static func _effect_modify_tag_cost(tag: String, reduction: float) -> void:
	# TODO: Store cost modifiers in a global state
	push_warning("Cost modifier not yet implemented: " + tag)

static func _effect_modify_tag_interval(tag: String, reduction: int) -> void:
	# TODO: Store interval modifiers in a global state
	push_warning("Interval modifier not yet implemented: " + tag)

static func _effect_set_next_card_cost(cost: int) -> void:
	# TODO: Store next card cost modifier
	push_warning("Next card cost not yet implemented")

# Timing effects
static func _effect_apply_haste(percent: float) -> void:
	# TODO: Apply haste to current gear
	push_warning("Haste effect not yet implemented")

static func _effect_apply_slow(percent: float) -> void:
	# TODO: Apply slow to current gear
	push_warning("Slow effect not yet implemented")

# Conditional effects
static func _process_conditional_effect(effect: String, source: Node, target: Node) -> void:
	# Format: if_tag:MICRO=3,damage=7
	# or: if_force:HEAT>5,draw_card=1
	
	var parts = effect.split(",", false, 1)  # Split into condition and effect
	if parts.size() != 2:
		push_warning("Invalid conditional effect: " + effect)
		return
	
	var condition = parts[0]
	var action = parts[1]
	
	if _evaluate_condition(condition, source):
		_process_single_effect(action, source, target)

static func _process_per_effect(effect: String, source: Node, target: Node) -> void:
	# Format: per_tag:BEAST,damage=2
	
	var parts = effect.split(",", false, 1)  # Split into condition and effect
	if parts.size() != 2:
		push_warning("Invalid per effect: " + effect)
		return
	
	var condition = parts[0]
	var action = parts[1]
	
	# Extract the tag or condition
	var condition_parts = condition.split(":")
	if condition_parts.size() != 2:
		return
	
	var count = _get_condition_count(condition_parts[1], source)
	
	# Execute the effect multiple times
	for i in count:
		_process_single_effect(action, source, target)

static func _evaluate_condition(condition: String, source: Node) -> bool:
	# Parse conditions like "if_tag:MICRO=3" or "if_force:HEAT>5"
	
	if condition.begins_with("if_tag:"):
		var tag_condition = condition.substr(7)  # Remove "if_tag:"
		var parts = tag_condition.split("=")
		if parts.size() != 2:
			return false
		
		var tag = parts[0]
		var required_count = int(parts[1])
		
		if GlobalGameManager.has("mainplate"):
			var mainplate = GlobalGameManager.get("mainplate")
			var count = mainplate.count_gears_with_tag(tag)
			return count >= required_count
	
	elif condition.begins_with("if_force:"):
		var force_condition = condition.substr(9)  # Remove "if_force:"
		# TODO: Parse force conditions like "HEAT>5"
		push_warning("Force conditions not yet implemented")
	
	return false

static func _get_condition_count(condition: String, source: Node) -> int:
	# Get count for "per" effects
	
	if condition.begins_with("tag:"):
		var tag = condition.substr(4)  # Remove "tag:"
		
		if GlobalGameManager.has("mainplate"):
			var mainplate = GlobalGameManager.get("mainplate")
			return mainplate.count_gears_with_tag(tag)
	
	return 0