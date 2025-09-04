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
		"poison":
			_handle_poison(int(value))
		
		# Defensive effects
		"heal", "heal_self":
			_handle_heal(value)
		"shield", "shield_self":
			_handle_shield(value)
		
		# Consume force effects (these should be checked before firing)
		"consume_red":
			_handle_consume_force(GameResource.Type.RED, value)
		"consume_blue":
			_handle_consume_force(GameResource.Type.BLUE, value)
		"consume_green":
			_handle_consume_force(GameResource.Type.GREEN, value)
		"consume_white":
			_handle_consume_force(GameResource.Type.WHITE, value)
		"consume_purple", "consume_black":
			_handle_consume_force(GameResource.Type.PURPLE, value)
		"consume_any":
			_handle_consume_any(value)
		"consume_max":
			_handle_consume_max(value)
		
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
	if GlobalGameManager.resource_manager:
		GlobalGameManager.resource_manager.increment_resource(force_type, amount)
		print("Generated ", amount, " of ", GameResource.Type.keys()[force_type])

static func _handle_consume_force(force_type: GameResource.Type, amount: float) -> bool:
	if not GlobalGameManager.resource_manager:
		return false
	
	if GlobalGameManager.resource_manager.can_afford_cost(force_type, amount):
		GlobalGameManager.resource_manager.decrement_resource(force_type, amount)
		return true
	return false

static func _handle_consume_any(amount: float) -> bool:
	if not GlobalGameManager.resource_manager:
		return false
	
	# Try to consume from any available force pool
	for force_type in [GameResource.Type.RED, GameResource.Type.BLUE, 
						GameResource.Type.GREEN, GameResource.Type.WHITE, 
						GameResource.Type.PURPLE]:
		if GlobalGameManager.resource_manager.can_afford_cost(force_type, amount):
			GlobalGameManager.resource_manager.decrement_resource(force_type, amount)
			return true
	return false

static func _handle_consume_max(amount: float) -> bool:
	if not GlobalGameManager.resource_manager:
		return false
	
	# Consume from the highest pool first
	var highest_type: GameResource.Type = GameResource.Type.RED
	var highest_amount: float = 0.0
	
	for force_type in [GameResource.Type.RED, GameResource.Type.BLUE, 
						GameResource.Type.GREEN, GameResource.Type.WHITE, 
						GameResource.Type.PURPLE]:
		var current: float = GlobalGameManager.resource_manager.get_resource(force_type)
		if current > highest_amount:
			highest_amount = current
			highest_type = force_type
	
	if highest_amount >= amount:
		GlobalGameManager.resource_manager.decrement_resource(highest_type, amount)
		return true
	return false

# Damage handlers
static func _handle_damage(amount: float) -> void:
	# Target top gremlin by default
	var gremlins: Array = GlobalGameManager.get_active_gremlins()
	if not gremlins.is_empty():
		var target = gremlins[0]
		if target.has_method("take_damage"):
			target.take_damage(amount)

static func _handle_damage_all(amount: float) -> void:
	var gremlins: Array = GlobalGameManager.get_active_gremlins()
	for gremlin in gremlins:
		if gremlin.has_method("take_damage"):
			gremlin.take_damage(amount)

static func _handle_damage_random(amount: float) -> void:
	var gremlins: Array = GlobalGameManager.get_active_gremlins()
	if not gremlins.is_empty():
		var target = gremlins.pick_random()
		if target.has_method("take_damage"):
			target.take_damage(amount)

static func _handle_damage_weakest(amount: float) -> void:
	var gremlins: Array = GlobalGameManager.get_active_gremlins()
	if gremlins.is_empty():
		return
	
	var weakest = gremlins[0]
	var min_hp: float = INF
	for gremlin in gremlins:
		if gremlin.has_method("get_current_hp"):
			var hp: float = gremlin.get_current_hp()
			if hp < min_hp:
				min_hp = hp
				weakest = gremlin
	
	if weakest and weakest.has_method("take_damage"):
		weakest.take_damage(amount)

