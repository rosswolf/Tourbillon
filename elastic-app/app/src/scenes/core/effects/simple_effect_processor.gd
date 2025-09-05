extends Node
class_name SimpleEffectProcessor

## Processes simple key=value effect strings for Tourbillon cards
## Complex effects are handled as special cases with complex_* prefix

# Process a comma-separated list of effects
static func process_effects(effect_string: String, source: Node = null) -> void:
	if effect_string.is_empty():
		return

	var effects: Array[String] = []
	for e in effect_string.split(","):
		effects.append(e.strip_edges())

	for effect in effects:
		if effect.is_empty():
			continue
		_process_single_effect(effect, source)

# Process a single effect
static func _process_single_effect(effect: String, source: Node) -> void:
	# Check for complex effects first
	if effect.begins_with("complex_"):
		_process_complex_effect(effect, source)
		return

	# Parse simple key=value
	var parts: Array[String] = []
	for p in effect.split("="):
		parts.append(p.strip_edges())

	if parts.size() != 2:
		push_warning("Invalid effect format: " + effect)
		return

	var effect_type: String = parts[0]
	var value: float = parts[1].to_float()

	# Route to appropriate handler
	match effect_type:
		# Card effects
		"draw":
			_handle_draw(int(value))
		"discard":
			_handle_discard(int(value))
		"mill":
			_handle_mill(int(value))

		# Generate force effects (no cost) - support both generate_ and add_ prefixes
		"generate_red", "add_red":
			_handle_generate_force(GameResource.Type.RED, value)
		"generate_blue", "add_blue":
			_handle_generate_force(GameResource.Type.BLUE, value)
		"generate_green", "add_green":
			_handle_generate_force(GameResource.Type.GREEN, value)
		"generate_white", "add_white":
			_handle_generate_force(GameResource.Type.WHITE, value)
		"generate_purple", "generate_black", "add_purple", "add_black":
			_handle_generate_force(GameResource.Type.PURPLE, value)

		# Special forces generation
		"generate_heat", "add_heat":
			_handle_generate_force(GameResource.Type.HEAT, value)
		"generate_precision", "add_precision":
			_handle_generate_force(GameResource.Type.PRECISION, value)
		"generate_momentum", "add_momentum":
			_handle_generate_force(GameResource.Type.MOMENTUM, value)
		"generate_balance", "add_balance":
			_handle_generate_force(GameResource.Type.BALANCE, value)
		"generate_entropy", "add_entropy":
			_handle_generate_force(GameResource.Type.ENTROPY, value)

		# Damage effects with targeting
		"damage", "damage_top":
			_handle_damage(value)
		"damage_all":
			_handle_damage_all(value)
		"damage_random":
			_handle_damage_random(value)
		"damage_weakest":
			_handle_damage_weakest(value)
		"damage_strongest":
			_handle_damage_strongest(value)
		"damage_bottom":
			_handle_damage_bottom(value)
		
		# Pierce damage effects (ignores armor)
		"pierce_damage", "pierce_damage_top":
			_handle_pierce_damage(value)
		"pierce_damage_all":
			_handle_pierce_damage_all(value)
		"pierce_damage_random":
			_handle_pierce_damage_random(value)
		"pierce_damage_weakest":
			_handle_pierce_damage_weakest(value)
		"pierce_damage_strongest":
			_handle_pierce_damage_strongest(value)
		"pierce_damage_bottom":
			_handle_pierce_damage_bottom(value)
		
		# Pop damage effects (double vs shields)
		"pop_damage", "pop_damage_top":
			_handle_pop_damage(value)
		"pop_damage_all":
			_handle_pop_damage_all(value)
		"pop_damage_random":
			_handle_pop_damage_random(value)
		"pop_damage_weakest":
			_handle_pop_damage_weakest(value)
		"pop_damage_strongest":
			_handle_pop_damage_strongest(value)
		"pop_damage_bottom":
			_handle_pop_damage_bottom(value)
		
		# Overkill damage (excess carries to next)
		"overkill_damage":
			_handle_overkill_damage(value)
		
		# Execute effect (instant kill below threshold)
		"execute":
			_handle_execute(int(value))
		"execute_all":
			_handle_execute_all(int(value))
		
		# Poison/DOT effects
		"poison":
			_handle_poison(int(value))
		"poison_all":
			_handle_poison_all(int(value))
		"burn":
			_handle_burn(int(value))
		"burn_all":
			_handle_burn_all(int(value))

		# Defensive effects
		"heal", "heal_self":
			_handle_heal(value)
		"shield", "shield_self":
			_handle_shield(value)

		# Consume force effects (these should be checked before firing)
		"consume_red", "pay_red":
			_handle_consume_force(GameResource.Type.RED, value)
		"consume_blue", "pay_blue":
			_handle_consume_force(GameResource.Type.BLUE, value)
		"consume_green", "pay_green":
			_handle_consume_force(GameResource.Type.GREEN, value)
		"consume_white", "pay_white":
			_handle_consume_force(GameResource.Type.WHITE, value)
		"consume_purple", "consume_black", "pay_purple", "pay_black":
			_handle_consume_force(GameResource.Type.PURPLE, value)
		"consume_heat", "pay_heat":
			_handle_consume_force(GameResource.Type.HEAT, value)
		"consume_precision", "pay_precision":
			_handle_consume_force(GameResource.Type.PRECISION, value)
		"consume_momentum", "pay_momentum":
			_handle_consume_force(GameResource.Type.MOMENTUM, value)
		"consume_balance", "pay_balance":
			_handle_consume_force(GameResource.Type.BALANCE, value)
		"consume_entropy", "pay_entropy":
			_handle_consume_force(GameResource.Type.ENTROPY, value)
		"consume_max", "pay_largest", "consume_largest":
			_handle_consume_largest(value)
		"pay_smallest", "consume_smallest":
			_handle_consume_smallest(value)

		# Gremlin constraint effects (caps and limits)
		"heat_soft_cap", "red_soft_cap":
			_handle_force_cap(GameResource.Type.HEAT, int(value), false)
		"precision_soft_cap", "white_soft_cap":
			_handle_force_cap(GameResource.Type.PRECISION, int(value), false)
		"momentum_soft_cap", "green_soft_cap":
			_handle_force_cap(GameResource.Type.MOMENTUM, int(value), false)
		"balance_soft_cap", "blue_soft_cap":
			_handle_force_cap(GameResource.Type.BALANCE, int(value), false)
		"entropy_soft_cap", "purple_soft_cap", "black_soft_cap":
			_handle_force_cap(GameResource.Type.ENTROPY, int(value), false)

		"heat_hard_cap", "red_hard_cap":
			_handle_force_cap(GameResource.Type.HEAT, int(value), true)
		"precision_hard_cap", "white_hard_cap":
			_handle_force_cap(GameResource.Type.PRECISION, int(value), true)
		"momentum_hard_cap", "green_hard_cap":
			_handle_force_cap(GameResource.Type.MOMENTUM, int(value), true)
		"balance_hard_cap", "blue_hard_cap":
			_handle_force_cap(GameResource.Type.BALANCE, int(value), true)
		"entropy_hard_cap", "purple_hard_cap", "black_hard_cap":
			_handle_force_cap(GameResource.Type.ENTROPY, int(value), true)

		"total_forces_cap":
			_handle_total_forces_cap(int(value))
		"hand_limit":
			_handle_hand_limit(int(value))
		"card_tax":
			_handle_card_tax(int(value))

		# Gremlin disruption effects (drains and forced actions)
		"drain_heat", "drain_red":
			_handle_drain_force(GameResource.Type.HEAT, value)
		"drain_precision", "drain_white":
			_handle_drain_force(GameResource.Type.PRECISION, value)
		"drain_momentum", "drain_green":
			_handle_drain_force(GameResource.Type.MOMENTUM, value)
		"drain_balance", "drain_blue":
			_handle_drain_force(GameResource.Type.BALANCE, value)
		"drain_entropy", "drain_purple", "drain_black":
			_handle_drain_force(GameResource.Type.ENTROPY, value)
		"drain_random":
			_handle_drain_random(value)
		"drain_all":
			_handle_drain_all(value)
		"drain_highest":
			_handle_drain_highest(value)

		"force_discard":
			_handle_force_discard(int(value))
		"destroy_gear":
			_handle_destroy_gear(int(value))
		"corrupt_gear":
			_handle_corrupt_gear(int(value))

		# Gremlin combat effects
		"summon":
			_handle_summon(value)
		"gremlin_shield":
			_handle_gremlin_shield(value, source)
		"gremlin_heal":
			_handle_gremlin_heal(value, source)
		"gremlin_armor":
			_handle_gremlin_armor(value, source)
		"enhance_gremlins":
			_handle_enhance_gremlins(value)

		_:
			push_warning("Unknown effect type: " + effect_type)

