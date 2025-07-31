extends Node

class_name MoveParser

class MovePiece:
	var name: String
	var has_value: bool = false
	var value: int = -1
	var repeat: int = 1
	var intent: Effect.Intent = Effect.Intent.UNKNOWN
	
	func with_name(name_in: String) -> MovePiece:
		name = name_in
		intent = Effect.intent_map.get(name, Effect.Intent.UNKNOWN)
		return self
		
	func with_value(value_in: int) -> MovePiece:
		value = value_in
		if value_in != 0:
			has_value = true
		return self
	
	func with_repeat(repeat_in: int) -> MovePiece:
		repeat = repeat_in
		return self
		
	func get_value() -> int:
		if has_value:
			return value
		else:
			return -1
			
	func get_label() -> String:
		if not has_value:
			return ""
		if not intent in [Effect.Intent.ATTACK_MELEE, Effect.Intent.ATTACK_RANGED, Effect.Intent.MOVE]:
			return ""
		else:
			if repeat == 1:
				return str(value)
			else:
				return str(value) + "x" + str(repeat)

static func parse_move_descriptor(move_descriptor: String) -> Array[MovePiece]:
	
	var results: Array[MovePiece] = []
	
	var tokens = move_descriptor.split(",")
	
	for token in tokens:
		var parts = token.split("=")
		if parts.size() != 2:
			assert(false, "Warning: Invalid token format: " + token)
			continue
			
		var move_name = parts[0].strip_edges()
	
		var move_param = parts[1].strip_edges()
				
		if move_param.length() == 0:	
			results.append(MovePiece.new().with_name(move_name))
		elif move_param.is_valid_int():
			var amount: int = int(move_param)
		
			results.append(MovePiece.new().with_name(move_name).with_value(amount))
		else:
		
			var param_parts = move_param.split("x")
			if param_parts.size() != 2 or (not param_parts[0].is_valid_int()) or (not param_parts[1].is_valid_int()):
				assert(false, "warning, params isnt an int nor is it in the format NxM for a multi hit")
				continue
			
			var amount = int(param_parts[0])
			var repeat = int(param_parts[1]) 
		
			results.append(MovePiece.new().with_name(move_name).with_value(amount).with_repeat(repeat))
				
	
	return results
