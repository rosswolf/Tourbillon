extends GremlinAction
class_name AttackAction

# Attack properties
var damage: int = 1
var damage_type: DamageType.Type = DamageType.Type.PHYSICAL
var target_selector: TargetSelector = null
var properties: Array[DamageProperty.Type] = []

# Attack modifiers
var damage_multiplier: float = 1.0
var can_crit: bool = false
var crit_chance: float = 0.1
var crit_multiplier: float = 2.0

func _init():
	action_name = "Attack"
	timing = Timing.EVERY_N_BEATS
	timing_value = 2
	
	# Default to targeting player/hero
	target_selector = TargetSelector.new()
	target_selector.selector_type = TargetSelector.Type.RANDOM

func _execute_action(gremlin: Entity) -> void:
	# Resolve targets
	var targets = TargetingSystem.resolve_targets(target_selector)
	
	if targets.is_empty():
		# No valid targets, attack player directly
		attack_player(gremlin)
	else:
		# Attack resolved targets
		for target in targets:
			attack_target(gremlin, target)

func attack_target(gremlin: Entity, target: Entity) -> void:
	# Create damage packet
	var packet = DamagePacket.new(damage, damage_type)
	packet.source = gremlin
	packet.multipliers = damage_multiplier
	
	# Add properties
	for prop in properties:
		packet.add_property(prop)
	
	# Check for critical hit
	if can_crit and randf() < crit_chance:
		packet.critical = true
		packet.multipliers *= crit_multiplier
	
	# Apply gremlin modifiers
	if gremlin.has_method("modify_outgoing_damage"):
		packet = gremlin.modify_outgoing_damage(packet)
	
	# Calculate and deal damage
	var final_damage = DamageCalculator.calculate_damage(packet, target)
	
	if target.has_method("take_damage"):
		target.take_damage(final_damage, packet)

func attack_player(gremlin: Entity) -> void:
	# Direct player damage
	if GlobalGameManager.has_method("damage_player"):
		var packet = DamagePacket.new(damage, damage_type)
		packet.source = gremlin
		packet.multipliers = damage_multiplier
		GlobalGameManager.damage_player(packet)

func get_description() -> String:
	return "Deal %d %s damage" % [damage, DamageType.get_name(damage_type)]

func get_intent() -> Dictionary:
	var intent = super.get_intent()
	intent["damage"] = damage
	intent["damage_type"] = damage_type
	intent["target"] = TargetSelector.Type.keys()[target_selector.selector_type]
	return intent

# Builder for creating attack actions
class AttackActionBuilder:
	var _action: AttackAction = AttackAction.new()
	
	func with_damage(amount: int, type: DamageType.Type = DamageType.Type.PHYSICAL) -> AttackActionBuilder:
		_action.damage = amount
		_action.damage_type = type
		return self
	
	func with_timing(timing: Timing, value: int = 1) -> AttackActionBuilder:
		_action.timing = timing
		_action.timing_value = value
		return self
	
	func with_target(selector: TargetSelector) -> AttackActionBuilder:
		_action.target_selector = selector
		return self
	
	func with_property(property: DamageProperty.Type) -> AttackActionBuilder:
		_action.properties.append(property)
		return self
	
	func with_crit(chance: float = 0.1, multiplier: float = 2.0) -> AttackActionBuilder:
		_action.can_crit = true
		_action.crit_chance = chance
		_action.crit_multiplier = multiplier
		return self
	
	func build() -> AttackAction:
		return _action