# Card manipulation handlers
static func _handle_draw(amount: int) -> void:
	if GlobalGameManager.library:
		GlobalGameManager.library.draw_card(amount)

static func _handle_discard(amount: int) -> void:
	if GlobalGameManager.library:
		# TODO: Implement player choice for discard
		push_warning("Discard not fully implemented - needs UI for player choice")

static func _handle_mill(amount: int) -> void:
	if GlobalGameManager.library:
		GlobalGameManager.library.mill_cards(amount)

# Force generation handlers
static func _handle_generate_force(force_type: GameResource.Type, amount: float) -> void:
	if GlobalGameManager.hero:
		GlobalGameManager.hero.add_force(force_type, int(amount))
		print("[DEBUG] Generated ", amount, " of ", GameResource.Type.keys()[force_type])

static func _handle_consume_force(force_type: GameResource.Type, amount: float) -> bool:
	if not GlobalGameManager.hero:
		return false

	if GlobalGameManager.hero.has_force(force_type, int(amount)):
		GlobalGameManager.hero.consume_force(force_type, int(amount))
		return true
	return false

static func _handle_consume_largest(amount: float) -> bool:
	if not GlobalGameManager.hero:
		return false

	# Consume from the highest pool first
	var highest_type: GameResource.Type = GameResource.Type.RED
	var highest_amount: float = 0.0

	# Check all basic forces (not special combined forces)
	for force_type in [GameResource.Type.RED, GameResource.Type.BLUE,
						GameResource.Type.GREEN, GameResource.Type.WHITE,
						GameResource.Type.PURPLE]:
		var resource = GlobalGameManager.hero.get_force_resource(force_type)
		if resource and resource.amount > highest_amount:
			highest_amount = resource.amount
			highest_type = force_type

	if highest_amount >= amount:
		GlobalGameManager.hero.consume_force(highest_type, int(amount))
		return true
	return false

static func _handle_consume_smallest(amount: float) -> bool:
	if not GlobalGameManager.hero:
		return false

	# Consume from the smallest non-zero pool first
	var smallest_type: GameResource.Type = GameResource.Type.RED
	var smallest_amount: float = INF
	var found_any: bool = false

	# Check all basic forces (not special combined forces)
	for force_type in [GameResource.Type.RED, GameResource.Type.BLUE,
						GameResource.Type.GREEN, GameResource.Type.WHITE,
						GameResource.Type.PURPLE]:
		var resource = GlobalGameManager.hero.get_force_resource(force_type)
		if resource and resource.amount > 0 and resource.amount < smallest_amount:
			smallest_amount = resource.amount
			smallest_type = force_type
			found_any = true

	if found_any and smallest_amount >= amount:
		GlobalGameManager.hero.consume_force(smallest_type, int(amount))
		return true
	return false

# Damage handlers - Basic damage
static func _handle_damage(amount: float) -> void:
	# Target top gremlin by default
	var gremlins: Array[Node] = GlobalGameManager.get_active_gremlins()
	if not gremlins.is_empty():
		var target = gremlins[0]
		if target and is_instance_valid(target) and target.has_method("receive_damage"):
			var packet = DamageFactory.create_basic(int(amount))
			target.receive_damage(packet)

static func _handle_damage_all(amount: float) -> void:
	var gremlins: Array[Node] = GlobalGameManager.get_active_gremlins()
	for gremlin in gremlins:
		if gremlin and is_instance_valid(gremlin) and gremlin.has_method("receive_damage"):
			var packet = DamageFactory.create_basic(int(amount))
			gremlin.receive_damage(packet)

static func _handle_damage_random(amount: float) -> void:
	var gremlins: Array[Node] = GlobalGameManager.get_active_gremlins()
	if not gremlins.is_empty():
		var target = gremlins.pick_random()
		if target and is_instance_valid(target) and target.has_method("receive_damage"):
			var packet = DamageFactory.create_basic(int(amount))
			target.receive_damage(packet)

static func _handle_damage_weakest(amount: float) -> void:
	var gremlins: Array[Node] = GlobalGameManager.get_active_gremlins()
	if gremlins.is_empty():
		return

	var weakest = null
	var min_hp: float = INF
	for gremlin in gremlins:
		if gremlin and is_instance_valid(gremlin) and gremlin.has("current_hp"):
			var hp: float = gremlin.current_hp
			if hp < min_hp:
				min_hp = hp
				weakest = gremlin

	if weakest and is_instance_valid(weakest) and weakest.has_method("receive_damage"):
		var packet = DamageFactory.create_basic(int(amount))
		weakest.receive_damage(packet)

static func _handle_damage_strongest(amount: float) -> void:
	var gremlins: Array[Node] = GlobalGameManager.get_active_gremlins()
	if gremlins.is_empty():
		return

	var strongest = null
	var max_hp: float = 0
	for gremlin in gremlins:
		if gremlin and is_instance_valid(gremlin) and gremlin.has("current_hp"):
			var hp: float = gremlin.current_hp
			if hp > max_hp:
				max_hp = hp
				strongest = gremlin

	if strongest and is_instance_valid(strongest) and strongest.has_method("receive_damage"):
		var packet = DamageFactory.create_basic(int(amount))
		strongest.receive_damage(packet)