static func _handle_damage_strongest(amount: float) -> void:
	var gremlins: Array = GlobalGameManager.get_active_gremlins()
	if gremlins.is_empty():
		return
	
	var strongest = gremlins[0]
	var max_hp: float = 0
	for gremlin in gremlins:
		if gremlin.has_method("get_current_hp"):
			var hp: float = gremlin.get_current_hp()
			if hp > max_hp:
				max_hp = hp
				strongest = gremlin
	
	if strongest and strongest.has_method("take_damage"):
		strongest.take_damage(amount)

static func _handle_damage_bottom(amount: float) -> void:
	# Target bottom (last) gremlin
	var gremlins: Array = GlobalGameManager.get_active_gremlins()
	if not gremlins.is_empty():
		var target = gremlins[-1]
		if target.has_method("take_damage"):
			target.take_damage(amount)

static func _handle_poison(amount: int) -> void:
	# Apply poison to top gremlin
	var gremlins: Array = GlobalGameManager.get_active_gremlins()
	if not gremlins.is_empty():
		var target = gremlins[0]
		if target.has_method("apply_poison"):
			target.apply_poison(amount)

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
		var all_gears: Array = GlobalGameManager.mainplate.get_all_gears()
		if not all_gears.is_empty():
			var sacrifice = all_gears.pick_random()
			GlobalGameManager.mainplate.remove_gear(sacrifice)
			_handle_draw(3)

static func _complex_force_cascade(_source: Node) -> void:
	# Convert all forces to damage (1:1 ratio)
	if not GlobalGameManager.resource_manager:
		return
	
	var total_damage: float = 0.0
	for force_type in [GameResource.Type.RED, GameResource.Type.BLUE, 
						GameResource.Type.GREEN, GameResource.Type.WHITE, 
						GameResource.Type.PURPLE]:
		var amount: float = GlobalGameManager.resource_manager.get_resource(force_type)
		if amount > 0:
			GlobalGameManager.resource_manager.set_resource(force_type, 0)
			total_damage += amount
	
	if total_damage > 0:
		_handle_damage_all(total_damage)

# Conditional complex effects (replaces string-based conditionals)
static func _complex_micro_synergy(_source: Node) -> void:
	# "If 3+ MICRO gears, deal 7 damage"
	if not GlobalGameManager.mainplate:
		return
	
	var micro_count: int = 0
	var all_gears: Array = GlobalGameManager.mainplate.get_all_gears()
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
	var all_gears: Array = GlobalGameManager.mainplate.get_all_gears()
	for gear in all_gears:
		if gear.has_method("has_tag") and gear.has_tag("BEAST"):
			beast_count += 1
	
	if beast_count > 0:
		_handle_damage(2 * beast_count)

static func _complex_heat_threshold(_source: Node) -> void:
	# "If Heat > 5, draw 1 card"
	if not GlobalGameManager.resource_manager:
		return
	
	var heat: float = GlobalGameManager.resource_manager.get_resource(GameResource.Type.HEAT)
	if heat > 5:
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
	
	var all_gears: Array = GlobalGameManager.mainplate.get_all_gears()
	for gear in all_gears:
		if gear.has_method("has_tag") and gear.has_tag("MICRO"):
			if gear.has_method("modify_interval"):
				gear.modify_interval(-1)  # Reduce interval by 1 tick

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
					if not GlobalGameManager.resource_manager.can_afford_cost(GameResource.Type.RED, value):
						return false
				"consume_blue", "pay_blue":
					if not GlobalGameManager.resource_manager.can_afford_cost(GameResource.Type.BLUE, value):
						return false
				"consume_green", "pay_green":
					if not GlobalGameManager.resource_manager.can_afford_cost(GameResource.Type.GREEN, value):
						return false
				"consume_white", "pay_white":
					if not GlobalGameManager.resource_manager.can_afford_cost(GameResource.Type.WHITE, value):
						return false
				"consume_purple", "consume_black", "pay_purple", "pay_black":
					if not GlobalGameManager.resource_manager.can_afford_cost(GameResource.Type.PURPLE, value):
						return false
				"consume_any", "pay_any":
					var can_afford_any: bool = false
					for force_type in [GameResource.Type.RED, GameResource.Type.BLUE, 
										GameResource.Type.GREEN, GameResource.Type.WHITE, 
										GameResource.Type.PURPLE]:
						if GlobalGameManager.resource_manager.can_afford_cost(force_type, value):
							can_afford_any = true
							break
					if not can_afford_any:
						return false
	
	return true