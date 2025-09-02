extends Node
class_name DamageCalculator

# Signal emitted when damage is calculated
signal damage_calculated(packet: DamagePacket, target: Entity, final_damage: int)
signal damage_blocked(packet: DamagePacket, target: Entity, blocked_amount: int)

# Calculate final damage after all modifiers
static func calculate_damage(packet: DamagePacket, target: Entity) -> int:
	if not packet or not target:
		return 0
	
	# Stage 1: Apply source modifiers (from attacker's gears/buffs)
	packet = apply_source_modifiers(packet)
	
	# Stage 2: Apply global modifiers (field effects, weather, etc)
	packet = apply_global_modifiers(packet)
	
	# Stage 3: Calculate base damage with modifiers
	var damage = packet.calculate_total()
	
	# Stage 4: Apply target defenses
	if not packet.ignore_all_defenses:
		damage = apply_defenses(damage, packet, target)
	
	# Stage 5: Apply vulnerabilities and resistances
	damage = apply_vulnerabilities(damage, packet, target)
	
	# Stage 6: Check for execution
	if packet.execution_threshold > 0 and target.has_method("get_health"):
		if target.get_health() <= packet.execution_threshold:
			damage = 999999  # Instant kill
	
	# Stage 7: Ensure minimum damage (unless fully blocked)
	if damage > 0 and packet.has_property(DamageProperty.Type.UNSTOPPABLE):
		damage = max(1, damage)
	
	return max(0, damage)

# Apply modifiers from the source (attacker)
static func apply_source_modifiers(packet: DamagePacket) -> DamagePacket:
	if not packet.source:
		return packet
	
	# Check for damage amplifiers on source
	if packet.source.has_method("get_damage_multiplier"):
		packet.multipliers *= packet.source.get_damage_multiplier()
	
	# Check for flat damage bonuses
	if packet.source.has_method("get_damage_bonus"):
		packet.flat_bonuses += packet.source.get_damage_bonus()
	
	# Check for critical strike
	if packet.source.has_method("get_crit_chance"):
		if randf() < packet.source.get_crit_chance():
			packet.critical = true
			packet.add_property(DamageProperty.Type.CRITICAL)
	
	return packet

# Apply global modifiers (field effects, etc)
static func apply_global_modifiers(packet: DamagePacket) -> DamagePacket:
	# This would check for global effects like:
	# - "All damage increased by 20%" 
	# - "Fire damage deals +2"
	# - etc.
	
	# Placeholder for global modifier system
	if GlobalGameManager.has_method("get_damage_modifiers"):
		var modifiers = GlobalGameManager.get_damage_modifiers()
		for modifier in modifiers:
			packet = modifier.apply(packet)
	
	return packet

# Apply target's defenses (shields, armor)
static func apply_defenses(damage: int, packet: DamagePacket, target: Entity) -> int:
	var remaining_damage = damage
	
	# Apply shields first (unless piercing)
	if not packet.ignore_shields and not DamageType.ignores_shields(packet.damage_type):
		if target.has_method("get_shields"):
			var shields = target.get_shields()
			if shields > 0:
				remaining_damage = apply_shields(remaining_damage, shields, packet, target)
	
	# Apply armor (unless bypassed)
	if not packet.ignore_armor and not DamageType.ignores_armor(packet.damage_type):
		if target.has_method("get_armor"):
			var armor = target.get_armor()
			if armor > 0:
				remaining_damage = max(0, remaining_damage - armor)
	
	return remaining_damage

# Apply shield interaction
static func apply_shields(damage: int, shield_amount: int, packet: DamagePacket, target: Entity) -> int:
	if packet.has_property(DamageProperty.Type.PIERCING):
		return damage  # Piercing ignores shields completely
	
	if shield_amount >= damage:
		# Shields absorb all damage
		if target.has_method("reduce_shields"):
			target.reduce_shields(damage)
		return 0
	else:
		# Shields absorb what they can
		if target.has_method("reduce_shields"):
			target.reduce_shields(shield_amount)
		
		if packet.has_property(DamageProperty.Type.OVERWHELMING):
			return damage - shield_amount  # Excess carries through
		else:
			return 0  # Shields block all even if depleted

# Apply vulnerabilities and resistances
static func apply_vulnerabilities(damage: int, packet: DamagePacket, target: Entity) -> int:
	if not target.has_method("get_damage_modifier"):
		return damage
	
	var modifier = target.get_damage_modifier(packet.damage_type)
	return int(damage * modifier)

# Process chain damage
static func process_chain_damage(packet: DamagePacket, initial_target: Entity) -> void:
	if not packet.can_chain or packet.chain_count <= 0:
		return
	
	var chained_targets = []
	var current_target = initial_target
	
	for i in packet.chain_count:
		var next_target = find_chain_target(current_target, chained_targets)
		if not next_target:
			break
		
		var chain_packet = packet.clone_reduced(packet.chain_reduction)
		var chain_damage = calculate_damage(chain_packet, next_target)
		
		if next_target.has_method("take_damage"):
			next_target.take_damage(chain_damage, chain_packet)
		
		chained_targets.append(next_target)
		current_target = next_target

# Find next target for chain damage
static func find_chain_target(from_target: Entity, exclude_list: Array) -> Entity:
	# This would use the targeting system to find adjacent/nearby targets
	# Placeholder implementation
	return null

# Process area damage
static func process_area_damage(packet: DamagePacket, center_position: Vector2i, radius: int) -> void:
	if packet.splash_radius <= 0:
		return
	
	# Get all entities in radius
	var targets = []  # Would get from positioning system
	
	for target in targets:
		var distance = (target.position - center_position).length()
		if distance <= radius:
			var falloff = 1.0 - (distance / float(radius)) * 0.5  # 50% falloff at edge
			var area_packet = packet.clone_reduced(falloff)
			var area_damage = calculate_damage(area_packet, target)
			
			if target.has_method("take_damage"):
				target.take_damage(area_damage, area_packet)