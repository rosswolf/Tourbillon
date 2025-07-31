extends Node
class_name Battleground

var arena: Arena 

var background_art_uid: String
var mobs: Dictionary[String, Mob] = {}


enum SortOrder {
	UNKNOWN,
	ASCENDING,
	DESCENDING
}

enum OrderPriority {
	UNKNOWN,
	IGNORE,
	CLOSEST,
	FARTHEST,
	LEFT_TO_RIGHT,
	HIGHEST_HP,
	LOWEST_HP,
	#STRONGEST_ATTACKER,
	WEAKEST_ATTACKER,
	#RIGHT_TO_LEFT,
	RIGHT,
	LEFT,
	RANDOM_ENEMY,
	#ATTACKER,
	#NON_ATTACKER,
	#FLYER,
	#NON_FLYER
}

enum DamagePriorityAttribute {
	UNKNOWN,
	INDEX,
	RAW_HP,
	ATTACK_DAMAGE,
	IS_ATTACKING,
	#IS_FLYER,
	IS_RIGHT_OF_HERO,
	IS_LEFT_OF_HERO,
	ABSOLUTE_DISTANCE,
	RANDOMIZE
}

func _init():
	GlobalSignals.core_mob_check_state.connect(__mob_health_changed)
	GlobalSignals.core_targeting_changed.connect(__on_targeting_changed)
	GlobalSignals.core_begin_turn.connect(__update_targeting_preview)
	GlobalSignals.core_end_turn.connect(__hide_targeting_preview)

func __on_targeting_changed(targeting: OrderPriority):
	__update_targeting_preview()

func __update_targeting_preview():
	var target: BattleEntity = get_priority_mob(GlobalGameManager.hero.get_targeting())
		
	if target == null:
		return
	var target_index: int = arena.get_position(target.instance_id)
	
	if target_index == -1:
		return
	
	set_icon_on_targeting_slot(target_index)

func __hide_targeting_preview():
	set_icon_on_targeting_slot(-1)
	
func __on_card_unhovered(card_instance_id: String):
	remove_icon_on_targeting_slot()
	pass
	
func set_icon_on_targeting_slot(target_index):
	GlobalSignals.signal_core_battleground_targeting_preview_changed(target_index)	
		
func remove_icon_on_targeting_slot():
	GlobalSignals.signal_core_battleground_targeting_preview_changed(-1)
	
func check_mobs_defeated() -> bool:
	return mobs.is_empty()
		
	
func __mob_health_changed(mob_instance_id, new_value):
	if new_value <= 0 and mobs.has(mob_instance_id):
		mobs.erase(mob_instance_id)	

func get_value_for_damage_priority(attribute: DamagePriorityAttribute, mob: Mob) -> Variant:
	if mob == null:
		assert(false, "mob is not set")
		return 0
		
	if attribute == DamagePriorityAttribute.UNKNOWN:
		return 0
	elif attribute == DamagePriorityAttribute.ABSOLUTE_DISTANCE:
		return abs(arena.unit_position_bimap.get_position(mob.instance_id) - arena.unit_position_bimap.get_position(GlobalGameManager.hero.instance_id))
	elif attribute == DamagePriorityAttribute.INDEX:
		return arena.unit_position_bimap.get_position(mob.instance_id)
	elif attribute == DamagePriorityAttribute.RAW_HP:
		return mob.health.amount
	elif attribute == DamagePriorityAttribute.IS_LEFT_OF_HERO:
		return arena.unit_position_bimap.get_position(mob.instance_id) != -1 and arena.unit_position_bimap.get_position(GlobalGameManager.hero.instance_id) != -1 and \
			(arena.unit_position_bimap.get_position(mob.instance_id) - arena.unit_position_bimap.get_position(GlobalGameManager.hero.instance_id)) < 0
	elif attribute == DamagePriorityAttribute.IS_RIGHT_OF_HERO:
		return arena.unit_position_bimap.get_position(mob.instance_id) != -1 and arena.unit_position_bimap.get_position(GlobalGameManager.hero.instance_id) != -1 and \
			(arena.unit_position_bimap.get_position(mob.instance_id) - arena.unit_position_bimap.get_position(GlobalGameManager.hero.instance_id)) > 0
	elif attribute == DamagePriorityAttribute.ATTACK_DAMAGE:
		return mob.get_next_move_damage()
	elif attribute == DamagePriorityAttribute.IS_ATTACKING:
		return mob.is_attacking()
	else:
		assert(false, "unexpected attribute " + str(attribute))
		return 0
	

