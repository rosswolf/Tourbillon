extends Resource
class_name TargetSelector

enum Type {
	# Single target selectors
	HIGHEST_HEALTH,
	LOWEST_HEALTH,
	NEWEST,
	OLDEST,
	TARGETED,      # Player selected
	RANDOM,
	STRONGEST,     # Highest attack
	WEAKEST,       # Lowest attack
	CLOSEST,       # Nearest to source
	FURTHEST,      # Furthest from source
	
	# Multi-target selectors
	ALL,
	ADJACENT,
	ROW,
	COLUMN,
	FIRST_N,
	LAST_N,
	RANDOM_N
}

enum Condition {
	ANY,              # No condition
	SHIELDED,         # Has shields > 0
	UNSHIELDED,       # Has shields == 0
	DAMAGED,          # Health < max_health
	FULL_HEALTH,      # Health == max_health
	POISONED,         # Has poison stacks
	MARKED,           # Has mark debuff
	STUNNED,          # Is stunned
	ABOVE_THRESHOLD,  # Health > X
	BELOW_THRESHOLD,  # Health < X
	HAS_BUFF,         # Has any buff
	HAS_DEBUFF,       # Has any debuff
	IS_ATTACKING      # Will attack next turn
}

# Selector configuration
var selector_type: Type = Type.RANDOM
var condition: Condition = Condition.ANY
var count: int = 1  # For multi-target selectors
var threshold: int = 0  # For threshold conditions
var fallback: Type = Type.RANDOM  # If no valid targets

# Priority for tie-breaking
var tiebreaker: Type = Type.RANDOM

# Get all valid targets based on condition
func get_valid_targets(all_targets: Array) -> Array:
	var valid = []
	
	for target in all_targets:
		if meets_condition(target):
			valid.append(target)
	
	return valid

# Check if target meets condition
func meets_condition(target: Entity) -> bool:
	match condition:
		Condition.ANY:
			return true
		Condition.SHIELDED:
			return target.has_method("get_shields") and target.get_shields() > 0
		Condition.UNSHIELDED:
			return not target.has_method("get_shields") or target.get_shields() == 0
		Condition.DAMAGED:
			return target.has_method("is_damaged") and target.is_damaged()
		Condition.FULL_HEALTH:
			return target.has_method("is_full_health") and target.is_full_health()
		Condition.POISONED:
			return target.has_method("has_status") and target.has_status("poison")
		Condition.MARKED:
			return target.has_method("has_status") and target.has_status("marked")
		Condition.STUNNED:
			return target.has_method("is_stunned") and target.is_stunned()
		Condition.ABOVE_THRESHOLD:
			return target.has_method("get_health") and target.get_health() > threshold
		Condition.BELOW_THRESHOLD:
			return target.has_method("get_health") and target.get_health() < threshold
		Condition.HAS_BUFF:
			return target.has_method("has_buffs") and target.has_buffs()
		Condition.HAS_DEBUFF:
			return target.has_method("has_debuffs") and target.has_debuffs()
		Condition.IS_ATTACKING:
			return target.has_method("will_attack_next") and target.will_attack_next()
		_:
			return true

# Select single target from valid targets
func select_single(targets: Array) -> Entity:
	if targets.is_empty():
		return null
	
	match selector_type:
		Type.HIGHEST_HEALTH:
			return get_highest_health(targets)
		Type.LOWEST_HEALTH:
			return get_lowest_health(targets)
		Type.NEWEST:
			return get_newest(targets)
		Type.OLDEST:
			return get_oldest(targets)
		Type.TARGETED:
			return get_player_targeted(targets)
		Type.RANDOM:
			return get_random(targets)
		Type.STRONGEST:
			return get_strongest(targets)
		Type.WEAKEST:
			return get_weakest(targets)
		Type.CLOSEST:
			return get_closest(targets)
		Type.FURTHEST:
			return get_furthest(targets)
		_:
			return get_random(targets)

