extends Resource
class_name DamagePacket

# Core damage properties
var base_amount: int = 0
var damage_type: DamageType.Type = DamageType.Type.PHYSICAL
var source: Entity = null  # The entity that initiated the damage
var source_position: Vector2i = Vector2i.ZERO

# Damage modifiers
var multipliers: float = 1.0
var flat_bonuses: int = 0
var critical: bool = false

# Damage properties/flags
var properties: Array[DamageProperty.Type] = []

# Defense bypasses
var ignore_shields: bool = false
var ignore_armor: bool = false
var ignore_all_defenses: bool = false

# Chain/splash properties
var can_chain: bool = false
var chain_count: int = 0
var chain_reduction: float = 0.5
var splash_radius: int = 0

# Conditional properties
var execution_threshold: int = 0  # Instant kill if target below this
var lifesteal_percent: float = 0.0  # Heal source by % of damage dealt

# Metadata
var is_retaliation: bool = false  # Damage from a counter-attack
var can_be_reflected: bool = true
var can_trigger_on_hit: bool = true

func _init(amount: int = 0, type: DamageType.Type = DamageType.Type.PHYSICAL):
	base_amount = amount
	damage_type = type

# Calculate final damage amount with all modifiers
func calculate_total() -> int:
	var total = float(base_amount) * multipliers + float(flat_bonuses)
	if critical:
		total *= 2.0
	return max(0, int(total))

# Check if packet has a specific property
func has_property(property: DamageProperty.Type) -> bool:
	return property in properties

# Add a property to the packet
func add_property(property: DamageProperty.Type) -> void:
	if not has_property(property):
		properties.append(property)

# Clone the packet for chain/splash damage
func clone_reduced(reduction: float = 0.5) -> DamagePacket:
	var new_packet = DamagePacket.new()
	new_packet.base_amount = int(base_amount * reduction)
	new_packet.damage_type = damage_type
	new_packet.source = source
	new_packet.multipliers = multipliers
	new_packet.flat_bonuses = int(flat_bonuses * reduction)
	new_packet.properties = properties.duplicate()
	new_packet.ignore_shields = ignore_shields
	new_packet.ignore_armor = ignore_armor
	return new_packet

# Builder pattern for creating damage packets
class DamagePacketBuilder:
	var _packet: DamagePacket = DamagePacket.new()
	
	func with_damage(amount: int, type: DamageType.Type = DamageType.Type.PHYSICAL) -> DamagePacketBuilder:
		_packet.base_amount = amount
		_packet.damage_type = type
		return self
	
	func with_source(entity: Entity) -> DamagePacketBuilder:
		_packet.source = entity
		return self
	
	func with_multiplier(mult: float) -> DamagePacketBuilder:
		_packet.multipliers *= mult
		return self
	
	func with_bonus(bonus: int) -> DamagePacketBuilder:
		_packet.flat_bonuses += bonus
		return self
	
	func with_property(property: DamageProperty.Type) -> DamagePacketBuilder:
		_packet.add_property(property)
		return self
	
	func with_piercing() -> DamagePacketBuilder:
		_packet.ignore_shields = true
		return self
	
	func with_true_damage() -> DamagePacketBuilder:
		_packet.ignore_all_defenses = true
		return self
	
	func with_chain(count: int, reduction: float = 0.5) -> DamagePacketBuilder:
		_packet.can_chain = true
		_packet.chain_count = count
		_packet.chain_reduction = reduction
		return self
	
	func with_lifesteal(percent: float) -> DamagePacketBuilder:
		_packet.lifesteal_percent = percent
		return self
	
	func with_execution(threshold: int) -> DamagePacketBuilder:
		_packet.execution_threshold = threshold
		return self
	
	func build() -> DamagePacket:
		return _packet