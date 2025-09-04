extends Node
class_name Damageable

## Interface for entities that can receive damage
## All damageable entities must extend this class

# Properties that affect damage calculation
var max_hp: int = 10
var current_hp: int = 10
var armor: int = 0  # Flat damage reduction
var shields: int = 0  # Absorbs damage before HP
var barrier_count: int = 0  # Absorbs complete hits

# Advanced defenses
var damage_cap: int = 0  # Max damage per hit (0 = no cap)
var damage_resistance: float = 0.0  # Percentage reduction (0.0-1.0)
var reflect_percent: float = 0.0  # Percentage reflected (0.0-1.0)
var execute_immunity_threshold: int = 0  # Can't be executed above this HP

# Status flags
var invulnerable: bool = false
var burn_duration: int = 0  # Prevents healing

# Signals
signal damage_received(packet: DamagePacket, actual_damage: int)
signal hp_changed(new_hp: int, max_hp: int)
signal shields_changed(new_shields: int)
signal barrier_broken()
signal defeated()

## Main damage interface - all damage goes through here
func receive_damage(packet: DamagePacket) -> int:
	if invulnerable:
		return 0
	
	# Pre-damage checks
	var modified_packet = _apply_pre_damage_modifiers(packet)
	
	# Calculate damage
	var damage_result = _calculate_damage(modified_packet)
	
	# Apply damage
	var actual_damage = _apply_damage(damage_result, modified_packet)
	
	# Post-damage effects
	_apply_post_damage_effects(modified_packet, actual_damage)
	
	# Emit signals
	damage_received.emit(modified_packet, actual_damage)
	
	return actual_damage

## Pre-damage modification hook (override in subclasses)
func _apply_pre_damage_modifiers(packet: DamagePacket) -> DamagePacket:
	return packet

## Calculate damage amount after defenses
func _calculate_damage(packet: DamagePacket) -> DamageResult:
	var result = DamageResult.new()
	result.packet = packet
	
	var damage = packet.get_damage_amount()
	
	# Apply damage cap
	if damage_cap > 0:
		damage = min(damage, damage_cap)
	
	# Apply resistance (not for true damage or pierce)
	if not packet.true_damage and not packet.pierce:
		damage = int(damage * (1.0 - damage_resistance))
	
	# Check barriers first (complete absorption)
	if barrier_count > 0 and not packet.pierce:
		result.barriers_broken = 1
		result.total_prevented = damage
		return result
	
	# Apply armor (unless pierce)
	if not packet.pierce and not packet.poison:
		var armor_reduction = min(armor, damage)
		damage -= armor_reduction
		result.armor_absorbed = armor_reduction
	
	# Apply to shields first (unless pierce)
	if shields > 0 and not packet.pierce:
		var shield_damage = damage
		
		# Pop keyword doubles damage vs shields
		if packet.pop:
			shield_damage *= 2
		
		var shields_lost = min(shields, shield_damage)
		result.shields_lost = shields_lost
		damage -= shields_lost
		
		# Pop doubles remaining damage too
		if packet.pop and damage > 0:
			damage *= 2
	
	result.final_damage = max(0, damage)
	return result

## Apply calculated damage to the entity
func _apply_damage(result: DamageResult, packet: DamagePacket) -> int:
	# Remove barriers
	if result.barriers_broken > 0:
		barrier_count -= result.barriers_broken
		barrier_broken.emit()
		return 0  # Barrier absorbed everything
	
	# Remove shields
	if result.shields_lost > 0:
		shields -= result.shields_lost
		shields_changed.emit(shields)
	
	# Apply HP damage
	if result.final_damage > 0:
		current_hp -= result.final_damage
		hp_changed.emit(current_hp, max_hp)
		
		# Check defeat
		if current_hp <= 0:
			_on_defeated()
	
	return result.final_damage

## Post-damage effects (reflect, overkill, etc)
func _apply_post_damage_effects(packet: DamagePacket, actual_damage: int) -> void:
	# Handle damage reflection
	if reflect_percent > 0 and packet.source and not packet.poison:
		var reflected = int(actual_damage * reflect_percent)
		if reflected > 0:
			_reflect_damage(packet.source, reflected)
	
	# Handle overkill
	if packet.overkill and current_hp <= 0:
		var excess = abs(current_hp)
		if excess > 0:
			_apply_overkill(packet, excess)

## Heal the entity
func heal(amount: int) -> int:
	if burn_duration > 0:
		return 0  # Can't heal while burned
	
	var healed = min(amount, max_hp - current_hp)
	current_hp += healed
	hp_changed.emit(current_hp, max_hp)
	return healed

## Add shields
func add_shields(amount: int) -> void:
	shields += amount
	shields_changed.emit(shields)

## Add barriers
func add_barriers(count: int) -> void:
	barrier_count += count

## Apply burn (prevents healing)
func apply_burn(ticks: int) -> void:
	burn_duration = max(burn_duration, ticks * 10)  # Convert to beats

## Check if can be executed
func can_be_executed(threshold: int) -> bool:
	if current_hp > execute_immunity_threshold:
		return false
	return current_hp <= threshold

## Execute (instant kill if eligible)
func execute() -> void:
	if not invulnerable:
		current_hp = 0
		_on_defeated()

## Called when HP reaches 0
func _on_defeated() -> void:
	defeated.emit()

## Helper: Reflect damage back to source
func _reflect_damage(source: Node, amount: int) -> void:
	if source.has_method("receive_damage"):
		var reflect_packet = DamagePacket.new()
		reflect_packet.amount = amount
		reflect_packet.damage_type = DamagePacket.DamageType.REFLECT
		reflect_packet.source = self
		reflect_packet.true_damage = true  # Reflected damage can't be reduced
		source.receive_damage(reflect_packet)

## Helper: Apply overkill to next target
func _apply_overkill(packet: DamagePacket, excess: int) -> void:
	# This needs to be handled by the combat manager
	if GlobalGameManager.has("gremlin_manager"):
		var manager = GlobalGameManager.get("gremlin_manager")
		if manager.has_method("apply_overkill_damage"):
			manager.apply_overkill_damage(packet, excess)

## Inner class for damage calculation results
class DamageResult extends RefCounted:
	var packet: DamagePacket
	var final_damage: int = 0
	var shields_lost: int = 0
	var armor_absorbed: int = 0
	var barriers_broken: int = 0
	var total_prevented: int = 0