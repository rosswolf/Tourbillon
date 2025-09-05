extends Node
class_name GremlinDownsideProcessor

## Processes downside effects from gremlins
## Downsides are constraints that gremlins impose while active

# Active downsides currently applied
static var active_downsides: Dictionary[String, int] = {}  # downside_type -> value

# Parse and apply a gremlin's moves/downsides string
static func process_gremlin_moves(moves_string: String, gremlin: Gremlin) -> void:
	if moves_string.is_empty():
		return

	var parts = moves_string.split(",")
	for part in parts:
		var trimmed = part.strip_edges()
		if trimmed.is_empty():
			continue

		_process_single_downside(trimmed, gremlin)

# Process a single downside effect
static func _process_single_downside(downside: String, gremlin: Gremlin) -> void:
	# Parse key=value
	var parts = downside.split("=")
	if parts.size() != 2:
		push_warning("Invalid downside format: " + downside)
		return

	var downside_type = parts[0].strip_edges()
	var value_str = parts[1].strip_edges()

	# Special handling for ticks (timing)
	if downside_type == "ticks":
		var ticks = int(value_str)
		if ticks == 0:
			# Immediate/passive effect
			gremlin.disruption_interval_beats = -1  # No periodic disruption
		else:
			# Set disruption interval
			gremlin.disruption_interval_beats = ticks * 10  # Convert to beats
			gremlin.beats_until_disruption = gremlin.disruption_interval_beats
		return

	# Parse the value
	var value = _parse_value(value_str)

	# Apply the downside
	match downside_type:
		# Resource caps (soft = can exceed temporarily, hard = absolute limit)
		"heat_soft_cap", "red_soft_cap":
			_apply_force_cap(GameResource.Type.HEAT, value, false)
		"precision_soft_cap", "white_soft_cap":
			_apply_force_cap(GameResource.Type.PRECISION, value, false)
		"momentum_soft_cap", "green_soft_cap":
			_apply_force_cap(GameResource.Type.MOMENTUM, value, false)
		"balance_soft_cap", "blue_soft_cap":
			_apply_force_cap(GameResource.Type.BALANCE, value, false)
		"entropy_soft_cap", "black_soft_cap":
			_apply_force_cap(GameResource.Type.ENTROPY, value, false)

		"heat_hard_cap", "red_hard_cap":
			_apply_force_cap(GameResource.Type.HEAT, value, true)
		"precision_hard_cap", "white_hard_cap":
			_apply_force_cap(GameResource.Type.PRECISION, value, true)
		"momentum_hard_cap", "green_hard_cap":
			_apply_force_cap(GameResource.Type.MOMENTUM, value, true)
		"balance_hard_cap", "blue_hard_cap":
			_apply_force_cap(GameResource.Type.BALANCE, value, true)
		"entropy_hard_cap", "black_hard_cap":
			_apply_force_cap(GameResource.Type.ENTROPY, value, true)

		"max_resource_soft_cap":
			_apply_all_forces_cap(value, false)
		"max_resource_hard_cap":
			_apply_all_forces_cap(value, true)

		# Drains (periodic resource loss)
		"drain_random":
			gremlin.set_meta("drain_type", "random")
			gremlin.set_meta("drain_amount", value)
		"drain_all_types":
			gremlin.set_meta("drain_type", "all")
			gremlin.set_meta("drain_amount", value)
		"drain_heat", "drain_red":
			gremlin.set_meta("drain_type", "heat")
			gremlin.set_meta("drain_amount", value)
		"drain_precision", "drain_white":
			gremlin.set_meta("drain_type", "precision")
			gremlin.set_meta("drain_amount", value)
		"drain_momentum", "drain_green":
			gremlin.set_meta("drain_type", "momentum")
			gremlin.set_meta("drain_amount", value)
		"drain_balance", "drain_blue":
			gremlin.set_meta("drain_type", "balance")
			gremlin.set_meta("drain_amount", value)
		"drain_entropy", "drain_black":
			gremlin.set_meta("drain_type", "entropy")
			gremlin.set_meta("drain_amount", value)

		# Card penalties
		"card_cost_penalty":
			_apply_card_cost_penalty(value)
		"force_discard":
			gremlin.set_meta("force_discard", value)

		# Summons
		"summon":
			gremlin.set_meta("summon_type", value_str)
		
		# Attack moves
		"attack":
			gremlin.set_meta("attack_damage", value)
			gremlin.set_meta("has_attack", true)

		_:
			push_warning("Unknown downside type: " + downside_type)

# Parse value string
static func _parse_value(value_str: String):
	if value_str.is_valid_int():
		return int(value_str)
	elif value_str.is_valid_float():
		return float(value_str)
	else:
		return value_str

