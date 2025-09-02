extends Resource
class_name ITargetable

# Interface for entities that can be targeted
# All targetable entities MUST implement these methods

# Get position on battlefield
func get_position() -> Vector2i:
	assert(false, "ITargetable.get_position() must be implemented")
	return Vector2i.ZERO

# Get spawn time (for newest/oldest targeting)
func get_spawn_time() -> float:
	assert(false, "ITargetable.get_spawn_time() must be implemented")
	return 0.0

# Check if has a specific status effect
func has_status(status_name: String) -> bool:
	return false  # Default: no status effects

# Check if has any buffs
func has_buffs() -> bool:
	return false  # Default: no buffs

# Check if has any debuffs  
func has_debuffs() -> bool:
	return false  # Default: no debuffs

# Check if stunned
func is_stunned() -> bool:
	return false  # Default: not stunned

# Get adjacent entities
func get_adjacent_entities() -> Array:
	return []  # Default: no adjacency system

# Get entity type for validation
func get_entity_type() -> Entity.EntityType:
	assert(false, "ITargetable.get_entity_type() must be implemented")
	return Entity.EntityType.UNKNOWN

# Check if entity is alive/valid target
func is_alive() -> bool:
	if self is IDamageable:
		return get_health() > 0
	return true  # Default: always valid

# Get display name for UI
func get_display_name() -> String:
	return "Unknown"