static func _handle_damage_bottom(amount: float) -> void:
	# Target bottom (last) gremlin
	var gremlins: Array[Node] = GlobalGameManager.get_active_gremlins()
	if not gremlins.is_empty():
		var target = gremlins[-1]
		if target and is_instance_valid(target) and target.has_method("receive_damage"):
			var packet = DamageFactory.create_basic(int(amount))
			target.receive_damage(packet)

static func _handle_poison(amount: int) -> void:
	# Apply poison to top gremlin
	var gremlins: Array[Node] = GlobalGameManager.get_active_gremlins()
	if not gremlins.is_empty():
		var target = gremlins[0]
		if target and is_instance_valid(target) and target.has_method("apply_poison"):
			target.apply_poison(amount)

# Pierce damage handlers (ignores armor)
static func _handle_pierce_damage(amount: float) -> void:
	var gremlins: Array[Node] = GlobalGameManager.get_active_gremlins()
	if not gremlins.is_empty():
		var target = gremlins[0]
		if target and is_instance_valid(target) and target.has_method("receive_damage"):
			var packet = DamageFactory.create(int(amount), ["pierce"])
			target.receive_damage(packet)

static func _handle_pierce_damage_all(amount: float) -> void:
	var gremlins: Array[Node] = GlobalGameManager.get_active_gremlins()
	for gremlin in gremlins:
		if gremlin and is_instance_valid(gremlin) and gremlin.has_method("receive_damage"):
			var packet = DamageFactory.create(int(amount), ["pierce"])
			gremlin.receive_damage(packet)

static func _handle_pierce_damage_random(amount: float) -> void:
	var gremlins: Array[Node] = GlobalGameManager.get_active_gremlins()
	if not gremlins.is_empty():
		var target = gremlins.pick_random()
		if target and is_instance_valid(target) and target.has_method("receive_damage"):
			var packet = DamageFactory.create(int(amount), ["pierce"])
			target.receive_damage(packet)

static func _handle_pierce_damage_weakest(amount: float) -> void:
	var target = _find_weakest_gremlin()
	if target and is_instance_valid(target) and target.has_method("receive_damage"):
		var packet = DamageFactory.create(int(amount), ["pierce"])
		target.receive_damage(packet)

static func _handle_pierce_damage_strongest(amount: float) -> void:
	var target = _find_strongest_gremlin()
	if target and is_instance_valid(target) and target.has_method("receive_damage"):
		var packet = DamageFactory.create(int(amount), ["pierce"])
		target.receive_damage(packet)

static func _handle_pierce_damage_bottom(amount: float) -> void:
	var gremlins: Array[Node] = GlobalGameManager.get_active_gremlins()
	if not gremlins.is_empty():
		var target = gremlins[-1]
		if target.has_method("receive_damage"):
			var packet = DamageFactory.create(int(amount), ["pierce"])
			target.receive_damage(packet)

# Pop damage handlers (double vs shields)
static func _handle_pop_damage(amount: float) -> void:
	var gremlins: Array[Node] = GlobalGameManager.get_active_gremlins()
	if not gremlins.is_empty():
		var target = gremlins[0]
		if target.has_method("receive_damage"):
			var packet = DamageFactory.create(int(amount), ["pop"])
			target.receive_damage(packet)

static func _handle_pop_damage_all(amount: float) -> void:
	var gremlins: Array[Node] = GlobalGameManager.get_active_gremlins()
	for gremlin in gremlins:
		if gremlin.has_method("receive_damage"):
			var packet = DamageFactory.create(int(amount), ["pop"])
			gremlin.receive_damage(packet)

static func _handle_pop_damage_random(amount: float) -> void:
	var gremlins: Array[Node] = GlobalGameManager.get_active_gremlins()
	if not gremlins.is_empty():
		var target = gremlins.pick_random()
		if target.has_method("receive_damage"):
			var packet = DamageFactory.create(int(amount), ["pop"])
			target.receive_damage(packet)

static func _handle_pop_damage_weakest(amount: float) -> void:
	var target = _find_weakest_gremlin()
	if target and target.has_method("receive_damage"):
		var packet = DamageFactory.create(int(amount), ["pop"])
		target.receive_damage(packet)

static func _handle_pop_damage_strongest(amount: float) -> void:
	var target = _find_strongest_gremlin()
	if target and target.has_method("receive_damage"):
		var packet = DamageFactory.create(int(amount), ["pop"])
		target.receive_damage(packet)

static func _handle_pop_damage_bottom(amount: float) -> void:
	var gremlins: Array[Node] = GlobalGameManager.get_active_gremlins()
	if not gremlins.is_empty():
		var target = gremlins[-1]
		if target.has_method("receive_damage"):
			var packet = DamageFactory.create(int(amount), ["pop"])
			target.receive_damage(packet)

# Overkill damage (excess carries to next)
static func _handle_overkill_damage(amount: float) -> void:
	var gremlins: Array[Node] = GlobalGameManager.get_active_gremlins()
	if not gremlins.is_empty():
		var target = gremlins[0]
		if target.has_method("receive_damage"):
			var packet = DamageFactory.create(int(amount), ["overkill"])
			# Note: Overkill logic should be handled by the damage system
			target.receive_damage(packet)

# Execute effects (instant kill below threshold)
static func _handle_execute(threshold: int) -> void:
	var gremlins: Array[Node] = GlobalGameManager.get_active_gremlins()
	if not gremlins.is_empty():
		var target = gremlins[0]
		if target.has_method("can_be_executed") and target.can_be_executed(threshold):
			if target.has_method("execute"):
				target.execute()

static func _handle_execute_all(threshold: int) -> void:
	var gremlins: Array[Node] = GlobalGameManager.get_active_gremlins()
	for gremlin in gremlins:
		if gremlin.has_method("can_be_executed") and gremlin.can_be_executed(threshold):
			if gremlin.has_method("execute"):
				gremlin.execute()

# Poison all effect
static func _handle_poison_all(amount: int) -> void:
	var gremlins: Array[Node] = GlobalGameManager.get_active_gremlins()
	for gremlin in gremlins:
		if gremlin.has_method("apply_poison"):
			gremlin.apply_poison(amount)

# Burn effects (prevent healing)
static func _handle_burn(duration: int) -> void:
	var gremlins: Array[Node] = GlobalGameManager.get_active_gremlins()
	if not gremlins.is_empty():
		var target = gremlins[0]
		if target.has_method("apply_burn"):
			target.apply_burn(duration)

static func _handle_burn_all(duration: int) -> void:
	var gremlins: Array[Node] = GlobalGameManager.get_active_gremlins()
	for gremlin in gremlins:
		if gremlin.has_method("apply_burn"):
			gremlin.apply_burn(duration)

# Helper functions
static func _find_weakest_gremlin() -> Node:
	var gremlins: Array[Node] = GlobalGameManager.get_active_gremlins()
	if gremlins.is_empty():
		return null
	
	var weakest = null
	var min_hp: float = INF
	for gremlin in gremlins:
		if gremlin and is_instance_valid(gremlin) and gremlin.has("current_hp"):
			var hp: float = gremlin.current_hp
			if hp < min_hp:
				min_hp = hp
				weakest = gremlin
	return weakest

