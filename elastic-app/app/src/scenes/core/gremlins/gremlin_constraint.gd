extends Resource
class_name GremlinConstraint

# Base constraint class that modifies gremlin behavior
var constraint_name: String = "Unknown Constraint"
var is_active: bool = true

# Apply constraint to incoming damage
func modify_incoming_damage(damage: int, packet: DamagePacket) -> int:
	return damage

# Apply constraint to outgoing damage
func modify_outgoing_damage(packet: DamagePacket) -> DamagePacket:
	return packet

# Modify gremlin stats
func modify_stats(gremlin: Entity) -> void:
	pass

# Check if action can be performed under this constraint
func can_perform_action(action: GremlinAction, gremlin: Entity) -> bool:
	return true

# Modify action before execution
func modify_action(action: GremlinAction, gremlin: Entity) -> GremlinAction:
	return action

# Process constraint each beat
func process_beat(gremlin: Entity, beat: int) -> void:
	pass

# Process constraint each tick
func process_tick(gremlin: Entity, tick: int) -> void:
	pass

# Get constraint description for UI
func get_description() -> String:
	return constraint_name

# Check if constraint should be removed
func should_remove() -> bool:
	return false