class FilterSortParams:
	var sort_order:SortOrder = SortOrder.UNKNOWN
	var sort_attribute: DamagePriorityAttribute = DamagePriorityAttribute.UNKNOWN
	var include_attributes: Array[DamagePriorityAttribute] = []
		
	func _init(sort_order_in: SortOrder, damage_priority_attribute_in: DamagePriorityAttribute, include_attributes_in: Array[DamagePriorityAttribute]):
		sort_order = sort_order_in
		sort_attribute = damage_priority_attribute_in
		include_attributes = include_attributes_in
		
func get_filter_sort_params(damage_priority: OrderPriority) -> FilterSortParams:
	var sort_order:SortOrder = SortOrder.UNKNOWN
	var sort_attribute: DamagePriorityAttribute = DamagePriorityAttribute.UNKNOWN
	var include_attributes: Array[DamagePriorityAttribute] = []
	if damage_priority == OrderPriority.CLOSEST:
		sort_order = SortOrder.ASCENDING
		sort_attribute = DamagePriorityAttribute.ABSOLUTE_DISTANCE
	elif damage_priority == OrderPriority.FARTHEST:
		sort_order = SortOrder.DESCENDING
		sort_attribute = DamagePriorityAttribute.ABSOLUTE_DISTANCE
	elif damage_priority == OrderPriority.LEFT_TO_RIGHT:
		sort_order = SortOrder.ASCENDING
		sort_attribute = DamagePriorityAttribute.INDEX
	elif damage_priority == OrderPriority.HIGHEST_HP:
		sort_order = SortOrder.DESCENDING
		sort_attribute = DamagePriorityAttribute.RAW_HP
	elif damage_priority == OrderPriority.LOWEST_HP:
		sort_order = SortOrder.ASCENDING
		sort_attribute = DamagePriorityAttribute.RAW_HP
	#elif damage_priority == OrderPriority.STRONGEST_ATTACKER:
		#sort_order = SortOrder.DESCENDING
		#damage_priority_attribute = DamagePriorityAttribute.ATTACK_DAMAGE
	elif damage_priority == OrderPriority.WEAKEST_ATTACKER:
		sort_order = SortOrder.ASCENDING
		sort_attribute = DamagePriorityAttribute.ATTACK_DAMAGE
		include_attributes = [DamagePriorityAttribute.IS_ATTACKING]
	#elif damage_priority == OrderPriority.RIGHT_TO_LEFT:
		#sort_order = SortOrder.DESCENDING
		#damage_priority_attribute = DamagePriorityAttribute.INDEX
	elif damage_priority == OrderPriority.RIGHT:
		sort_order = SortOrder.ASCENDING
		sort_attribute = DamagePriorityAttribute.INDEX
		include_attributes = [DamagePriorityAttribute.IS_RIGHT_OF_HERO]
	elif damage_priority == OrderPriority.LEFT:
		sort_order = SortOrder.DESCENDING
		sort_attribute = DamagePriorityAttribute.INDEX
		include_attributes = [DamagePriorityAttribute.IS_LEFT_OF_HERO]
		#elif damage_priority == OrderPriority.ATTACKER:
		#sort_order = SortOrder.DESCENDING
		#damage_priority_attribute = DamagePriorityAttribute.IS_ATTACKING
	#elif damage_priority == OrderPriority.NON_ATTACKER:
		#sort_order = SortOrder.ASCENDING
		#damage_priority_attribute = DamagePriorityAttribute.IS_ATTACKING
	#elif damage_priority == OrderPriority.FLYER:
		#sort_order = SortOrder.DESCENDING
		#damage_priority_attribute = DamagePriorityAttribute.IS_FLYER
	#elif damage_priority == OrderPriority.NON_FLYER:
		#sort_order = SortOrder.ASCENDING
		#damage_priority_attribute = DamagePriorityAttribute.IS_FLYER
	else:
		assert(false, "unexepcted Damage Priority " + str(damage_priority))
	
	return FilterSortParams.new(sort_order, sort_attribute, include_attributes)
	
func get_filter_callable(damage_priority: OrderPriority):
	var filter_params: FilterSortParams = get_filter_sort_params(damage_priority)
	
	return func(mob: Mob):
		var result = true
		for attribute in filter_params.include_attributes:
			result = result and get_value_for_damage_priority(attribute, mob)
		return result
		
