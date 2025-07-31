extends Node
class_name Arena 
# Unit Positioning

enum Facing {
	UNKNOWN,
	RIGHT,
	LEFT
}

enum DecisionType {
	UNKNOWN,
	IN_RANGE,
	OUT_OF_RANGE
}

var current_arena_size: int
var unit_position_bimap: PositionBiMap

func _init(arena_size: int):
	#TODO confirm that we should have created & moved here. 
	GlobalSignals.core_mob_check_state.connect(on_mob_health_changed)
	#GlobalSignals.core_mob_created.connect(on_mob_health_changed)
	#GlobalSignals.core_mob_moved.connect(on_mob_health_changed)
	
	unit_position_bimap = PositionBiMap.new()
	current_arena_size = arena_size
	GlobalSignals.signal_core_arena_created(arena_size)

func on_mob_health_changed(mob_instance_id: String, new_value: int):
	if new_value != 0:
		return
	
	unit_position_bimap.remove(mob_instance_id)

func add_and_signal(entity: BattleEntity, position: int) -> void:
	unit_position_bimap.add(entity, position)
	entity.signal_created()
	
func swap_and_signal(entity: BattleEntity, entity2: BattleEntity) -> void:
	var entity_position = get_position(entity.instance_id)
	var entity2_position = get_position(entity2.instance_id)
	
	unit_position_bimap.remove(entity2.instance_id)	
	unit_position_bimap.move(entity, entity2_position)
	unit_position_bimap.add(entity2, entity_position)
	
	entity.signal_moved(entity2_position)
	entity2.signal_moved(entity_position)
	
func move_and_signal(entity: BattleEntity, new_position: int) -> void:
	unit_position_bimap.move(entity, new_position)
	entity.signal_moved(new_position)
	#TODO: await for signal from UI?
	await TimerService.create_timer(0.7).timeout 
		
func get_mobs() -> Array[Mob]:
	var results: Array[Mob] = []
	for entity in unit_position_bimap.__pos_to_entities.values():
		if entity is Mob:
			results.append(entity as Mob)
	return results

func knockback_entity(target: BattleEntity, direction: int):
	var target_pos = unit_position_bimap.get_position(target.instance_id)
	
	var open_slot = can_knock_direction(target, direction)
	if open_slot != -1:
		await knock_direction(target, direction, open_slot)	

		
func can_knock_direction(target: BattleEntity, direction: int):
	var check_index = unit_position_bimap.get_position(target.instance_id) + direction
	while check_index > 0 and check_index < current_arena_size:
		if unit_position_bimap.get_id(check_index) == "":
			return check_index
		check_index = check_index + direction
	return -1
	
func knock_direction(target: BattleEntity, direction: int, open_slot: int):
	
	var to_index = open_slot
	var from_index = to_index + (-1 * direction)
	
	var target_index = unit_position_bimap.get_position(target.instance_id)
	
	while from_index >= target_index:
		var entity: BattleEntity = unit_position_bimap.get_entity(from_index)
		await move_and_signal(entity, to_index)
		to_index = from_index
		from_index = to_index + (-1 * direction)
	return true
	
func get_direction(source: BattleEntity, target: BattleEntity):
	__confirm_valid_and_in_arena(source, target)
	if get_position(source.instance_id) < get_position(target.instance_id):
		return 1
	else:
		return -1

func get_distance_between(source: BattleEntity, target: BattleEntity):
	__confirm_valid_and_in_arena(source, target)
	return abs(get_position(target.instance_id) - get_position(source.instance_id))
	
func __confirm_valid_and_in_arena(source: BattleEntity, target: BattleEntity):
	if source == null or target == null:
		assert(false, "source/target shouldn't be null")
		return false
	var source_pos = get_position(source.instance_id)
	var target_pos = get_position(target.instance_id)
	if target_pos == -1 or source_pos == -1:
		assert(false, "can't get a direction unless both entities are in the arena")
		return false
	
	return true
	
func get_position(entity_id: String) -> int:
	return unit_position_bimap.get_position(entity_id)

func get_entity(position: int) -> BattleEntity:
	return unit_position_bimap.get_entity(position)
