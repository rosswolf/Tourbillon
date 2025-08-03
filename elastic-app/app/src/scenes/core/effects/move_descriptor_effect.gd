extends Effect
class_name MoveDescriptorEffect

var effects: Array[Effect]
var move_list: Array[MoveParser.MovePiece] = []

func _init(move_descriptor: String, cost: Cost = null):
	move_list = MoveParser.parse_move_descriptor(move_descriptor)
	
	for move_piece in move_list:
		var effect: Effect = OneTimeEffect.new(move_piece.name, {"param": move_piece.value}, null)
		effects.append(effect)
		effect_name = effect_name + move_piece.name + " "
	
	# Make sure we add the overall cost if needed
	if cost != null:
		effects.append(OneTimeEffect.new("none", {}, cost))
	
func _could_satisfy_costs(source: Entity, target: Entity) -> bool:
	for effect in effects:
		if not effect._could_satisfy_costs(source, target):
			return false
			
	return true

func _execute_satisfy_costs(source: Entity, target: Entity) -> bool:
	for effect in effects:
		if not effect._execute_satisfy_costs(source, target):
			# This should be guarded by one_time_effect checking satisfy before executing satisfy
			assert(false, "failed to satisfy costs for effect, this shouldn't happen")
			return false
			
	return true
	
func _is_valid_source(source: Entity):
	for effect in effects:
		if not effect._is_valid_source(source):
			return false	
	return true
	
func _is_valid_target(source: Entity):
	for effect in effects:
		if not effect._is_valid_target(source):
			return false	
	return true
	
func activate(source: Entity):
	var result: bool = true
	for effect in effects:
		if not effect.activate(source):
			result = false
			
	return result
	
func get_intent_amount() -> int:
	var result: int = -1
	for move_piece in move_list:
		var intent: Effect.Intent = Effect.intent_map.get(move_piece.name, Intent.UNKNOWN)
		if move_piece.has_value and intent in [Intent.ATTACK_MELEE, Intent.ATTACK_RANGED]:
			result = 0
			if move_piece.repeat == 1:
				result += int(move_piece.value)
			else:
				result += int(move_piece.value) * move_piece.repeat
	return result
	
static func load_empty_move() -> MoveDescriptorEffect:
	return MoveDescriptorEffect.new("none=0")
