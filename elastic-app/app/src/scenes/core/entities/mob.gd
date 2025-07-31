extends BattleEntity
class_name Mob

var __movement_range: int
var movement_range: int:
	get:
		if has_status_effect(StatusEffect.Type.SLOW):
			return max(0, __movement_range - 1)
		if has_status_effect(StatusEffect.Type.TRIPPED):
			return 0
		return __movement_range
	set(value):
		__movement_range = value

var __possible_moves_in_range: Array[MoveDescriptorEffect] = []
var __possible_moves_out_of_range: Array[MoveDescriptorEffect] = []
var __next_move: MoveDescriptorEffect = MoveDescriptorEffect.load_empty_move()

var team: String = "mobs"

var sweet_spot : int = 1 # Ideal distance to Hero when attacking.  

func _init() -> void:
	GlobalSignals.core_mob_created.connect(__on_core_mob_created)
	
func __on_core_mob_created(mob_id: String):
	if instance_id == mob_id:
		__pick_next_move()
		
func __pick_next_move():
	if has_status_effect(StatusEffect.Type.STUNNED):
		__next_move = MoveDescriptorEffect.load_empty_move()
	else:	
		if GlobalGameManager.battleground.arena.get_position(self.instance_id) == -1:
			return
		
		if GlobalGameManager.battleground.can_attack_target(self, GlobalGameManager.hero, 1):
			__next_move = __possible_moves_in_range.pick_random()
		else:
			__next_move = __possible_moves_out_of_range.pick_random()
	
func __stun():
	__next_move = MoveDescriptorEffect.load_empty_move()
	update_visible_intent()
	
func activate_next_move():
	if __next_move:
		await __next_move.activate(self)	
		__pick_next_move()
	
func update_visible_intent():
	GlobalSignals.signal_core_mob_intent_updated(self.instance_id)

func get_move_pieces() -> Array[MoveParser.MovePiece]:
	return __next_move.move_list

func is_attacking() -> bool:
	for move_piece in __next_move.move_list:
		if move_piece.intent in [Effect.Intent.ATTACK_MELEE, Effect.Intent.ATTACK_RANGED]:
			return true
	return false

func get_next_move_damage():
	return BattleEntity.apply_damage_modifiers(self, GlobalGameManager.hero, __next_move.get_attack_amount()) 
	
func is_flyer() -> bool:
	return __status_effects.has(StatusEffect.Type.FLYING)
	
	

func signal_moved(new_position: int) -> void:
	GlobalSignals.signal_core_mob_moved(instance_id, new_position)

func signal_created() -> void:
	GlobalSignals.signal_core_mob_created(instance_id)
		
func add_status_effect(effect: StatusEffect.Type, duration: int = 1):
	if effect == StatusEffect.Type.CARELESS:
		block.amount = 0
		if duration != 0:
			assert(false, "CARLESS must have a duration of 0, since it is only immediate")
	
	if duration == 0:
		return

	if __status_effects.has(effect):
		__status_effects[effect] = __status_effects[effect] + duration
	else:
		__status_effects[effect] = duration
		
	if effect == StatusEffect.Type.STUNNED:
		__stun()
		
func _generate_instance_id() -> String:
	return "mob_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())
	