func get_sorting_callable(damage_priority: OrderPriority):
	var sort_params: FilterSortParams = get_filter_sort_params(damage_priority)
	return func(mob1: Mob, mob2: Mob):
		if mob1 == null or mob2 == null:
			assert(false, "unexpected null mob when sorting array")
			return false
		
		var mob1_val: int = get_value_for_damage_priority(sort_params.sort_attribute, mob1)
		var mob2_val: int = get_value_for_damage_priority(sort_params.sort_attribute, mob2)
		
		var mob1_default_val: int = get_value_for_damage_priority(DamagePriorityAttribute.INDEX, mob1)
		var mob2_default_val: int = get_value_for_damage_priority(DamagePriorityAttribute.INDEX, mob2)
		
		if sort_params.sort_order == SortOrder.UNKNOWN:
			assert(false, "unexpected sort order unknown")
			sort_params.sort_order = SortOrder.ASCENDING
			return false
			
		if mob1_val == mob2_val:
			# default is always leftmost...
			return mob1_default_val < mob2_default_val
		else:
			if sort_params.sort_order == SortOrder.ASCENDING:
				return mob1_val < mob2_val
			elif sort_params.sort_order == SortOrder.DESCENDING:
				return mob2_val < mob1_val
			else:
				assert(false, "unexpected sort order but not unknown!?")
				return false
	
func get_mob_ordering(mobs: Array[Mob], damage_priority: OrderPriority) -> Array[Mob]:
	var result = mobs.duplicate()
	
	if damage_priority == OrderPriority.IGNORE:
		damage_priority = GlobalGameManager.hero.get_targeting()
		
	if damage_priority == OrderPriority.RANDOM_ENEMY:
		result.shuffle()
		return result
	
	var filter_callable: Callable = get_filter_callable(damage_priority)
	result = result.filter(filter_callable)
	
	var sorting_callable: Callable = get_sorting_callable(damage_priority)
	
	result.sort_custom(sorting_callable)
	return result

func spawn_new_stage(wave_difficulty: int):	
	spawn_random_wave_at_difficulty(wave_difficulty)
	
func spawn_random_wave_at_difficulty(wave_difficulty: int):
	var wave_templates: Array[String] = []
	
	wave_templates.assign(StaticData.lookup_in_data(StaticData.wave_data,"wave_difficulty",wave_difficulty,"wave_template_id"))
	
	if wave_templates.size() == 0:
		assert(false, "no waves found with difficulty " + str(wave_difficulty))
	
	var wave_template:String = wave_templates.pick_random()
	
	spawn_wave(wave_template)
	
func spawn_wave(wave_template_id: String):
	var current_arena_size = int(StaticData.wave_data.get(wave_template_id).get("arena_size"))
	#TODO: might change
	if current_arena_size > 18:
		assert(false, "arenas can't be bigger than 18 yet. currently use numberline (1-18)")

	var wave_template_data = StaticData.wave_data.get(wave_template_id)
	var mobs_to_spawn = wave_template_data.get("wave_mobs", {})
	if mobs_to_spawn.size() == 0:
		assert(false, "0 mobs to spawn for wave")
	
	if current_arena_size < mobs_to_spawn.size() + 1:
		assert(false, "not enough space in arena to spawn mobs and player")
	
	var player_location: int = int(wave_template_data.get("hero_spawn_location", -1))
	if player_location == -1:
		assert(false, "must specify a player location that is >= 0 and < arena_size")
		
	arena = Arena.new(current_arena_size)

	arena.add_and_signal(GlobalGameManager.hero, player_location)
	
	for mob_template_id in mobs_to_spawn.keys():
		var mob_location = int(mobs_to_spawn[mob_template_id]) 
		var mob: Mob = Mob.load_mob(mob_template_id)
		mob.facing = Arena.Facing.LEFT
		mobs[mob.instance_id] = mob
		arena.add_and_signal(mob, mob_location)

func aoe_attack(source: BattleEntity, damage: int, aoe_size: int) -> bool:
	if aoe_size % 2 == 0:
		assert(false, "aoe size must be odd for now")
		return false
	
	if source is Hero:
		var mob: Mob = acquire_target_for(source) as Mob
		
		var mob_pos = arena.get_position(mob.instance_id)
	
		# Do overall AOE animation	
		var min = mob_pos - floor(aoe_size/2.0)
		var max = mob_pos + floor(aoe_size/2.0) + 1 # range is exclusive
		for pos in range(min, max):
			if pos >= 0 and pos < arena.current_arena_size:
				await damage_unit_at_position(pos, damage, source)
				
		return true
	else:
		assert(false, "unimplemented for mobs right now")
		return false
	