# Apply a force cap
static func _apply_force_cap(force_type: GameResource.Type, cap: int, is_hard: bool) -> void:
	var cap_key = _get_force_name(force_type) + ("_hard_cap" if is_hard else "_soft_cap")

	# Track the lowest cap if multiple gremlins apply caps
	if cap_key in active_downsides:
		active_downsides[cap_key] = min(active_downsides[cap_key], cap)
	else:
		active_downsides[cap_key] = cap

	# Apply the cap to the hero's resource
	if GlobalGameManager.hero:
		var resource = GlobalGameManager.hero.get_force_resource(force_type)
		if resource:
			if is_hard:
				# Hard cap - immediately reduce if over
				if resource.amount > cap:
					resource.amount = cap
				resource.max_amount = cap
			else:
				# Soft cap - just set a visual indicator, allow temporary exceeding
				resource.set_meta("soft_cap", cap)

	print("[DEBUG] [Downside] Applied ", cap_key, " = ", cap)

# Apply cap to all forces
static func _apply_all_forces_cap(cap: int, is_hard: bool) -> void:
	var force_types: Array[GameResource.Type] = [
		GameResource.Type.HEAT,
		GameResource.Type.PRECISION,
		GameResource.Type.MOMENTUM,
		GameResource.Type.BALANCE,
		GameResource.Type.ENTROPY
	]

	for force_type in force_types:
		_apply_force_cap(force_type, cap, is_hard)

# Apply card cost penalty
static func _apply_card_cost_penalty(penalty: int) -> void:
	active_downsides["card_cost_penalty"] = active_downsides.get("card_cost_penalty", 0) + penalty
	print("[DEBUG] [Downside] Card cost penalty: +", penalty)

# Get force name for display
static func _get_force_name(force_type: GameResource.Type) -> String:
	match force_type:
		GameResource.Type.HEAT:
			return "heat"
		GameResource.Type.PRECISION:
			return "precision"
		GameResource.Type.MOMENTUM:
			return "momentum"
		GameResource.Type.BALANCE:
			return "balance"
		GameResource.Type.ENTROPY:
			return "entropy"
		_:
			return "unknown"

# Execute disruption effects when triggered
static func trigger_disruption(gremlin: Gremlin) -> void:
	# Check for drain effects
	if gremlin.has_meta("drain_type"):
		var drain_type = gremlin.get_meta("drain_type")
		var drain_amount = gremlin.get_meta("drain_amount", 1)
		_execute_drain(drain_type, drain_amount)

	# Check for force discard
	if gremlin.has_meta("force_discard"):
		var discard_count = gremlin.get_meta("force_discard", 1)
		_force_discard_cards(discard_count)

	# Check for summons
	if gremlin.has_meta("summon_type"):
		var summon_type = gremlin.get_meta("summon_type")
		_summon_gremlin(summon_type)
	
	# Check for attack damage
	if gremlin.has_meta("has_attack") and gremlin.get_meta("has_attack"):
		var damage = gremlin.get_meta("attack_damage", 1)
		_execute_attack(damage)

# Execute drain effect
static func _execute_drain(drain_type: String, amount: int) -> void:
	if not GlobalGameManager.hero:
		return

	match drain_type:
		"random":
			# Drain from a random force that has resources
			var available_forces: Array[GameResource.Type] = []
			var force_types: Array[GameResource.Type] = [
				GameResource.Type.HEAT,
				GameResource.Type.PRECISION,
				GameResource.Type.MOMENTUM,
				GameResource.Type.BALANCE,
				GameResource.Type.ENTROPY
			]

			for force_type in force_types:
				var resource = GlobalGameManager.hero.get_force_resource(force_type)
				if resource and resource.amount > 0:
					available_forces.append(force_type)

			if available_forces.size() > 0:
				var chosen = available_forces.pick_random()
				var resource = GlobalGameManager.hero.get_force_resource(chosen)
				resource.decrement(amount)
				print("[DEBUG] [Disruption] Drained ", amount, " ", _get_force_name(chosen))

		"all":
			# Drain from all forces
			var force_types: Array[GameResource.Type] = [
				GameResource.Type.HEAT,
				GameResource.Type.PRECISION,
				GameResource.Type.MOMENTUM,
				GameResource.Type.BALANCE,
				GameResource.Type.ENTROPY
			]

			for force_type in force_types:
				var resource = GlobalGameManager.hero.get_force_resource(force_type)
				if resource and resource.amount > 0:
					resource.decrement(min(amount, resource.amount))
			print("[DEBUG] [Disruption] Drained ", amount, " from all forces")

		"heat", "precision", "momentum", "balance", "entropy":
			# Drain specific force
			var force_type = _get_force_type_from_name(drain_type)
			if force_type != null:
				var resource = GlobalGameManager.hero.get_force_resource(force_type)
				if resource:
					resource.decrement(min(amount, resource.amount))
					print("[DEBUG] [Disruption] Drained ", amount, " ", drain_type)