# Select multiple targets
func select_multiple(targets: Array) -> Array:
	if targets.is_empty():
		return []
	
	match selector_type:
		Type.ALL:
			return targets
		Type.ADJACENT:
			return get_adjacent_targets(targets)
		Type.ROW:
			return get_row_targets(targets)
		Type.COLUMN:
			return get_column_targets(targets)
		Type.FIRST_N:
			return get_first_n(targets, count)
		Type.LAST_N:
			return get_last_n(targets, count)
		Type.RANDOM_N:
			return get_random_n(targets, count)
		_:
			return [select_single(targets)]

# Specific selector implementations
func get_highest_health(targets: Array) -> Entity:
	var highest = targets[0]
	for target in targets:
		if target.has_method("get_health") and target.get_health() > highest.get_health():
			highest = target
	return highest

func get_lowest_health(targets: Array) -> Entity:
	var lowest = targets[0]
	for target in targets:
		if target.has_method("get_health") and target.get_health() < lowest.get_health():
			lowest = target
	return lowest

func get_newest(targets: Array) -> Entity:
	var newest = targets[0]
	for target in targets:
		if target.has_method("get_spawn_time") and target.get_spawn_time() > newest.get_spawn_time():
			newest = target
	return newest

func get_oldest(targets: Array) -> Entity:
	var oldest = targets[0]
	for target in targets:
		if target.has_method("get_spawn_time") and target.get_spawn_time() < oldest.get_spawn_time():
			oldest = target
	return oldest

func get_player_targeted(targets: Array) -> Entity:
	# Check if player has selected a target
	if GlobalGameManager.has_method("get_selected_target"):
		var selected = GlobalGameManager.get_selected_target()
		if selected in targets:
			return selected
	return get_random(targets)

func get_random(targets: Array) -> Entity:
	return targets[randi() % targets.size()]

func get_strongest(targets: Array) -> Entity:
	var strongest = targets[0]
	for target in targets:
		if target.has_method("get_attack") and target.get_attack() > strongest.get_attack():
			strongest = target
	return strongest

func get_weakest(targets: Array) -> Entity:
	var weakest = targets[0]
	for target in targets:
		if target.has_method("get_attack") and target.get_attack() < weakest.get_attack():
			weakest = target
	return weakest

func get_closest(targets: Array) -> Entity:
	# Requires source position - placeholder
	return get_random(targets)

func get_furthest(targets: Array) -> Entity:
	# Requires source position - placeholder
	return get_random(targets)

func get_adjacent_targets(targets: Array) -> Array:
	# Requires position system - placeholder
	return targets.slice(0, min(3, targets.size()))

func get_row_targets(targets: Array) -> Array:
	# Requires grid position - placeholder
	return targets

func get_column_targets(targets: Array) -> Array:
	# Requires grid position - placeholder
	return targets

func get_first_n(targets: Array, n: int) -> Array:
	return targets.slice(0, min(n, targets.size()))

func get_last_n(targets: Array, n: int) -> Array:
	var start = max(0, targets.size() - n)
	return targets.slice(start, targets.size())

func get_random_n(targets: Array, n: int) -> Array:
	var shuffled = targets.duplicate()
	shuffled.shuffle()
	return shuffled.slice(0, min(n, shuffled.size()))

# Builder pattern for creating selectors
class TargetSelectorBuilder:
	var _selector: TargetSelector = TargetSelector.new()
	
	func with_type(type: Type) -> TargetSelectorBuilder:
		_selector.selector_type = type
		return self
	
	func with_condition(condition: Condition) -> TargetSelectorBuilder:
		_selector.condition = condition
		return self
	
	func with_count(count: int) -> TargetSelectorBuilder:
		_selector.count = count
		return self
	
	func with_threshold(threshold: int) -> TargetSelectorBuilder:
		_selector.threshold = threshold
		return self
	
	func with_fallback(fallback: Type) -> TargetSelectorBuilder:
		_selector.fallback = fallback
		return self
	
	func with_tiebreaker(tiebreaker: Type) -> TargetSelectorBuilder:
		_selector.tiebreaker = tiebreaker
		return self
	
	func build() -> TargetSelector:
		return _selector