static func _find_strongest_gremlin() -> Node:
	var gremlins: Array[Node] = GlobalGameManager.get_active_gremlins()
	if gremlins.is_empty():
		return null
	
	var strongest = null
	var max_hp: float = 0
	for gremlin in gremlins:
		if gremlin and is_instance_valid(gremlin) and gremlin.has("current_hp"):
			var hp: float = gremlin.current_hp
			if hp > max_hp:
				max_hp = hp
				strongest = gremlin
	return strongest

# Defensive handlers
static func _handle_heal(amount: float) -> void:
	if GlobalGameManager.hero and GlobalGameManager.hero.has_method("heal"):
		GlobalGameManager.hero.heal(amount)

static func _handle_shield(amount: float) -> void:
	if GlobalGameManager.hero and GlobalGameManager.hero.has_method("add_shield"):
		GlobalGameManager.hero.add_shield(amount)

# Complex effect handler
static func _process_complex_effect(effect_id: String, source: Node) -> void:
	# Complex effects are implemented as code
	match effect_id:
		"complex_chain_reaction":
			_complex_chain_reaction(source)
		"complex_mega_burst":
			_complex_mega_burst(source)
		"complex_sacrifice_draw":
			_complex_sacrifice_draw(source)
		"complex_force_cascade":
			_complex_force_cascade(source)
		# Conditional effects from spreadsheet
		"complex_micro_synergy":
			_complex_micro_synergy(source)
		"complex_beast_pack":
			_complex_beast_pack(source)
		"complex_heat_threshold":
			_complex_heat_threshold(source)
		# Cost modifier effects
		"complex_tool_discount":
			_complex_tool_discount(source)
		"complex_micro_haste":
			_complex_micro_haste(source)
		"complex_next_free":
			_complex_next_free(source)

		# Tag synergy effects
		"complex_order_line":
			_complex_order_line(source)
		"complex_chaos_isolation":
			_complex_chaos_isolation(source)
		"complex_forge_support":
			_complex_forge_support(source)
		"complex_void_hunger":
			_complex_void_hunger(source)
		"complex_crystal_focus":
			_complex_crystal_focus(source)
		"complex_shadow_stealth":
			_complex_shadow_stealth(source)
		"complex_arcane_ritual":
			_complex_arcane_ritual(source)
		"complex_mech_automation":
			_complex_mech_automation(source)

		# Threshold effects
		"complex_overheat":
			_complex_overheat(source)
		"complex_precision_strike":
			_complex_precision_strike(source)
		"complex_momentum_avalanche":
			_complex_momentum_avalanche(source)
		"complex_perfect_balance":
			_complex_perfect_balance(source)
		"complex_entropy_cascade":
			_complex_entropy_cascade(source)

		# Position-based effects
		"complex_adjacent_trigger":
			_complex_adjacent_trigger(source)
		"complex_row_production":
			_complex_row_production(source)
		"complex_column_shield":
			_complex_column_shield(source)
		"complex_diagonal_damage":
			_complex_diagonal_damage(source)

		# Sacrifice effects
		"complex_sacrifice_power":
			_complex_sacrifice_power(source)
		"complex_discard_damage":
			_complex_discard_damage(source)
		"complex_destroy_draw":
			_complex_destroy_draw(source)

		# Scaling effects
		"complex_force_scaling":
			_complex_force_scaling(source)
		"complex_card_scaling":
			_complex_card_scaling(source)
		"complex_gear_scaling":
			_complex_gear_scaling(source)

		# Combo effects
		"complex_red_blue_combo":
			_complex_red_blue_combo(source)
		"complex_white_purple_combo":
			_complex_white_purple_combo(source)
		"complex_rainbow_burst":
			_complex_rainbow_burst(source)

		_:
			push_warning("Unknown complex effect: " + effect_id)

# Example complex effects
static func _complex_chain_reaction(source: Node) -> void:
	# Trigger all adjacent gears
	if source and source.has_method("get_grid_position"):
		var pos: Vector2i = source.get_grid_position()
		var adjacent_positions: Array[Vector2i] = [
			pos + Vector2i.UP, pos + Vector2i.DOWN,
			pos + Vector2i.LEFT, pos + Vector2i.RIGHT
		]
		for adj_pos in adjacent_positions:
			if GlobalGameManager.mainplate:
				var gear = GlobalGameManager.mainplate.get_gear_at(adj_pos)
				if gear and gear.has_method("trigger_production"):
					gear.trigger_production()

static func _complex_mega_burst(_source: Node) -> void:
	# Generate 3 of each basic force
	for force_type in [GameResource.Type.RED, GameResource.Type.BLUE,
						GameResource.Type.GREEN, GameResource.Type.WHITE,
						GameResource.Type.PURPLE]:
		_handle_generate_force(force_type, 3.0)

static func _complex_sacrifice_draw(_source: Node) -> void:
	# Destroy a random gear to draw 3 cards
	if GlobalGameManager.mainplate:
		var all_gears: Array[Node] = GlobalGameManager.mainplate.get_all_gears()
		if not all_gears.is_empty():
			var sacrifice = all_gears.pick_random()
			GlobalGameManager.mainplate.remove_gear(sacrifice)
			_handle_draw(3)

static func _complex_force_cascade(_source: Node) -> void:
	# Convert all forces to damage (1:1 ratio)
	if not GlobalGameManager.hero:
		return

	var total_damage: float = 0.0
	for force_type in [GameResource.Type.RED, GameResource.Type.BLUE,
						GameResource.Type.GREEN, GameResource.Type.WHITE,
						GameResource.Type.PURPLE]:
		var resource = GlobalGameManager.hero.get_force_resource(force_type)
		if resource and resource.amount > 0:
			total_damage += resource.amount
			resource.amount = 0  # Clear the resource

	if total_damage > 0:
		_handle_damage_all(total_damage)

# Conditional complex effects (replaces string-based conditionals)
static func _complex_micro_synergy(_source: Node) -> void:
	# "If 3+ MICRO gears, deal 7 damage"
	if not GlobalGameManager.mainplate:
		return

	var micro_count: int = 0
	var all_gears: Array[Node] = GlobalGameManager.mainplate.get_all_gears()
	for gear in all_gears:
		if gear.has_method("has_tag") and gear.has_tag("MICRO"):
			micro_count += 1

	if micro_count >= 3:
		_handle_damage(7)

static func _complex_beast_pack(_source: Node) -> void:
	# "Deal 2 damage per BEAST gear"
	if not GlobalGameManager.mainplate:
		return

	var beast_count: int = 0
	var all_gears: Array[Node] = GlobalGameManager.mainplate.get_all_gears()
	for gear in all_gears:
		if gear.has_method("has_tag") and gear.has_tag("BEAST"):
			beast_count += 1

	if beast_count > 0:
		_handle_damage(2 * beast_count)

