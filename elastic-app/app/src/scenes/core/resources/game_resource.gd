extends Resource
class_name GameResource

# When adding a new type here, be sure to update the get_resource_background_color function below
enum Type {
	UNKNOWN,
	# Force resources (5) - Each force has both a name and color
	# Heat/Red - Friction and combustion energy
	RED,
	HEAT = RED,  # Alias for clarity
	# Precision/Blue - Control and accuracy
	BLUE,
	PRECISION = BLUE,  # Alias for clarity
	# Momentum/Green - Perpetual motion and growth
	GREEN,
	MOMENTUM = GREEN,  # Alias for clarity
	# Balance/White - Regulation and stability
	WHITE,
	BALANCE = WHITE,  # Alias for clarity
	# Entropy/Purple - Decay and chaos
	PURPLE,
	ENTROPY = PURPLE,  # Alias for clarity
	# Special
	INSPIRATION,
	# Legacy (for backward compatibility)
	GOLD = INSPIRATION,  # Alias for INSPIRATION
	PURPLE_TIME,
	GREEN_TIME,
	BLUE_TIME,
	PURPLE_ENERGY,
	GREEN_ENERGY,
	BLUE_ENERGY,
	NONE
}

		
class ResourceAccessor:
	class __SpecificResourceAccessor:
		var getter: Callable
		var setter: Callable
		
		func _init(g: Callable, s: Callable) -> void:
			getter = g
			setter = s
		
		func get_value() -> int:
			return getter.call() as int
			
		func set_value(value: int) -> void:
			setter.call(value)
			
		func increment(amount: int = 1) -> void:
			setter.call(getter.call() + amount)
			
		func decrement(amount: int = 1) -> void:
			setter.call(getter.call() - amount)
	
	var __resources: Dictionary = {
		# Force resources (5) - Only need one accessor per force since colors and names are aliases
		GameResource.Type.RED: __SpecificResourceAccessor.new(
			func(): return GlobalGameManager.hero.red.amount if GlobalGameManager.hero and GlobalGameManager.hero.red else 0,
			func(value): if GlobalGameManager.hero and GlobalGameManager.hero.red: GlobalGameManager.hero.red.amount = value
		),
		GameResource.Type.BLUE: __SpecificResourceAccessor.new(
			func(): return GlobalGameManager.hero.blue.amount if GlobalGameManager.hero and GlobalGameManager.hero.blue else 0,
			func(value): if GlobalGameManager.hero and GlobalGameManager.hero.blue: GlobalGameManager.hero.blue.amount = value
		),
		GameResource.Type.GREEN: __SpecificResourceAccessor.new(
			func(): return GlobalGameManager.hero.green.amount if GlobalGameManager.hero and GlobalGameManager.hero.green else 0,
			func(value): if GlobalGameManager.hero and GlobalGameManager.hero.green: GlobalGameManager.hero.green.amount = value
		),
		GameResource.Type.WHITE: __SpecificResourceAccessor.new(
			func(): return GlobalGameManager.hero.white.amount if GlobalGameManager.hero and GlobalGameManager.hero.white else 0,
			func(value): if GlobalGameManager.hero and GlobalGameManager.hero.white: GlobalGameManager.hero.white.amount = value
		),
		GameResource.Type.PURPLE: __SpecificResourceAccessor.new(
			func(): return GlobalGameManager.hero.purple.amount if GlobalGameManager.hero and GlobalGameManager.hero.purple else 0,
			func(value): if GlobalGameManager.hero and GlobalGameManager.hero.purple: GlobalGameManager.hero.purple.amount = value
		),
	}
	
	func get_count(resource_type: GameResource.Type) -> int:
		assert(__resources.has(resource_type), "Resource type must exist: " + str(resource_type))
		return __resources[resource_type].get_value()
		
	func increment(resource_type: GameResource.Type, amount: int = 1) -> void:
		__resources[resource_type].increment(amount)
		
	func decrement(resource_type: GameResource.Type, amount: int = 1) -> void:
		__resources[resource_type].decrement(amount)
