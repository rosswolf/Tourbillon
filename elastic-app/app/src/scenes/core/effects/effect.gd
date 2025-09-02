extends Node

class_name Effect

var effect_name: String = ""

class InternalEffect:
	var __f: Callable
	var __valid_source_types: Array
	var __valid_target_types: Array
	
	func _init(f: Callable, valid_types: Dictionary[String, Array]):
		__f = f
		__valid_source_types = valid_types.get("source", [Entity])
		__valid_target_types = valid_types.get("target", [Entity])
						
enum Intent {
	UNKNOWN,
	ATTACK_MELEE,
	ATTACK_RANGED,
	NON_ATTACK,
	MOVE
}

static var effect_map: Dictionary[String, InternalEffect] = {
	"none":  InternalEffect.new(
		func(source: Entity, params: Dictionary):
			return true,
		{} 
	),
	# Legacy time/energy effects removed - use force system instead
	"draw_card": InternalEffect.new(
		func(source: Entity, params: Dictionary):
			var amount = int(params.get("param"))
			GlobalGameManager.library.draw_card(amount)
			return true,
		{"source":[Hero, Card, Goal]}
	),

	"cooldown":  InternalEffect.new(
		func(source: Entity, params: Dictionary):
			var amount: float = float(params.get("param"))
			var card: Card = params.get("card") as Card
			GlobalSignals.signal_core_slot_add_cooldown(card.instance_id, amount)
			return true,
		{"source":[Hero, Card]}
	),
	"shop": InternalEffect.new(
		func(source: Entity, params: Dictionary):
			var shop_type: String = params.get("param")
			GlobalSignals.signal_core_card_selection(shop_type, Library.Zone.HAND)
			return true,
		{"source":[Hero, Card, Goal]}
	),
	"add_gold": InternalEffect.new(
		func(source: Entity, params: Dictionary):
			var amount: int = int(params.get("param"))
			GlobalGameManager.hero.gold.increment(amount)
			return true,
		{"source":[Hero, Card]}
	),
	"end_game": InternalEffect.new(
		func(source: Entity, params: Dictionary):
			GlobalSignals.signal_core_game_over()
			return true,
		{"source":[Hero, Card, Goal]}
	),
	"win": InternalEffect.new(
		func(source: Entity, params: Dictionary):
			GlobalSignals.signal_core_game_win()
			return true,
		{"source":[Hero, Card, Goal]}
	)
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

static func entity_in_types(source: Entity, valid_types: Array):
	var valid_type_strings: Array[String] = []
	for type in valid_types:
		valid_type_strings.append(type._get_type_string())
		
	var type_string = "None"
	if source != null:
		type_string = source._get_type_string()
	return type_string in valid_type_strings or Entity._get_type_string() in valid_type_strings
	


func __is_valid_source(source: Entity):
	assert(false, "sub classes need to override __is_valid_source")
	return false
	
func __is_valid_target(target: Entity):
	assert(false, "sub classes need to override __is_valid_target")
	return false
	
func __could_satisfy_costs(source: Entity, target: Entity) -> bool:
	assert(false, "sub classes need to override __could_satisfy_costs")
	return false
	