func damage_unit_at_position(pos: int, damage: int, source: BattleEntity):
	if pos >= 0 and pos < arena.current_arena_size:
		var target: BattleEntity = arena.get_entity(pos)
		if target == null:
			return true
		target.apply_unit_damage(damage, source)
	
	return true
	
func mob_heal_ally(source: BattleEntity, amount: int):
	var lowest_hp = 9999999
	var current_target: Mob = null
	for i in range(0, arena.current_arena_size):
		
		var mob: Mob = arena.get_entity(0) as Mob
		if mob != null and mob.health.amount < lowest_hp:
			current_target = mob
			lowest_hp = mob.health.amount
			
	if current_target != null:
		current_target.health.increment(amount)
	
func dash_right(entity: BattleEntity) -> bool:
	return dash_dir(entity, 1)

func dash_left(entity: BattleEntity) -> bool:
	return dash_dir(entity, -1)
	
func dash_dir(entity: BattleEntity, dir: int) -> bool:
	if dir != 1 and dir != -1:
		assert(false, "dir must be 1 or -1")
		return false
	
	var how_many: int = 1
	
	var entity_pos: int = arena.get_position(entity.instance_id)
	if entity_pos == -1:
		assert(false, "trying to dash an entity that isn't in the arena " + entity.instance_id)
		return false
	
	while arena.unit_position_bimap.get_id(entity_pos + (dir * how_many)) == "":
		how_many = how_many + 1
	
	var unit_at_pos = arena.unit_position_bimap.get_id(entity_pos + (dir * how_many))
	
	how_many = how_many - 1
	
	var new_index = entity_pos + (dir * how_many)
	if entity_pos == new_index:
		return true
	
	arena.unit_position_bimap.move(entity, new_index)
	entity.signal_moved(new_index)
	
	return true
	
func stun_mob(damage_priority: OrderPriority):
	var target_mob: Mob = get_priority_mob(damage_priority)
	if target_mob != null:
		target_mob.add_status_effect(StatusEffect.Type.STUNNED, 1)
	
func trip_mob(damage_priority: OrderPriority, amount: int):
	var target_mob: Mob = get_priority_mob(damage_priority)
	if target_mob != null:
		target_mob.add_status_effect(StatusEffect.Type.TRIPPED, 1)

func knockback_mob(amount: int):
	var damage_priority: Battleground.OrderPriority = GlobalGameManager.hero.get_targeting()
	var target_mob: Mob = get_priority_mob(damage_priority)
	if target_mob != null:
		var direction = arena.get_direction(GlobalGameManager.hero, target_mob)
		arena.knockback_entity(target_mob, direction)

func bump(source: BattleEntity):
	var damage_priority: Battleground.OrderPriority = GlobalGameManager.hero.get_targeting()
	var target_mob: Mob = get_priority_mob(damage_priority)
	
	var push_direction: int = arena.get_direction(source, target_mob)
	if push_direction != -1 and push_direction != 1:
		assert(false, "direction must be 1 or -1")
	
	var target_pos = arena.get_position(target_mob.instance_id)
	if target_pos == -1:
		assert(false, "source must be in the arena")
	
	var target_pos_2 = target_pos + push_direction
	
	if arena.get_entity(target_pos) == null:
		return true
	
	if arena.get_entity(target_pos_2) == null:
		signal_and_move_mob(arena.get_entity(target_pos), target_pos_2)
	else:
		arena.swap_and_signal(arena.get_entity(target_pos), arena.get_entity(target_pos_2))
	return true

func unit_pull(source: BattleEntity):
	var target: BattleEntity = acquire_target_for(source)
	
	# A B  (A, B) direction is 1 (right).  
	var direction: int = arena.get_direction(source, target) 
	
	var target_original_pos = arena.get_position(target.instance_id)
	var source_original_pos = arena.get_position(source.instance_id)
	
	var target_desired_pos = source_original_pos + direction
	
	var conflicting_entity = arena.get_entity(target_desired_pos)
	if conflicting_entity == null:
		return await signal_and_move_mob(target, target_desired_pos)
	else:
		return await arena.swap_and_signal(target, conflicting_entity)
		
func unit_dash(entity: BattleEntity) -> bool:
	var target: BattleEntity = acquire_target_for(entity)
	if target == null:
		return true
	var target_loc = arena.get_position(target.instance_id)
	var entity_loc = arena.get_position(GlobalGameManager.hero.instance_id)
	if target_loc == -1 or entity_loc == -1:
		assert(false, "entity or target not in arena when dashing")
		return false
	if target_loc > entity_loc:
		return dash_right(entity)
	else:
		return dash_left(entity)

