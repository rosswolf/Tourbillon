extends Node

class_name Effect

var effect_name: String = ""

class InternalEffect:
	var __f: Callable
	var __valid_source_types: Array
	
	func _init(f: Callable, valid_source_types: Array):
		__f = f
		__valid_source_types = valid_source_types
						
enum Intent {
	UNKNOWN,
	ATTACK_MELEE,
	ATTACK_RANGED,
	NON_ATTACK,
	MOVE
}

static var effect_map: Dictionary[String, InternalEffect] = {
	"heal_ally": InternalEffect.new(
		func(source: Entity, params: Dictionary):
			var amount: int = int(params.get("param", 0))
			return await GlobalGameManager.battleground.mob_heal_ally(source, amount),
		[]
	),
	"pull": InternalEffect.new(
		func(source: Entity, params: Dictionary):
			return await GlobalGameManager.battleground.unit_pull(source),
		[Hero]
	),
	"bump": InternalEffect.new(
		func(source: Entity, params: Dictionary):
			return await GlobalGameManager.battleground.bump(source),
		[Hero]
	),
	"aoe3_attack": InternalEffect.new(
		func(source: Entity, params: Dictionary):
			var damage: int = int(params.get("param", 0))
			return await GlobalGameManager.battleground.aoe_attack(GlobalGameManager.hero, damage, 3),
		[Hero]
	),
	#"attack_direction": InternalEffect.new(
		#func(source: Entity, params: Dictionary):
			#var damage: int = int(params.get("param", 0))
			#var targeting: Battleground.OrderPriority = int(params.get("targeting", Battleground.OrderPriority.UNKNOWN))
			#return await GlobalGameManager.battleground.unit_attack_with_targeting(source, damage, targeting),
		#[Hero]
	#),
	"dash": InternalEffect.new(
		func(source: Entity, params: Dictionary):
			return await GlobalGameManager.battleground.unit_dash(source),
		[Hero]
	),
	"heal": InternalEffect.new(
		func(source: Entity, params: Dictionary):
			var how_many = int(params.get("param"))
			if source is Hero:
				GlobalGameManager.hero.health.increment(how_many)
				return true,
		[Hero]
	),
	"add_armor": InternalEffect.new(
		func(source: Entity, params: Dictionary):
			var value = int(params.get("param"))
			GlobalGameManager.hero.armor.increment(value)
			return true,
		[Hero]
	),
	"set_armor": InternalEffect.new(
		func(source: Entity, params: Dictionary):
			var value = int(params.get("param"))
			GlobalGameManager.hero.armor.amount = value
			return true,
		[Hero]
	),
	"add_gold": InternalEffect.new(
		func(source: Entity, params: Dictionary):
			var how_many = int(params.get("param"))
			GlobalGameManager.hero.gold.increment(how_many)
			return true,
		[Hero]
	),
	"add_instinct": InternalEffect.new(
		func(source: Entity, params: Dictionary):
			var how_many = int(params.get("param"))
			GlobalGameManager.hero.instinct.increment(how_many)
			return true,
		[Hero]
	),
	"add_training": InternalEffect.new(
		func(source: Entity, params: Dictionary):
			var how_many = int(params.get("param"))
			GlobalGameManager.hero.training_points.increment(how_many)
			return true,
		[Hero]
	),
	"add_endurance": InternalEffect.new(
		func(source: Entity, params: Dictionary):
			var how_many = int(params.get("param"))
			GlobalGameManager.hero.endurance.increment(how_many)
			return true,
		[Hero]
	),
	#"jump": InternalEffect.new(
		#func(source: Entity, params: Dictionary):
			##TODO: implement move
			#return true,
		#[Hero, Mob]
	#),
	"none":  InternalEffect.new(
		func(source: Entity, params: Dictionary):
			return true,
		[Hero, Card]
		),
	"attack_melee": InternalEffect.new(
		func(source: Entity, params: Dictionary):
			var damage: int = int(params.get("param", 0))
			return await GlobalGameManager.battleground.unit_attack_melee(source, damage),
		[Hero]
	),
	"attack": InternalEffect.new(
		func(source: Entity, params: Dictionary):
			var damage: int = int(params.get("param", 0))
			return await GlobalGameManager.battleground.unit_attack_range(source, damage),
		[Hero]
	),
	"block": InternalEffect.new(
		func(source: Entity, params: Dictionary):
			var new_block = int(params.get("param"))
			if source is Hero:
				GlobalGameManager.hero.block.increment(new_block)
				return true,
		[Hero]
	),
	"replenish_time": InternalEffect.new(
		func(source: Entity, params: Dictionary):
			var amount = int(params.get("param"))
			GlobalGameManager.hero.time.replenish_time(amount)
			return true,
		[Hero, Card] 
	),
	"add_time": InternalEffect.new(
		func(source: Entity, params: Dictionary):
			var amount = int(params.get("param"))
			GlobalGameManager.hero.time.add_time(amount)
			return true,
		[Hero, Card] 
	),
	"add_energy": InternalEffect.new(
		func(source: Entity, params: Dictionary):
			var amount = int(params.get("param"))
			GlobalGameManager.hero.energy.increment(amount)
			return true,
		[Hero, Card] 
	),
	"draw_card": InternalEffect.new(
		func(source: Entity, params: Dictionary):
			var amount = int(params.get("param"))
			GlobalGameManager.library.draw_card(amount)
			return true,
		[Hero, Card] 
	),
}

static var intent_map: Dictionary[String, Intent] = {
	"dash": Intent.MOVE,
	"heal": Intent.NON_ATTACK,
	"add_armor": Intent.UNKNOWN,
	"add_gold": Intent.UNKNOWN,
	"add_instinct": Intent.UNKNOWN,
	"add_training": Intent.UNKNOWN,
	"add_endurance": Intent.UNKNOWN,
	"jump": Intent.UNKNOWN,
	"effect_none": Intent.UNKNOWN,
	"attack": Intent.ATTACK_RANGED,
	"attack_melee": Intent.ATTACK_MELEE,
	"block": Intent.NON_ATTACK,
	"remove_card_from_deck": Intent.UNKNOWN,
	"stun": Intent.UNKNOWN,
	"trip": Intent.UNKNOWN,
	"knockback": Intent.UNKNOWN,
	"slime": Intent.NON_ATTACK,
	"reduce_block":  Intent.NON_ATTACK,
	"weaken": Intent.NON_ATTACK,
	"increase_strength":  Intent.NON_ATTACK,
	"move":  Intent.MOVE,
	"helicopter" : Intent.UNKNOWN,
	"aoe3_attack" : Intent.UNKNOWN
}

static func source_is_valid(source: Entity, valid_types: Array):
	var source_class = source.get_class()
	return source_class in valid_types
	
func _could_satisfy_costs(source: Entity, target: Entity) -> bool:
	assert(false, "sub classes need to override _could_satisfy_costs")
	return false
	
