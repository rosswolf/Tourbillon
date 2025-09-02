extends Node
class_name TargetingSystem

# Signals for targeting events
signal targets_selected(targets: Array)
signal targeting_cancelled()
signal target_highlighted(target: Entity)
signal target_unhighlighted(target: Entity)

# Retargeting behaviors when target becomes invalid
enum RetargetBehavior {
	FIZZLE,         # Effect fails
	NEXT_VALID,     # Pick next valid by same criteria
	RANDOM_VALID,   # Pick random valid target
	OVERKILL,       # Excess transfers to adjacent
	SPLIT           # Split among remaining valid
}

# Main targeting resolution
static func resolve_targets(selector: TargetSelector, all_targets: Array = []) -> Array:
	# Get all potential targets if not provided
	if all_targets.is_empty():
		all_targets = get_all_targetable_entities()
	
	# Filter by condition
	var valid_targets = selector.get_valid_targets(all_targets)
	
	# Handle no valid targets
	if valid_targets.is_empty():
		if selector.fallback != selector.selector_type:
			# Try fallback selector
			var fallback_selector = TargetSelector.new()
			fallback_selector.selector_type = selector.fallback
			fallback_selector.condition = TargetSelector.Condition.ANY
			return resolve_targets(fallback_selector, all_targets)
		return []
	
	# Select based on type
	if is_multi_target(selector.selector_type):
		return selector.select_multiple(valid_targets)
	else:
		var single = selector.select_single(valid_targets)
		return [single] if single else []

# Check if selector is multi-target
static func is_multi_target(type: TargetSelector.Type) -> bool:
	return type in [
		TargetSelector.Type.ALL,
		TargetSelector.Type.ADJACENT,
		TargetSelector.Type.ROW,
		TargetSelector.Type.COLUMN,
		TargetSelector.Type.FIRST_N,
		TargetSelector.Type.LAST_N,
		TargetSelector.Type.RANDOM_N
	]

# Get all targetable entities (gremlins in this case)
static func get_all_targetable_entities() -> Array:
	# This would connect to the gremlin manager
	if GlobalGameManager.has_method("get_all_gremlins"):
		return GlobalGameManager.get_all_gremlins()
	return []

# Handle retargeting when original target becomes invalid
static func handle_invalid_target(
	original_target: Entity, 
	selector: TargetSelector,
	behavior: RetargetBehavior = RetargetBehavior.FIZZLE
) -> Array:
	
	match behavior:
		RetargetBehavior.FIZZLE:
			return []
		
		RetargetBehavior.NEXT_VALID:
			var all_targets = get_all_targetable_entities()
			all_targets.erase(original_target)
			return resolve_targets(selector, all_targets)
		
		RetargetBehavior.RANDOM_VALID:
			var random_selector = TargetSelector.new()
			random_selector.selector_type = TargetSelector.Type.RANDOM
			random_selector.condition = selector.condition
			var all_targets = get_all_targetable_entities()
			all_targets.erase(original_target)
			return resolve_targets(random_selector, all_targets)
		
		RetargetBehavior.OVERKILL:
			# Find adjacent target
			if original_target.has_method("get_adjacent_entities"):
				var adjacent = original_target.get_adjacent_entities()
				if not adjacent.is_empty():
					return [adjacent[0]]
			return []
		
		RetargetBehavior.SPLIT:
			# Split effect among all remaining valid targets
			var all_targets = get_all_targetable_entities()
			all_targets.erase(original_target)
			return selector.get_valid_targets(all_targets)
		
		_:
			return []

# Calculate threat level for smart targeting
static func calculate_threat(entity: Entity) -> float:
	var threat = 0.0
	
	if entity.has_method("get_attack"):
		threat += entity.get_attack() * 2.0  # Weight attack heavily
	
	if entity.has_method("get_health"):
		threat += entity.get_health() * 0.5  # Consider survivability
	
	if entity.has_method("get_shields"):
		threat += entity.get_shields() * 0.3  # Shields make it harder to kill
	
	if entity.has_method("will_attack_next_turn"):
		if entity.will_attack_next_turn():
			threat *= 1.5  # Immediate threats
	
	if entity.has_method("get_special_threat"):
		threat += entity.get_special_threat()  # Custom threat modifiers
	
	return threat

# Get highest threat target
static func get_highest_threat(targets: Array) -> Entity:
	if targets.is_empty():
		return null
	
	var highest_threat = targets[0]
	var highest_value = calculate_threat(highest_threat)
	
	for target in targets:
		var threat = calculate_threat(target)
		if threat > highest_value:
			highest_threat = target
			highest_value = threat
	
	return highest_threat

# Validate targeting for a specific effect
static func validate_targeting(source: Entity, target: Entity, requirements: Dictionary) -> bool:
	# Check range requirement
	if requirements.has("max_range"):
		var distance = calculate_distance(source, target)
		if distance > requirements["max_range"]:
			return false
	
	# Check line of sight
	if requirements.has("requires_los") and requirements["requires_los"]:
		if not has_line_of_sight(source, target):
			return false
	
	# Check target type
	if requirements.has("valid_types"):
		if not target.get_type() in requirements["valid_types"]:
			return false
	
	# Check friendly fire
	if requirements.has("no_friendly_fire") and requirements["no_friendly_fire"]:
		if are_allies(source, target):
			return false
	
	return true

# Calculate distance between entities
static func calculate_distance(entity1: Entity, entity2: Entity) -> int:
	if entity1.has_method("get_position") and entity2.has_method("get_position"):
		var pos1 = entity1.get_position()
		var pos2 = entity2.get_position()
		return abs(pos1.x - pos2.x) + abs(pos1.y - pos2.y)  # Manhattan distance
	return 0

# Check line of sight
static func has_line_of_sight(source: Entity, target: Entity) -> bool:
	# Placeholder - would check for obstacles
	return true

# Check if entities are allies
static func are_allies(entity1: Entity, entity2: Entity) -> bool:
	if entity1.has_method("get_team") and entity2.has_method("get_team"):
		return entity1.get_team() == entity2.get_team()
	return false