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
		"draw", "draw_card":
			_effect_draw_cards(value)
		"discard":
			_effect_discard_cards(value)
		"mill":
			_effect_mill_cards(value)
		
		# Force effects - Basic forces (Red, Blue, Green, White, Purple)
		"add_red", "produce_red":
			_effect_add_force(GameResource.Type.RED, value)
		"add_blue", "produce_blue":
			_effect_add_force(GameResource.Type.BLUE, value)
		"add_green", "produce_green":
			_effect_add_force(GameResource.Type.GREEN, value)
		"add_white", "produce_white":
			_effect_add_force(GameResource.Type.WHITE, value)
		"add_purple", "produce_purple", "add_black", "produce_black":
			_effect_add_force(GameResource.Type.PURPLE, value)
		
		# Force effects - Combined forces
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
		
		# Pay/consume force effects - Basic forces
		"pay_red":
			_effect_consume_force(GameResource.Type.RED, value)
		"pay_blue":
			_effect_consume_force(GameResource.Type.BLUE, value)
		"pay_green":
			_effect_consume_force(GameResource.Type.GREEN, value)
		"pay_white":
			_effect_consume_force(GameResource.Type.WHITE, value)
		"pay_black", "pay_purple":
			_effect_consume_force(GameResource.Type.PURPLE, value)
		"pay_heat":
			_effect_consume_force(GameResource.Type.HEAT, value)
		"pay_precision":
			_effect_consume_force(GameResource.Type.PRECISION, value)
		"pay_momentum":
			_effect_consume_force(GameResource.Type.MOMENTUM, value)
		"pay_balance":
			_effect_consume_force(GameResource.Type.BALANCE, value)
		"pay_entropy":
			_effect_consume_force(GameResource.Type.ENTROPY, value)
		"pay_largest":
			_effect_consume_largest_force(value)
		"pay_smallest":
			_effect_consume_smallest_force(value)
		
		# Speed modifier
		"faster":
			_effect_apply_faster(value, source)
		
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
			GlobalGameManager.library.draw_card(1)

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
			force_resource.increment(amount)

static func _effect_consume_force(force_type: GameResource.Type, amount: float) -> void:
	if GlobalGameManager.hero:
		var force_resource = GlobalGameManager.hero.get_force_resource(force_type)
		if force_resource:
			# Handle fractional amounts (like 1.5, 2.5, etc.)
			var int_part = int(amount)
			var frac_part = amount - int_part
			
			# Consume the integer part
			if force_resource.amount >= int_part:
				force_resource.decrement(int_part)
			
			# Handle fractional part with randomness
			if frac_part > 0 and randf() < frac_part:
				if force_resource.amount >= 1:
					force_resource.decrement(1)

static func _effect_consume_largest_force(amount: float) -> void:
	if not GlobalGameManager.hero:
		return
	
	# Find the force with the most current amount
	var largest_type = null
	var largest_amount: int = 0
	
	var force_types: Array[String] = [
		GameResource.Type.RED,
		GameResource.Type.BLUE,
		GameResource.Type.GREEN,
		GameResource.Type.WHITE,
		GameResource.Type.PURPLE,
		GameResource.Type.HEAT,
		GameResource.Type.PRECISION,
		GameResource.Type.MOMENTUM,
		GameResource.Type.BALANCE,
		GameResource.Type.ENTROPY
	]
	
	for force_type in force_types:
		var force_resource = GlobalGameManager.hero.get_force_resource(force_type)
		if force_resource and force_resource.amount > largest_amount:
			largest_amount = force_resource.amount
			largest_type = force_type
	
	# Consume from the largest force
	if largest_type:
		_effect_consume_force(largest_type, amount)

static func _effect_consume_smallest_force(amount: float) -> void:
	if not GlobalGameManager.hero:
		return
	
	# Find the force with the least current amount (but > 0)
	var smallest_type = null
	var smallest_amount: int = 999999
	
	var force_types: Array[String] = [
		GameResource.Type.RED,
		GameResource.Type.BLUE,
		GameResource.Type.GREEN,
		GameResource.Type.WHITE,
		GameResource.Type.PURPLE,
		GameResource.Type.HEAT,
		GameResource.Type.PRECISION,
		GameResource.Type.MOMENTUM,
		GameResource.Type.BALANCE,
		GameResource.Type.ENTROPY
	]
	
	for force_type in force_types:
		var force_resource = GlobalGameManager.hero.get_force_resource(force_type)
		if force_resource and force_resource.current > 0 and force_resource.current < smallest_amount:
			smallest_amount = force_resource.current
			smallest_type = force_type
	
	# Consume from the smallest force
	if smallest_type:
		_effect_consume_force(smallest_type, amount)

static func _effect_consume_max_force(amount: int) -> void:
	if not GlobalGameManager.hero:
		return
	
	# Build list of forces with their current amounts
	var force_amounts: Array[Dictionary] = []
	var force_types: Array[String] = [
		GameResource.Type.RED,
		GameResource.Type.BLUE,
		GameResource.Type.GREEN,
		GameResource.Type.WHITE,
		GameResource.Type.PURPLE,
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
	var consumed: int = 0
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
	# Note: gremlin_manager is not a property of GlobalGameManager yet
	# This will need to be added when gremlin system is fully integrated
	push_warning("Gremlin damage not yet implemented - gremlin_manager not initialized")
	return

static func _effect_damage_all(amount: int) -> void:
	# Note: gremlin_manager is not a property of GlobalGameManager yet
	push_warning("Gremlin damage all not yet implemented - gremlin_manager not initialized")
	return

static func _effect_apply_poison(stacks: int) -> void:
	# Note: gremlin_manager is not a property of GlobalGameManager yet
	push_warning("Poison not yet implemented - gremlin_manager not initialized")
	return

static func _effect_apply_burn(duration: int) -> void:
	# Note: gremlin_manager is not a property of GlobalGameManager yet
	push_warning("Burn not yet implemented - gremlin_manager not initialized")
	return

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
static func _effect_apply_faster(beats: int, source: Node) -> void:
	# Reduce the current gear's timer by X beats
	if source:
		# Source should be a Card or Mainplate with timer metadata
		var current_beats = source.get_meta("current_beats", 0)
		var new_beats = min(current_beats + beats, source.get_meta("production_interval_beats", 30))
		source.set_meta("current_beats", new_beats)
		
		# Update progress display for UI slots
		if source is EngineSlot:
			source.__update_progress_display()
		# For other sources, signal the update
		elif GlobalSignals.has_signal("core_gear_process_beat"):
			var card_id = source.get_meta("instance_id", "")
			if card_id != "":
				GlobalSignals.signal_core_gear_process_beat(card_id, null)

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
		
		assert(GlobalGameManager.has("mainplate"), "Mainplate must exist for tag conditions")
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
		
		assert(GlobalGameManager.has("mainplate"), "Mainplate must exist for getting tag count")
		var mainplate = GlobalGameManager.get("mainplate")
		return mainplate.count_gears_with_tag(tag)
	
	return 0