static func _complex_heat_threshold(_source: Node) -> void:
	# "If Heat > 5, draw 1 card"
	if not GlobalGameManager.hero:
		return

	var resource = GlobalGameManager.hero.get_force_resource(GameResource.Type.HEAT)
	if resource and resource.amount > 5:
		_handle_draw(1)

# Cost modifier complex effects
static func _complex_tool_discount(_source: Node) -> void:
	# "TOOL gears cost -0.5 Ticks"
	# This needs to be a passive effect tracked by the mainplate/card system
	push_warning("Tool discount effect needs passive system implementation")
	# TODO: Implement when passive modifier system exists

static func _complex_micro_haste(_source: Node) -> void:
	# "MICRO gears fire 1 Tick faster"
	# This needs to modify gear intervals
	if not GlobalGameManager.mainplate:
		return

	var all_gears: Array[Node] = GlobalGameManager.mainplate.get_all_gears()
	for gear in all_gears:
		if gear.has_method("has_tag") and gear.has_tag("MICRO"):
			if gear.has_method("modify_interval"):
				gear.modify_interval(-1)  # Reduce interval by 1 tick

static func _complex_next_free(_source: Node) -> void:
	# "Next card costs 0 Ticks"
	# This needs to set a flag that the next card played costs 0
	if GlobalGameManager.has_method("set_next_card_free"):
		GlobalGameManager.set_next_card_free(true)
	else:
		push_warning("Next card free effect needs game manager support")

# Tag synergy complex effects
static func _complex_order_line(source: Node) -> void:
	# "If 3+ ORDER gears form a line, draw 2 cards"
	if not GlobalGameManager.mainplate or not source:
		return

	# Check for horizontal or vertical lines of ORDER gears
	# This is a simplified check - full implementation would check actual lines
	var order_count: int = 0
	var all_gears: Array[Node] = GlobalGameManager.mainplate.get_all_gears()
	for gear in all_gears:
		if gear.has_method("has_tag") and gear.has_tag("ORDER"):
			order_count += 1

	if order_count >= 3:
		_handle_draw(2)

static func _complex_chaos_isolation(source: Node) -> void:
	# "CHAOS gears deal +3 damage if no adjacent gears"
	if not GlobalGameManager.mainplate or not source:
		return

	if source.has_method("get_grid_position"):
		var pos: Vector2i = source.get_grid_position()
		var adjacent_positions: Array[Vector2i] = [
			pos + Vector2i.UP, pos + Vector2i.DOWN,
			pos + Vector2i.LEFT, pos + Vector2i.RIGHT
		]

		var has_adjacent: bool = false
		for adj_pos in adjacent_positions:
			if GlobalGameManager.mainplate.get_gear_at(adj_pos) != null:
				has_adjacent = true
				break

		if not has_adjacent and source.has_method("has_tag") and source.has_tag("CHAOS"):
			_handle_damage(3)

static func _complex_forge_support(source: Node) -> void:
	# "Other gears in same row produce +1"
	if not GlobalGameManager.mainplate or not source:
		return

	if source.has_method("get_grid_position"):
		var pos: Vector2i = source.get_grid_position()
		var all_gears: Array[Node] = GlobalGameManager.mainplate.get_all_gears()

		for gear in all_gears:
			if gear != source and gear.has_method("get_grid_position"):
				var gear_pos: Vector2i = gear.get_grid_position()
				if gear_pos.y == pos.y:  # Same row
					if gear.has_method("bonus_production"):
						gear.bonus_production(1)

static func _complex_void_hunger(_source: Node) -> void:
	# "Consume 5 any forces → 7 damage"
	var total_consumed: float = 0.0

	if not GlobalGameManager.hero:
		return

	# Try to consume 5 forces from any pools
	for force_type in [GameResource.Type.RED, GameResource.Type.BLUE,
						GameResource.Type.GREEN, GameResource.Type.WHITE,
						GameResource.Type.PURPLE]:
		var resource = GlobalGameManager.hero.get_force_resource(force_type)
		if resource:
			var to_consume: int = min(resource.amount, int(5.0 - total_consumed))

			if to_consume > 0:
				GlobalGameManager.hero.consume_force(force_type, to_consume)
				total_consumed += to_consume

		if total_consumed >= 5.0:
			break

	if total_consumed >= 5.0:
		_handle_damage(7)

static func _complex_crystal_focus(_source: Node) -> void:
	# "CRYSTAL gears: Double Precision production"
	if not GlobalGameManager.mainplate:
		return

	var all_gears: Array[Node] = GlobalGameManager.mainplate.get_all_gears()
	for gear in all_gears:
		if gear.has_method("has_tag") and gear.has_tag("CRYSTAL"):
			# Generate bonus precision equal to current production
			_handle_generate_force(GameResource.Type.PRECISION, 2)

static func _complex_shadow_stealth(_source: Node) -> void:
	# "SHADOW gears: Gremlins can't target you next turn"
	# This needs a buff/debuff system
	push_warning("Shadow stealth effect needs buff system implementation")

static func _complex_arcane_ritual(_source: Node) -> void:
	# "ARCANE gears: If 3+, trigger all gears once"
	if not GlobalGameManager.mainplate:
		return

	var arcane_count: int = 0
	var all_gears: Array[Node] = GlobalGameManager.mainplate.get_all_gears()

	for gear in all_gears:
		if gear.has_method("has_tag") and gear.has_tag("ARCANE"):
			arcane_count += 1

	if arcane_count >= 3:
		for gear in all_gears:
			if gear.has_method("trigger_production"):
				gear.trigger_production()

static func _complex_mech_automation(_source: Node) -> void:
	# "MECH gears: Produce without consuming this turn"
	if not GlobalGameManager.mainplate:
		return

	var all_gears: Array[Node] = GlobalGameManager.mainplate.get_all_gears()
	for gear in all_gears:
		if gear.has_method("has_tag") and gear.has_tag("MECH"):
			if gear.has_method("set_free_production"):
				gear.set_free_production(true)

# Threshold complex effects
static func _complex_overheat(_source: Node) -> void:
	# "If Heat >= 10: Deal 15 damage, lose all Heat"
	if not GlobalGameManager.hero:
		return

	var resource = GlobalGameManager.hero.get_force_resource(GameResource.Type.RED)
	if resource and resource.amount >= 10:
		_handle_damage(15)
		resource.amount = 0

static func _complex_precision_strike(_source: Node) -> void:
	# "If Precision >= 7: Deal damage equal to Precision to weakest"
	if not GlobalGameManager.hero:
		return

	var resource = GlobalGameManager.hero.get_force_resource(GameResource.Type.BLUE)
	if resource and resource.amount >= 7:
		_handle_damage_weakest(resource.amount)

static func _complex_momentum_avalanche(_source: Node) -> void:
	# "If Momentum >= 8: Double all Momentum, deal that much damage"
	if not GlobalGameManager.hero:
		return

	var resource = GlobalGameManager.hero.get_force_resource(GameResource.Type.GREEN)
	if resource and resource.amount >= 8:
		var damage_amount = resource.amount * 2
		resource.amount = damage_amount  # Double the momentum
		_handle_damage(damage_amount)

