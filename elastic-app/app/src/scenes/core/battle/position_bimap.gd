class_name PositionBiMap
extends RefCounted

# Note: not intended for large arenas

var __pos_to_entities: Dictionary[int, BattleEntity] = {}

func add(entity: BattleEntity, position: int) -> void:
	if contains(entity.instance_id):
		assert(false, "entity already in bimap: " + entity.instance_id)

	if not is_position_empty(position):
		assert(false, "attempted to add to non-empty position in bimap: " + entity.instance_id + ", " + str(position))

	__pos_to_entities[position] = entity

func move(entity: BattleEntity, new_position: int) -> void:
	var current_position: int = get_position(entity.instance_id)

	if current_position == -1:
		assert(false, "entity not in bimap when attempting move: " + entity.instance_id)

	if not is_position_empty(new_position):
		assert(false, "attempted to move to non-empty position in bimap: " + entity.instance_id + ", " + str(new_position))

	__pos_to_entities.erase(current_position)
	__pos_to_entities[new_position] = entity



func remove(id: String) -> void:
	if not contains(id):
		return

	for position in __pos_to_entities.keys():
		if __pos_to_entities[position].instance_id == id:
			__pos_to_entities.erase(position)
			break

func contains(id: String) -> bool:
	return get_position(id) != -1

func get_position(id: String) -> int:
	for position in __pos_to_entities:
		var entity: BattleEntity = __pos_to_entities[position]
		if entity.instance_id == id:
			return position

	return -1

func get_entity(position: int) -> BattleEntity:
	if __pos_to_entities.has(position):
		return __pos_to_entities[position]
	else:
		return null

func is_position_empty(position: int) -> bool:
	return __pos_to_entities.get(position) == null

func get_id(position: int) -> String:
	var entity: BattleEntity = get_entity(position)
	if entity == null:
		return ""
	else:
		return entity.instance_id

func has_id(id: String) -> bool:
	return contains(id)

func clear() -> void:
	__pos_to_entities.clear()
