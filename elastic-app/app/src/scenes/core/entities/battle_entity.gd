extends Entity
class_name BattleEntity

var health: CappedResource
var block: CappedResource
var armor: CappedResource

var __status_effects: Dictionary[StatusEffect.Type, int] = {}


func signal_moved(new_position: int) -> void:
	assert(false, "signal_moved() must be overwritten by subclass")

func signal_created() -> void:
	assert(false, "signal_created() must be overwritten by subclass")
		
func get_active_status_effects() -> Array[StatusEffect.Type]:
	return __status_effects.keys()
	
func has_status_effect(effect: StatusEffect.Type):
	return __status_effects.has(effect) and __status_effects[effect] > 0

func decrement_status_effect(effect: StatusEffect.Type):
	if (effect == StatusEffect.Type.POISONED):
		var poison_duration = __status_effects.get(effect, 0)
		health.decrement(poison_duration)
		
	if __status_effects.has(effect):
		__status_effects[effect] = __status_effects[effect] - 1
		if __status_effects[effect] <= 0:
			__status_effects.erase(effect)
	
func decrement_all_status_effects():
	for effect_key in __status_effects.keys():
		decrement_status_effect(effect_key)

func apply_unit_damage(initial_damage: int, attack_source: BattleEntity) -> bool:
	if attack_source == null:
		assert(false, "Should always have an attack source when applying unit damage")
	
	var damage: int = apply_damage_modifiers(attack_source, self, initial_damage)
	print("initial dmg " + str(initial_damage))
	print("modified dmg " + str(damage))
	
	if damage < block.amount:
		block.decrement(damage)
		return true
	
	var remaining_damage = damage - block.amount
	block.amount = 0

	if remaining_damage < armor.amount:
		armor.decrement(damage)
		return true
	
	remaining_damage = damage - armor.amount
	armor.amount = 0
		
	health.decrement(remaining_damage)
	return true
	
static func apply_damage_modifiers(source: BattleEntity, target: BattleEntity, initial_damage: int) -> int:
	var damage: int = initial_damage
	
	# NOTE: order matters, so we'll need to review to make sure this does what we want
	
	# Source Effects First
	if source.has_status_effect(StatusEffect.Type.WEAK):
		damage = int(damage *  StaticData.get_float("weak_multiplier"))
	
	# Target Effects Second
	if target.has_status_effect(StatusEffect.Type.MARKED):
		damage += 1
	if target.has_status_effect(StatusEffect.Type.VULNERABLE):
		damage = int(damage *  StaticData.get_float("vulnerable_multiplier"))
			
	return damage
		