static func _complex_perfect_balance(_source: Node) -> void:
	# "If all forces equal and > 0: Draw 3, shield 5"
	if not GlobalGameManager.hero:
		return

	var red_res = GlobalGameManager.hero.get_force_resource(GameResource.Type.RED)
	var blue_res = GlobalGameManager.hero.get_force_resource(GameResource.Type.BLUE)
	var green_res = GlobalGameManager.hero.get_force_resource(GameResource.Type.GREEN)
	var white_res = GlobalGameManager.hero.get_force_resource(GameResource.Type.WHITE)
	var purple_res = GlobalGameManager.hero.get_force_resource(GameResource.Type.PURPLE)

	if red_res and blue_res and green_res and white_res and purple_res:
		var red = red_res.current
		var blue = blue_res.current
		var green = green_res.current
		var white = white_res.current
		var purple = purple_res.current

		if red > 0 and red == blue and blue == green and green == white and white == purple:
			_handle_draw(3)
			_handle_shield(5)

static func _complex_entropy_cascade(_source: Node) -> void:
	# "If Entropy >= 6: All gears take 1 damage, deal 10 to all enemies"
	if not GlobalGameManager.hero:
		return

	var resource = GlobalGameManager.hero.get_force_resource(GameResource.Type.PURPLE)
	if resource and resource.amount >= 6:
		# Damage all enemies
		_handle_damage_all(10)

# Position-based complex effects
static func _complex_adjacent_trigger(source: Node) -> void:
	# "Trigger all adjacent gears"
	if not GlobalGameManager.mainplate or not source:
		return

	if source.has_method("get_grid_position"):
		var pos: Vector2i = source.get_grid_position()
		var adjacent_positions: Array[Vector2i] = [
			pos + Vector2i.UP, pos + Vector2i.DOWN,
			pos + Vector2i.LEFT, pos + Vector2i.RIGHT
		]

		for adj_pos in adjacent_positions:
			var gear = GlobalGameManager.mainplate.get_gear_at(adj_pos)
			if gear and gear.has_method("trigger_production"):
				gear.trigger_production()

static func _complex_row_production(source: Node) -> void:
	# "All gears in this row produce immediately"
	if not GlobalGameManager.mainplate or not source:
		return

	if source.has_method("get_grid_position"):
		var pos: Vector2i = source.get_grid_position()
		var all_gears: Array[Node] = GlobalGameManager.mainplate.get_all_gears()

		for gear in all_gears:
			if gear.has_method("get_grid_position"):
				var gear_pos: Vector2i = gear.get_grid_position()
				if gear_pos.y == pos.y:  # Same row
					if gear.has_method("trigger_production"):
						gear.trigger_production()

static func _complex_column_shield(source: Node) -> void:
	# "All gears in this column gain shield"
	if not GlobalGameManager.mainplate or not source:
		return

	if source.has_method("get_grid_position"):
		var pos: Vector2i = source.get_grid_position()
		var all_gears: Array[Node] = GlobalGameManager.mainplate.get_all_gears()

		var column_count: int = 0
		for gear in all_gears:
			if gear.has_method("get_grid_position"):
				var gear_pos: Vector2i = gear.get_grid_position()
				if gear_pos.x == pos.x:  # Same column
					column_count += 1

		# Shield player based on column gear count
		_handle_shield(column_count * 2)

static func _complex_diagonal_damage(source: Node) -> void:
	# "Deal 3 damage per gear on diagonals from this"
	if not GlobalGameManager.mainplate or not source:
		return

	if source.has_method("get_grid_position"):
		var pos: Vector2i = source.get_grid_position()
		var diagonal_positions: Array[Vector2i] = [
			pos + Vector2i(1, 1), pos + Vector2i(1, -1),
			pos + Vector2i(-1, 1), pos + Vector2i(-1, -1)
		]

		var diagonal_count: int = 0
		for diag_pos in diagonal_positions:
			if GlobalGameManager.mainplate.get_gear_at(diag_pos) != null:
				diagonal_count += 1

		if diagonal_count > 0:
			_handle_damage(diagonal_count * 3)

# Sacrifice complex effects
static func _complex_sacrifice_power(source: Node) -> void:
	# "Destroy this gear: Deal 10 damage"
	if source and GlobalGameManager.mainplate:
		GlobalGameManager.mainplate.remove_gear(source)
		_handle_damage(10)

static func _complex_discard_damage(_source: Node) -> void:
	# "Discard 2 cards: Deal 8 damage"
	# This needs UI for player choice
	push_warning("Discard damage effect needs UI implementation")
	# For now, just deal damage if hand has 2+ cards
	if GlobalGameManager.library:
		var hand_size: int = GlobalGameManager.library.get_hand_size()
		if hand_size >= 2:
			# Would need player to choose 2 cards
			_handle_damage(8)

static func _complex_destroy_draw(source: Node) -> void:
	# "Destroy a gear: Draw cards equal to its interval"
	if not GlobalGameManager.mainplate:
		return

	var all_gears: Array[Node] = GlobalGameManager.mainplate.get_all_gears()
	if all_gears.size() > 1:  # Don't destroy last gear
		# For now, destroy random gear (should be player choice)
		var target = all_gears.pick_random()
		if target != source and target.has_method("get_interval"):
			var interval: int = target.get_interval()
			GlobalGameManager.mainplate.remove_gear(target)
			_handle_draw(interval)

# Scaling complex effects
static func _complex_force_scaling(_source: Node) -> void:
	# "Deal damage equal to total forces"
	if not GlobalGameManager.hero:
		return

	var total: float = 0.0
	for force_type in [GameResource.Type.RED, GameResource.Type.BLUE,
						GameResource.Type.GREEN, GameResource.Type.WHITE,
						GameResource.Type.PURPLE]:
		var resource = GlobalGameManager.hero.get_force_resource(force_type)
		if resource:
			total += resource.amount

	if total > 0:
		_handle_damage(total)

static func _complex_card_scaling(_source: Node) -> void:
	# "Deal damage equal to cards in hand"
	if GlobalGameManager.library:
		var hand_size: int = GlobalGameManager.library.get_hand_size()
		if hand_size > 0:
			_handle_damage(hand_size * 2)

static func _complex_gear_scaling(_source: Node) -> void:
	# "Produce 1 of each force per gear on mainplate"
	if not GlobalGameManager.mainplate:
		return

	var gear_count: int = GlobalGameManager.mainplate.get_all_gears().size()
	if gear_count > 0:
		for force_type in [GameResource.Type.RED, GameResource.Type.BLUE,
							GameResource.Type.GREEN, GameResource.Type.WHITE,
							GameResource.Type.PURPLE]:
			_handle_generate_force(force_type, gear_count)

