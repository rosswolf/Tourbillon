extends GremlinConstraint
class_name DefensiveConstraint

# Defensive properties
var damage_cap: int = -1              # Max damage per hit (-1 = no cap)
var immune_to: Array[DamageType.Type] = []  # Damage type immunities
var resist_types: Dictionary = {}     # Damage type -> resistance %
var general_resistance: float = 0.0   # General damage resistance
var shield_regen_per_tick: int = 0    # Shields regenerated per tick
var armor_stacks: int = 0             # Flat damage reduction
var reflect_percent: float = 0.0      # % of damage reflected back
var dodge_chance: float = 0.0         # Chance to dodge attacks

# Shield properties
var max_shields: int = 0
var shield_decay_per_beat: int = 0    # Shields lost per beat

func _init():
	constraint_name = "Defensive Constraint"

func modify_incoming_damage(damage: int, packet: DamagePacket) -> int:
	# Check immunity
	if packet.damage_type in immune_to:
		return 0
	
	# Check dodge
	if dodge_chance > 0 and randf() < dodge_chance:
		return 0
	
	# Apply type-specific resistance
	if resist_types.has(packet.damage_type):
		damage = int(damage * (1.0 - resist_types[packet.damage_type]))
	
	# Apply general resistance
	damage = int(damage * (1.0 - general_resistance))
	
	# Apply armor (flat reduction)
	damage = max(0, damage - armor_stacks)
	
	# Apply damage cap
	if damage_cap > 0:
		damage = min(damage, damage_cap)
	
	# Handle reflection
	if reflect_percent > 0 and packet.source != null:
		var reflect_damage = int(damage * reflect_percent)
		if packet.source.has_method("take_damage"):
			var reflect_packet = DamagePacket.new(reflect_damage, packet.damage_type)
			reflect_packet.is_retaliation = true
			reflect_packet.source = null  # Prevent infinite reflection
			packet.source.take_damage(reflect_damage, reflect_packet)
	
	return damage

func process_tick(gremlin: Entity, tick: int) -> void:
	# Regenerate shields
	if shield_regen_per_tick > 0 and gremlin.has_method("add_shields"):
		gremlin.add_shields(shield_regen_per_tick)
		if max_shields > 0 and gremlin.has_method("get_shields"):
			var current = gremlin.get_shields()
			if current > max_shields and gremlin.has_method("set_shields"):
				gremlin.set_shields(max_shields)

func process_beat(gremlin: Entity, beat: int) -> void:
	# Shield decay
	if shield_decay_per_beat > 0 and gremlin.has_method("reduce_shields"):
		gremlin.reduce_shields(shield_decay_per_beat)

func get_description() -> String:
	var desc = "Defensive: "
	var parts = []
	
	if armor_stacks > 0:
		parts.append("Armor %d" % armor_stacks)
	if general_resistance > 0:
		parts.append("Resist %.0f%%" % (general_resistance * 100))
	if shield_regen_per_tick > 0:
		parts.append("Shield Regen %d/tick" % shield_regen_per_tick)
	if damage_cap > 0:
		parts.append("Damage Cap %d" % damage_cap)
	if dodge_chance > 0:
		parts.append("Dodge %.0f%%" % (dodge_chance * 100))
	if reflect_percent > 0:
		parts.append("Reflect %.0f%%" % (reflect_percent * 100))
	if not immune_to.is_empty():
		parts.append("Immune to %d types" % immune_to.size())
	
	return desc + ", ".join(parts) if not parts.is_empty() else "No defenses"

# Builder for creating defensive constraints
class DefensiveConstraintBuilder:
	var _constraint: DefensiveConstraint = DefensiveConstraint.new()
	
	func with_armor(stacks: int) -> DefensiveConstraintBuilder:
		_constraint.armor_stacks = stacks
		return self
	
	func with_resistance(percent: float) -> DefensiveConstraintBuilder:
		_constraint.general_resistance = percent
		return self
	
	func with_type_resistance(type: DamageType.Type, percent: float) -> DefensiveConstraintBuilder:
		_constraint.resist_types[type] = percent
		return self
	
	func with_immunity(type: DamageType.Type) -> DefensiveConstraintBuilder:
		_constraint.immune_to.append(type)
		return self
	
	func with_damage_cap(cap: int) -> DefensiveConstraintBuilder:
		_constraint.damage_cap = cap
		return self
	
	func with_shield_regen(amount: int) -> DefensiveConstraintBuilder:
		_constraint.shield_regen_per_tick = amount
		return self
	
	func with_dodge(chance: float) -> DefensiveConstraintBuilder:
		_constraint.dodge_chance = chance
		return self
	
	func with_reflection(percent: float) -> DefensiveConstraintBuilder:
		_constraint.reflect_percent = percent
		return self
	
	func build() -> DefensiveConstraint:
		return _constraint