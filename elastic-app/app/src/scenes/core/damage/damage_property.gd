extends Resource
class_name DamageProperty

enum Type {
	PIERCING,        # Ignores shields
	OVERWHELMING,    # Excess shield damage carries through
	CHAINING,        # Jumps to adjacent targets
	EXPLOSIVE,       # Hits all enemies in radius
	EXECUTION,       # Instant kill below threshold
	VAMPIRIC,        # Heals attacker
	STUNNING,        # Can stun target
	BURNING,         # Applies burn DoT
	FREEZING,        # Applies freeze/slow
	POISONING,       # Applies poison DoT
	MARKING,         # Marks target for bonus damage
	CLEAVING,        # Hits multiple enemies in arc
	CRITICAL,        # Can critically strike
	UNSTOPPABLE,     # Cannot be reduced below 1
	REFLECTABLE      # Can be reflected back
}

# Get display name for property
static func get_name(property: Type) -> String:
	match property:
		Type.PIERCING: return "Piercing"
		Type.OVERWHELMING: return "Overwhelming"
		Type.CHAINING: return "Chaining"
		Type.EXPLOSIVE: return "Explosive"
		Type.EXECUTION: return "Execution"
		Type.VAMPIRIC: return "Vampiric"
		Type.STUNNING: return "Stunning"
		Type.BURNING: return "Burning"
		Type.FREEZING: return "Freezing"
		Type.POISONING: return "Poisoning"
		Type.MARKING: return "Marking"
		Type.CLEAVING: return "Cleaving"
		Type.CRITICAL: return "Critical"
		Type.UNSTOPPABLE: return "Unstoppable"
		Type.REFLECTABLE: return "Reflectable"
		_: return "Unknown"

# Get icon for property (placeholder paths)
static func get_icon_path(property: Type) -> String:
	match property:
		Type.PIERCING: return "res://assets/icons/piercing.png"
		Type.OVERWHELMING: return "res://assets/icons/overwhelming.png"
		Type.CHAINING: return "res://assets/icons/chaining.png"
		Type.EXPLOSIVE: return "res://assets/icons/explosive.png"
		Type.EXECUTION: return "res://assets/icons/execution.png"
		Type.VAMPIRIC: return "res://assets/icons/vampiric.png"
		Type.STUNNING: return "res://assets/icons/stunning.png"
		Type.BURNING: return "res://assets/icons/burning.png"
		Type.FREEZING: return "res://assets/icons/freezing.png"
		Type.POISONING: return "res://assets/icons/poisoning.png"
		Type.MARKING: return "res://assets/icons/marking.png"
		Type.CLEAVING: return "res://assets/icons/cleaving.png"
		Type.CRITICAL: return "res://assets/icons/critical.png"
		Type.UNSTOPPABLE: return "res://assets/icons/unstoppable.png"
		Type.REFLECTABLE: return "res://assets/icons/reflectable.png"
		_: return ""