# Combo complex effects
static func _complex_red_blue_combo(_source: Node) -> void:
	# "If Red + Blue >= 10: Create HEAT, deal 12 pierce damage"
	if not GlobalGameManager.hero:
		return

	var red_res = GlobalGameManager.hero.get_force_resource(GameResource.Type.RED)
	var blue_res = GlobalGameManager.hero.get_force_resource(GameResource.Type.BLUE)

	if red_res and blue_res:
		var red = red_res.current
		var blue = blue_res.current

		if red + blue >= 10:
			# Consume to create HEAT
			var to_consume: int = min(red, blue, 5)
			GlobalGameManager.hero.consume_force(GameResource.Type.RED, to_consume)
			GlobalGameManager.hero.consume_force(GameResource.Type.BLUE, to_consume)
			_handle_generate_force(GameResource.Type.HEAT, to_consume)
			# Pierce damage (would need pierce flag)
			_handle_damage(12)

static func _complex_white_purple_combo(_source: Node) -> void:
	# "If White + Purple >= 10: Create BALANCE, heal 5, shield 5"
	if not GlobalGameManager.hero:
		return

	var white_res = GlobalGameManager.hero.get_force_resource(GameResource.Type.WHITE)
	var purple_res = GlobalGameManager.hero.get_force_resource(GameResource.Type.PURPLE)

	if white_res and purple_res:
		var white = white_res.current
		var purple = purple_res.current

		if white + purple >= 10:
			var to_consume: int = min(white, purple, 5)
			GlobalGameManager.hero.consume_force(GameResource.Type.WHITE, to_consume)
			GlobalGameManager.hero.consume_force(GameResource.Type.PURPLE, to_consume)
			_handle_generate_force(GameResource.Type.BALANCE, to_consume)
			_handle_heal(5)
			_handle_shield(5)

static func _complex_rainbow_burst(_source: Node) -> void:
	# "If have all 5 force types: Consume all, deal that much to all, draw 5"
	if not GlobalGameManager.hero:
		return

	var has_all: bool = true
	var total: float = 0.0

	for force_type in [GameResource.Type.RED, GameResource.Type.BLUE,
						GameResource.Type.GREEN, GameResource.Type.WHITE,
						GameResource.Type.PURPLE]:
		var resource = GlobalGameManager.hero.get_force_resource(force_type)
		if not resource or resource.amount <= 0:
			has_all = false
			break
		total += resource.amount

	if has_all:
		# Consume all forces
		for force_type in [GameResource.Type.RED, GameResource.Type.BLUE,
							GameResource.Type.GREEN, GameResource.Type.WHITE,
							GameResource.Type.PURPLE]:
			var resource = GlobalGameManager.hero.get_force_resource(force_type)
			if resource:
				resource.amount = 0

		_handle_damage_all(total)
		_handle_draw(5)

# Check if an effect can be satisfied (for consumption effects)
static func can_satisfy_effect(effect_string: String) -> bool:
	if effect_string.is_empty():
		return true

	var effects: Array[String] = []
	for e in effect_string.split(","):
		effects.append(e.strip_edges())

	for effect in effects:
		if effect.begins_with("consume_") or effect.begins_with("pay_"):
			var parts: Array[String] = []
			for p in effect.split("="):
				parts.append(p.strip_edges())

			if parts.size() != 2:
				continue

			var effect_type: String = parts[0]
			var value: float = parts[1].to_float()

			# Check if we can afford the consumption
			match effect_type:
				"consume_red", "pay_red":
					if not GlobalGameManager.hero or not GlobalGameManager.hero.has_force(GameResource.Type.RED, int(value)):
						return false
				"consume_blue", "pay_blue":
					if not GlobalGameManager.hero or not GlobalGameManager.hero.has_force(GameResource.Type.BLUE, int(value)):
						return false
				"consume_green", "pay_green":
					if not GlobalGameManager.hero or not GlobalGameManager.hero.has_force(GameResource.Type.GREEN, int(value)):
						return false
				"consume_white", "pay_white":
					if not GlobalGameManager.hero or not GlobalGameManager.hero.has_force(GameResource.Type.WHITE, int(value)):
						return false
				"consume_purple", "consume_black", "pay_purple", "pay_black":
					if not GlobalGameManager.hero or not GlobalGameManager.hero.has_force(GameResource.Type.PURPLE, int(value)):
						return false
				"consume_heat", "pay_heat":
					if not GlobalGameManager.hero or not GlobalGameManager.hero.has_force(GameResource.Type.HEAT, int(value)):
						return false
				"consume_precision", "pay_precision":
					if not GlobalGameManager.hero or not GlobalGameManager.hero.has_force(GameResource.Type.PRECISION, int(value)):
						return false
				"consume_momentum", "pay_momentum":
					if not GlobalGameManager.hero or not GlobalGameManager.hero.has_force(GameResource.Type.MOMENTUM, int(value)):
						return false
				"consume_balance", "pay_balance":
					if not GlobalGameManager.hero or not GlobalGameManager.hero.has_force(GameResource.Type.BALANCE, int(value)):
						return false
				"consume_entropy", "pay_entropy":
					if not GlobalGameManager.hero or not GlobalGameManager.hero.has_force(GameResource.Type.ENTROPY, int(value)):
						return false
				"consume_max", "pay_largest", "consume_largest":
					if not GlobalGameManager.hero:
						return false
					# Check if any pool has enough
					var highest: float = 0.0
					for force_type in [GameResource.Type.RED, GameResource.Type.BLUE,
										GameResource.Type.GREEN, GameResource.Type.WHITE,
										GameResource.Type.PURPLE]:
						var resource = GlobalGameManager.hero.get_force_resource(force_type)
						if resource and resource.amount > highest:
							highest = resource.amount
					if highest < value:
						return false
				"pay_smallest", "consume_smallest":
					if not GlobalGameManager.hero:
						return false
					# Check if the smallest non-zero pool has enough
					var smallest: float = INF
					var found_any: bool = false
					for force_type in [GameResource.Type.RED, GameResource.Type.BLUE,
										GameResource.Type.GREEN, GameResource.Type.WHITE,
										GameResource.Type.PURPLE]:
						var resource = GlobalGameManager.hero.get_force_resource(force_type)
						if resource and resource.amount > 0 and resource.amount < smallest:
							smallest = resource.amount
							found_any = true
					if not found_any or smallest < value:
						return false

	return true

# ============================================================================
# GREMLIN-SPECIFIC EFFECT HANDLERS
# ============================================================================

# Force cap handlers
static func _handle_force_cap(force_type: GameResource.Type, cap: int, is_hard: bool) -> void:
	if not GlobalGameManager.hero:
		return

	var resource = GlobalGameManager.hero.get_force_resource(force_type)
	if not resource:
		return

	if is_hard:
		# Hard cap - immediately reduce if over and set max
		if resource.amount > cap:
			resource.amount = cap
		resource.max_amount = cap
		print("[DEBUG] [Constraint] Hard cap ", GameResource.Type.keys()[force_type], " at ", cap)
	else:
		# Soft cap - set metadata for UI indication
		resource.set_meta("soft_cap", cap)
		print("[DEBUG] [Constraint] Soft cap ", GameResource.Type.keys()[force_type], " at ", cap)

