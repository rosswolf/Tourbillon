extends IDamageable
class_name ICombatant

# Interface for entities that can deal damage
# Combat-capable entities MUST implement these methods

# Get attack power
func get_attack() -> int:
	assert(false, "ICombatant.get_attack() must be implemented")
	return 0

# Get damage multiplier for outgoing damage
func get_damage_multiplier() -> float:
	return 1.0  # Default: no modification

# Get flat damage bonus for outgoing damage
func get_damage_bonus() -> int:
	return 0  # Default: no bonus

# Get critical strike chance (0.0 to 1.0)
func get_crit_chance() -> float:
	return 0.0  # Default: no crits

# Modify outgoing damage packet
func modify_outgoing_damage(packet: DamagePacket) -> DamagePacket:
	return packet  # Default: no modification

# Get current energy/mana
func get_energy() -> int:
	return 999  # Default: unlimited energy

# Get maximum energy
func get_max_energy() -> int:
	return 999  # Default: unlimited energy

# Consume energy
func consume_energy(amount: int) -> bool:
	return true  # Default: always can consume (unlimited)

# Check if will attack next turn
func will_attack_next_turn() -> bool:
	return false  # Default: unknown

# Get threat level for smart targeting
func get_threat_level() -> float:
	return float(get_attack())  # Default: threat = attack power

# Get team/faction
func get_team() -> int:
	return 0  # Default: neutral team