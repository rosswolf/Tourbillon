extends Resource
class_name IDamageable

# Interface for entities that can take damage
# All entities that can be damaged MUST implement these methods

# Take damage and return actual damage dealt
func take_damage(amount: int, packet: DamagePacket) -> int:
	assert(false, "IDamageable.take_damage() must be implemented")
	return 0

# Get current health
func get_health() -> int:
	assert(false, "IDamageable.get_health() must be implemented")
	return 0

# Get maximum health
func get_max_health() -> int:
	assert(false, "IDamageable.get_max_health() must be implemented")
	return 0

# Check if entity is at full health
func is_full_health() -> bool:
	return get_health() == get_max_health()

# Check if entity is damaged
func is_damaged() -> bool:
	return get_health() < get_max_health()

# Check if entity is below half health
func is_below_half_health() -> bool:
	return get_health() < (get_max_health() / 2)

# Get current shields (0 if no shields)
func get_shields() -> int:
	return 0  # Default: no shields

# Get maximum shields
func get_max_shields() -> int:
	return 0  # Default: no shields

# Add shields
func add_shields(amount: int) -> void:
	pass  # Default: do nothing if no shield system

# Reduce shields
func reduce_shields(amount: int) -> int:
	return 0  # Default: no shields to reduce

# Set shields to specific value
func set_shields(amount: int) -> void:
	pass  # Default: do nothing if no shield system

# Get armor value (flat damage reduction)
func get_armor() -> int:
	return 0  # Default: no armor

# Get damage modifier for a specific damage type
func get_damage_modifier(damage_type: DamageType.Type) -> float:
	return 1.0  # Default: no modification

# Check if immune to a damage type
func is_immune_to(damage_type: DamageType.Type) -> bool:
	return false  # Default: not immune to anything