static func _handle_total_forces_cap(cap: int) -> void:
	if not GlobalGameManager.hero:
		return

	# Apply cap to sum of all forces
	var total: int = 0
	for force_type in [GameResource.Type.HEAT, GameResource.Type.PRECISION,
						GameResource.Type.MOMENTUM, GameResource.Type.BALANCE,
						GameResource.Type.ENTROPY]:
		var resource = GlobalGameManager.hero.get_force_resource(force_type)
		if resource:
			total += resource.amount

	# If over cap, reduce proportionally
	if total > cap:
		var scale: float = float(cap) / float(total)
		for force_type in [GameResource.Type.HEAT, GameResource.Type.PRECISION,
							GameResource.Type.MOMENTUM, GameResource.Type.BALANCE,
							GameResource.Type.ENTROPY]:
			var resource = GlobalGameManager.hero.get_force_resource(force_type)
			if resource:
				resource.amount = int(resource.amount * scale)

	print("[DEBUG] [Constraint] Total forces capped at ", cap)

static func _handle_hand_limit(limit: int) -> void:
	if GlobalGameManager.library:
		GlobalGameManager.library.set_meta("hand_limit", limit)
		print("[DEBUG] [Constraint] Hand limit set to ", limit)

		# Force discard if over limit
		var current_hand: int = GlobalGameManager.library.get_hand_size()
		if current_hand > limit:
			_handle_force_discard(current_hand - limit)

static func _handle_card_tax(tax: int) -> void:
	# Store as metadata for card cost calculation
	if not GlobalGameManager.has_meta("card_tax"):
		GlobalGameManager.set_meta("card_tax", 0)

	var current_tax: int = GlobalGameManager.get_meta("card_tax")
	GlobalGameManager.set_meta("card_tax", current_tax + tax)
	print("[DEBUG] [Constraint] Card tax increased by ", tax)

# Drain handlers
static func _handle_drain_force(force_type: GameResource.Type, amount: float) -> void:
	if not GlobalGameManager.hero:
		return

	var resource = GlobalGameManager.hero.get_force_resource(force_type)
	if resource and resource.amount > 0:
		var drained: float = min(amount, resource.amount)
		resource.decrement(drained)
		print("[DEBUG] [Disruption] Drained ", drained, " ", GameResource.Type.keys()[force_type])

static func _handle_drain_random(amount: float) -> void:
	if not GlobalGameManager.hero:
		return

	# Find forces with resources
	var available_forces: Array[GameResource.Type] = []
	for force_type in [GameResource.Type.HEAT, GameResource.Type.PRECISION,
						GameResource.Type.MOMENTUM, GameResource.Type.BALANCE,
						GameResource.Type.ENTROPY]:
		var resource = GlobalGameManager.hero.get_force_resource(force_type)
		if resource and resource.amount > 0:
			available_forces.append(force_type)

	if not available_forces.is_empty():
		var chosen = available_forces.pick_random()
		_handle_drain_force(chosen, amount)

static func _handle_drain_all(amount: float) -> void:
	if not GlobalGameManager.hero:
		return

	for force_type in [GameResource.Type.HEAT, GameResource.Type.PRECISION,
						GameResource.Type.MOMENTUM, GameResource.Type.BALANCE,
						GameResource.Type.ENTROPY]:
		_handle_drain_force(force_type, amount)

static func _handle_drain_highest(amount: float) -> void:
	if not GlobalGameManager.hero:
		return

	var highest_type: GameResource.Type = GameResource.Type.HEAT
	var highest_amount: float = 0.0

	for force_type in [GameResource.Type.HEAT, GameResource.Type.PRECISION,
						GameResource.Type.MOMENTUM, GameResource.Type.BALANCE,
						GameResource.Type.ENTROPY]:
		var resource = GlobalGameManager.hero.get_force_resource(force_type)
		if resource and resource.amount > highest_amount:
			highest_amount = resource.amount
			highest_type = force_type

	if highest_amount > 0:
		_handle_drain_force(highest_type, amount)

# Forced action handlers
static func _handle_force_discard(count: int) -> void:
	if GlobalGameManager.library:
		print("[DEBUG] [Disruption] Force discard ", count, " cards")
		# For now, discard random cards (should be player choice UI)
		for i in count:
			GlobalGameManager.library.discard_random_card()

static func _handle_destroy_gear(count: int) -> void:
	if not GlobalGameManager.mainplate:
		return

	var gears = GlobalGameManager.mainplate.get_cards_in_order()
	if gears.is_empty():
		return

	print("[DEBUG] [Disruption] Destroy ", count, " gears")
	for i in min(count, gears.size()):
		# Should be player choice, for now random
		var target = gears.pick_random()
		gears.erase(target)
		# Find position and remove
		for pos in GlobalGameManager.mainplate.slots:
			if GlobalGameManager.mainplate.slots[pos] == target:
				GlobalGameManager.mainplate.remove_card(pos)
				break

static func _handle_corrupt_gear(count: int) -> void:
	if not GlobalGameManager.mainplate:
		return

	var gears = GlobalGameManager.mainplate.get_cards_in_order()
	print("[DEBUG] [Disruption] Corrupt ", count, " gears")

	for i in min(count, gears.size()):
		var target = gears.pick_random()
		# Apply corruption (disable production for N ticks)
		target.set_meta("corrupted", true)
		target.set_meta("corruption_duration", 30)  # 3 ticks

# Gremlin combat handlers
static func _handle_summon(summon_type: float) -> void:
	print("[DEBUG] [Gremlin] Summon: ", summon_type)
	# Delegate to gremlin manager
	if GlobalGameManager.has_method("summon_gremlin"):
		GlobalGameManager.summon_gremlin(str(summon_type))

static func _handle_gremlin_shield(amount: float, source: Node) -> void:
	# Shield the gremlin itself
	if source and source.has_method("add_shields"):
		source.add_shields(int(amount))
		print("[DEBUG] [Gremlin] ", source.gremlin_name if source.has("gremlin_name") else "Gremlin", " gains ", amount, " shields")

static func _handle_gremlin_heal(amount: float, source: Node) -> void:
	# Heal the gremlin itself
	if source and source.has_method("heal"):
		source.heal(int(amount))
		print("[DEBUG] [Gremlin] ", source.gremlin_name if source.has("gremlin_name") else "Gremlin", " heals ", amount)

static func _handle_gremlin_armor(amount: float, source: Node) -> void:
	# Add armor to the gremlin
	if source and source.has("armor"):
		source.armor += int(amount)
		print("[DEBUG] [Gremlin] ", source.gremlin_name if source.has("gremlin_name") else "Gremlin", " gains ", amount, " armor")

static func _handle_enhance_gremlins(amount: float) -> void:
	# Enhance all gremlins
	var gremlins: Array[Node] = GlobalGameManager.get_active_gremlins()
	print("[DEBUG] [Gremlin] Enhancing ", gremlins.size(), " gremlins by ", amount)

	for gremlin in gremlins:
		if gremlin.has("armor"):
			gremlin.armor += int(amount)
		if gremlin.has_method("add_shields"):
			gremlin.add_shields(int(amount))
