extends Resource
class_name DamageType

enum Type {
	PHYSICAL,    # Standard damage, reduced by armor
	# Future damage types - uncomment as needed:
	# ENERGY,      # Bypasses armor, reduced by shields
	# TRUE,        # Ignores all defenses
	# POISON,      # Damage over time, ignores shields
	# FIRE,        # Can spread to adjacent targets
	# ICE,         # Can freeze/slow targets
	# LIGHTNING,   # Can chain between targets
	# HOLY,        # Extra damage to undead/demons
	# DARK,        # Lifesteal potential
	# PSYCHIC      # Bypasses physical defenses
}

# Get display name for damage type
static func get_name(type: Type) -> String:
	match type:
		Type.PHYSICAL: return "Physical"
		Type.ENERGY: return "Energy"
		Type.TRUE: return "True"
		Type.POISON: return "Poison"
		Type.FIRE: return "Fire"
		Type.ICE: return "Ice"
		Type.LIGHTNING: return "Lightning"
		Type.HOLY: return "Holy"
		Type.DARK: return "Dark"
		Type.PSYCHIC: return "Psychic"
		_: return "Unknown"

# Get color for damage type (for UI)
static func get_color(type: Type) -> Color:
	match type:
		Type.PHYSICAL: return Color.WHITE
		Type.ENERGY: return Color.CYAN
		Type.TRUE: return Color.GOLD
		Type.POISON: return Color.GREEN
		Type.FIRE: return Color.ORANGE_RED
		Type.ICE: return Color.LIGHT_BLUE
		Type.LIGHTNING: return Color.YELLOW
		Type.HOLY: return Color.LIGHT_GOLDENROD
		Type.DARK: return Color.PURPLE
		Type.PSYCHIC: return Color.MAGENTA
		_: return Color.GRAY

# Check if damage type ignores shields
static func ignores_shields(type: Type) -> bool:
	return type in [Type.TRUE, Type.POISON, Type.PSYCHIC]

# Check if damage type ignores armor
static func ignores_armor(type: Type) -> bool:
	return type in [Type.TRUE, Type.ENERGY, Type.PSYCHIC]