# Get force type from name
static func _get_force_type_from_name(name: String) -> GameResource.Type:
	match name:
		"heat":
			return GameResource.Type.HEAT
		"precision":
			return GameResource.Type.PRECISION
		"momentum":
			return GameResource.Type.MOMENTUM
		"balance":
			return GameResource.Type.BALANCE
		"entropy":
			return GameResource.Type.ENTROPY
		_:
			return GameResource.Type.HEAT  # Default

# Force discard cards
static func _force_discard_cards(count: int) -> void:
	# TODO: Implement forced discard UI
	print("[DEBUG] [Disruption] Force discard ", count, " cards")

	# For now, discard random cards from hand
	if GlobalGameManager.library:
		for i in count:
			#GlobalGameManager.library.discard_random_card()

# Summon a gremlin
static func _summon_gremlin(summon_type: String) -> void:
	print("[DEBUG] [Disruption] Summon gremlin: ", summon_type)
	# This will call back to spawn logic
	# TODO: Implement summon logic

# Execute attack damage on hero
static func _execute_attack(damage: int) -> void:
	if not GlobalGameManager.hero:
		return
	
	print("[DEBUG] [Disruption] Gremlin attacks for ", damage, " damage")
	
	# Deal damage to the hero
	var hero = GlobalGameManager.hero
	if hero.hp:
		hero.hp.decrement(damage)
		GlobalSignals.signal_core_hero_damaged(damage)

# Remove a gremlin's downsides when defeated
static func remove_gremlin_downsides(gremlin: Gremlin) -> void:
	# For now, we'd need to track which gremlin applied which downside
	# This is a simplified version - in production, track per-gremlin downsides

	# Recalculate all downsides from remaining gremlins
	recalculate_all_downsides()

# Recalculate downsides from all active gremlins
static func recalculate_all_downsides() -> void:
	# Clear current downsides
	active_downsides.clear()

	# Reset hero resource caps
	if GlobalGameManager.hero:
		var force_types: Array[GameResource.Type] = [
			GameResource.Type.HEAT,
			GameResource.Type.PRECISION,
			GameResource.Type.MOMENTUM,
			GameResource.Type.BALANCE,
			GameResource.Type.ENTROPY
		]

		for force_type in force_types:
			var resource = GlobalGameManager.hero.get_force_resource(force_type)
			if resource:
				resource.max_amount = 99  # Reset to default max
				resource.remove_meta("soft_cap")

	# TODO: Re-apply downsides from all active gremlins
	# This requires accessing the gremlin manager to get all active gremlins

# Get description of a gremlin's downsides for UI
static func get_downside_description(moves_string: String) -> String:
	if moves_string.is_empty():
		return "No special effects"

	var descriptions: Array[String] = []
	var parts = moves_string.split(",")

	for part in parts:
		var trimmed = part.strip_edges()
		if trimmed.is_empty():
			continue

		var kv = trimmed.split("=")
		if kv.size() != 2:
			continue

		var type = kv[0]
		var value = kv[1]

		match type:
			"ticks":
				continue  # Don't show timing
			"heat_soft_cap", "red_soft_cap":
				descriptions.append("Heat cap: " + value)
			"precision_soft_cap", "white_soft_cap":
				descriptions.append("Precision cap: " + value)
			"momentum_soft_cap", "green_soft_cap":
				descriptions.append("Momentum cap: " + value)
			"balance_soft_cap", "blue_soft_cap":
				descriptions.append("Balance cap: " + value)
			"entropy_soft_cap", "black_soft_cap":
				descriptions.append("Entropy cap: " + value)
			"max_resource_soft_cap":
				descriptions.append("All forces cap: " + value)
			"heat_hard_cap", "red_hard_cap":
				descriptions.append("Heat HARD cap: " + value)
			"precision_hard_cap", "white_hard_cap":
				descriptions.append("Precision HARD cap: " + value)
			"drain_random":
				descriptions.append("Drains " + value + " random")
			"drain_all_types":
				descriptions.append("Drains " + value + " all")
			"card_cost_penalty":
				descriptions.append("Cards cost +" + value)
			"force_discard":
				descriptions.append("Discard " + value + " cards")
			"summon":
				descriptions.append("Summons " + value)
			"attack":
				descriptions.append("Attack: " + value + " damage")

	if descriptions.is_empty():
		return "No special effects"

	return ", ".join(descriptions)
