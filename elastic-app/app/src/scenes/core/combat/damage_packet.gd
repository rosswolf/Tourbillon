extends Resource
class_name DamagePacket

## Encapsulates all information about a damage instance
## The damage amount is already pre-calculated with force multipliers from card data

# Core properties
@export var amount: int = 0  # Already includes force multipliers
@export var damage_type: DamageType = DamageType.NORMAL
@export var source: Node = null  # Who/what caused this damage

# Damage keywords (from PRD)
@export var pierce: bool = false  # Ignores armor
@export var pop: bool = false  # Double damage vs shields
@export var overkill: bool = false  # Excess carries to next target
@export var true_damage: bool = false  # Cannot be modified by defenses
@export var poison: bool = false  # Is this poison damage?

# Metadata
@export var timestamp_beats: int = 0  # When this damage was created

enum DamageType {
	NORMAL,      # Standard damage
	POISON,      # Damage over time
	REFLECT,     # Reflected damage
	EXECUTE      # Instant kill below threshold
}

## Get final damage amount (no multiplier calculation needed)
func get_damage_amount() -> int:
	return amount

## Create a modified copy of this packet
func with_modifier(property: String, value) -> DamagePacket:
	var new_packet = duplicate(true) as DamagePacket
	new_packet.set(property, value)
	return new_packet

## String representation for debugging
func _to_string() -> String:
	var keywords: Array[String] = []
	if pierce: keywords.append("pierce")
	if pop: keywords.append("pop")
	if overkill: keywords.append("overkill")
	if true_damage: keywords.append("true")
	if poison: keywords.append("poison")
	
	var keyword_str = ""
	if not keywords.is_empty():
		keyword_str = " [" + ", ".join(keywords) + "]"
	
	return "DamagePacket(%d %s%s)" % [amount, DamageType.keys()[damage_type], keyword_str]