func acquire_target_for(attack_source: BattleEntity) -> BattleEntity:
	if attack_source is Hero:
		return get_priority_mob(GlobalGameManager.hero.get_targeting())
	else:
		# TODO make unit teams. 
		return GlobalGameManager.hero
		
		
const RANGED_ATTACK_RANGE = 9999 # larger than we'll ever need for ranged attacks
const MELEE_ATTACK_RANGE = 1
func unit_attack_range(source: BattleEntity, damage: int) -> bool:
	return await unit_attack(source, damage, RANGED_ATTACK_RANGE)
		
func unit_attack_melee(source: BattleEntity, damage: int) -> bool:
	return await unit_attack(source, damage, MELEE_ATTACK_RANGE)
	
func unit_attack(source: BattleEntity, damage: int, range: int) -> bool:
	var target = acquire_target_for(source)
	if can_attack_target(source, target, range):
		return await target.apply_unit_damage(damage, source)
	return true
	
func is_target_facing_attack(source: BattleEntity, target: BattleEntity) -> bool:
	if source == target:
		# Why you hitting yourself?
		return true
		
	var source_position: int = arena.unit_position_bimap.get_position(source.instance_id)
	var target_position: int = arena.unit_position_bimap.get_position(target.instance_id)
		
	if source_position < target_position:
		return target.facing == Arena.Facing.LEFT
	
	return target.facing == Arena.Facing.RIGHT
						
func can_attack_target(source: BattleEntity, target: BattleEntity, range: int):
	if source is Hero:
		# TODO: any restrictions on the hero targeting? (like a status effect similar to ensnare)
		return true
	elif source is Mob:
		var mob_pos: int = arena.unit_position_bimap.get_position(source.instance_id)
	
		if mob_pos == -1:
			return false
	
		return can_attack_hero_from_range(range, mob_pos)
	else:
		assert(false, "what battle entity are you dealing with, huh?")

func can_attack_hero_from_range(attack_range, location):
	var hero_pos = arena.unit_position_bimap.get_position(GlobalGameManager.hero.instance_id)
	return abs(location - hero_pos) <= attack_range

func move_mob_retreat(mob: Mob, amount: int):
	var dir: int = arena.get_direction(GlobalGameManager.hero, mob)
	return await move_mob_direction(mob, amount, dir)
	
func move_mob_engage(mob: Mob, amount: int):
	var dir: int = arena.get_direction(GlobalGameManager.hero, mob)
	return await move_mob_direction(mob, amount, dir * -1)

func move_mob_direction(mob: Mob, amount: int, direction: int):
	if direction != 1 and direction != -1:
		assert(false, "direction must be 1 or -1")
		return false

	var mob_pos: int = arena.unit_position_bimap.get_position(mob.instance_id)
		
	var start = mob_pos + direction
	var end = mob_pos + (direction * (amount + 1))
		
	for new_possible_spot in range(start, end, direction):
		if new_possible_spot >= 0 and new_possible_spot < arena.current_arena_size:
			if arena.get_entity(new_possible_spot) == null:
				await signal_and_move_mob(mob, new_possible_spot)	

func move_mob_toward_sweet_spot(mob: Mob, amount: int):
	
	var distance: int = arena.get_distance_between(mob, GlobalGameManager.hero)
	
	if distance == mob.sweet_spot:
		return true
		
	var dir: int = arena.get_direction(GlobalGameManager.hero, mob)
	if distance > mob.sweet_spot: 
		# mob wants to move towards
		dir = dir * -1
		
	return await move_mob_direction(mob, amount, dir)
	
func signal_and_move_mob(mob: Mob, new_position: int):
	if new_position != -1:
		arena.move_and_signal(mob, new_position)
		
func get_priority_mob(damagePriority: OrderPriority) -> Mob:
	if arena == null:
		return null
	var mob_list: Array[Mob] = arena.get_mobs()
	var mobs_to_attack: Array[Mob] = get_mob_ordering(mob_list, damagePriority)
	
	if mobs_to_attack.size() >= 1:
		return mobs_to_attack[0]
	else:
		return null
	
func resolve_mob_turns():
	# TODO (maybe make order for backstrikers, attackers, then debuffers)
	var mob_order = get_mob_ordering(arena.get_mobs(), OrderPriority.LEFT_TO_RIGHT)
	
	for mob in mob_order:
		mob.block.amount = 0
		await mob.activate_next_move()

	for mob in mob_order:
		mob.decrement_all_status_effects()
		
	for mob in mob_order:
		mob.update_visible_intent()
		