static func load_mob(mob_template_id: String) -> Mob:
	var builder = Mob.MobBuilder.new()
	var mob_data = StaticData.mob_data.get(mob_template_id)
	
	if mob_data == null:
		assert(false, "Mob template not found: " + mob_template_id)
		return null
	
	builder.with_template_id(mob_template_id)
	builder.with_display_name(mob_data.get("display_name"))
	builder.with_max_health(int(mob_data.get("max_health")))
	builder.with_max_armor(int(mob_data.get("max_armor")))
	builder.with_move(mob_data.get("in_range_1",""), Arena.DecisionType.IN_RANGE)
	builder.with_move(mob_data.get("in_range_2",""), Arena.DecisionType.IN_RANGE)
	builder.with_move(mob_data.get("in_range_3",""), Arena.DecisionType.IN_RANGE)
	builder.with_move(mob_data.get("in_range_4",""), Arena.DecisionType.IN_RANGE)
	builder.with_move(mob_data.get("in_range_5",""), Arena.DecisionType.IN_RANGE)
	builder.with_move(mob_data.get("in_range_6",""), Arena.DecisionType.IN_RANGE)
	builder.with_move(mob_data.get("out_of_range_1",""), Arena.DecisionType.OUT_OF_RANGE)
	builder.with_move(mob_data.get("out_of_range_2",""), Arena.DecisionType.OUT_OF_RANGE)
	builder.with_move(mob_data.get("out_of_range_3",""), Arena.DecisionType.OUT_OF_RANGE)
	builder.with_move(mob_data.get("out_of_range_4",""), Arena.DecisionType.OUT_OF_RANGE)
	builder.with_move(mob_data.get("out_of_rangee_5",""), Arena.DecisionType.OUT_OF_RANGE)
	builder.with_move(mob_data.get("out_of_range_6",""), Arena.DecisionType.OUT_OF_RANGE)
	builder.with_sweet_spot(mob_data.get("sweet_spot", 1))
	builder.with_movement_range(int(mob_data.get("movement", 1)))
	
	var mob = builder.build()
	return mob

class MobBuilder extends Entity.EntityBuilder:
	# Building properties to build
	var __max_health: int
	var __max_armor: int
	var __move_descriptors_in_range: Array[String] = []
	var __move_descriptors_out_of_range: Array[String] = []
	var __attack_range: int
	var __movemment_range: int
	var __sweet_spot: int
	
	func with_max_health(max_health: int) -> MobBuilder:
		__max_health = max_health
		return self
	
	func with_max_armor(max_armor: int) -> MobBuilder:
		__max_armor = max_armor
		return self
			
	func with_move(move_descriptor: String, decision_type: Arena.DecisionType) -> MobBuilder:
		if decision_type == Arena.DecisionType.IN_RANGE:
			__move_descriptors_in_range.append(move_descriptor)
		elif decision_type == Arena.DecisionType.OUT_OF_RANGE:
			__move_descriptors_out_of_range.append(move_descriptor)
		return self
	
	func with_movement_range(movement_in: int):
		__movemment_range = movement_in
		return self
		
	func with_sweet_spot(sweet_spot_in: int):
		__sweet_spot = sweet_spot_in
		return self
	
	
	func build() -> Mob:
		var mob = Mob.new()
		var empty_callable: Callable = func(dummy): pass
		

		super.build_entity(mob)
		
		var on_health_change: Callable = func(value): 
			GlobalSignals.signal_core_mob_resource_changed(mob.instance_id, GameResource.Type.CURRENT_HEALTH, value)
			GlobalSignals.signal_core_mob_check_state(mob.instance_id, value)
		
		mob.health = CappedResource.new(__max_health, __max_health, on_health_change, empty_callable, true)
		var on_block_change: Callable = func(value): 
			GlobalSignals.signal_core_mob_resource_changed(mob.instance_id, GameResource.Type.BLOCK, value)
		mob.block = CappedResource.new(0, 1000000, on_block_change, empty_callable, false)
		var on_armor_change: Callable = func(value): 
			GlobalSignals.signal_core_mob_resource_changed(mob.instance_id, GameResource.Type.ARMOR, value)
		mob.armor = CappedResource.new(__max_armor, __max_armor, on_armor_change, empty_callable, false)

		mob.sweet_spot = __sweet_spot
		
		for move_descriptor in __move_descriptors_in_range:
			if move_descriptor == "":
				continue
			var move = MoveDescriptorEffect.new(move_descriptor)
			if move != null:
				mob.__possible_moves_in_range.append(move) 
		for move_descriptor in __move_descriptors_out_of_range:
			if move_descriptor == "":
				continue
			var move = MoveDescriptorEffect.new(move_descriptor)
			if move != null:
				mob.__possible_moves_out_of_range.append(move) 
		mob.movement_range = __movemment_range
		mob.__pick_next_move()
		return mob
