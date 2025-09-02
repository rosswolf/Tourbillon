extends Resource
class_name GameResource

# When adding a new type here, be sure to update the get_resource_background_color function below
enum Type {
	UNKNOWN,
	# Core force resources (from PRD)
	HEAT,        # Red - Attack All
	PRECISION,   # Blue - Attack Bottom
	MOMENTUM,    # Green - Attack Top
	BALANCE,     # White - Defense/Health
	ENTROPY,     # Purple - Randomness/Chaos
	# UI/Color resources (for backward compatibility)
	GOLD,
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
		
		func _init(g: Callable, s: Callable):
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
		# Core force resources from PRD
		GameResource.Type.HEAT: __SpecificResourceAccessor.new(
			func(): return GlobalGameManager.hero.heat.amount if GlobalGameManager.hero and GlobalGameManager.hero.heat else 0,
			func(value): if GlobalGameManager.hero and GlobalGameManager.hero.heat: GlobalGameManager.hero.heat.amount = value
		),
		GameResource.Type.PRECISION: __SpecificResourceAccessor.new(
			func(): return GlobalGameManager.hero.precision.amount if GlobalGameManager.hero and GlobalGameManager.hero.precision else 0,
			func(value): if GlobalGameManager.hero and GlobalGameManager.hero.precision: GlobalGameManager.hero.precision.amount = value
		),
		GameResource.Type.MOMENTUM: __SpecificResourceAccessor.new(
			func(): return GlobalGameManager.hero.momentum.amount if GlobalGameManager.hero and GlobalGameManager.hero.momentum else 0,
			func(value): if GlobalGameManager.hero and GlobalGameManager.hero.momentum: GlobalGameManager.hero.momentum.amount = value
		),
		GameResource.Type.BALANCE: __SpecificResourceAccessor.new(
			func(): return GlobalGameManager.hero.balance.amount if GlobalGameManager.hero and GlobalGameManager.hero.balance else 0,
			func(value): if GlobalGameManager.hero and GlobalGameManager.hero.balance: GlobalGameManager.hero.balance.amount = value
		),
		GameResource.Type.ENTROPY: __SpecificResourceAccessor.new(
			func(): return GlobalGameManager.hero.entropy.amount if GlobalGameManager.hero and GlobalGameManager.hero.entropy else 0,
			func(value): if GlobalGameManager.hero and GlobalGameManager.hero.entropy: GlobalGameManager.hero.entropy.amount = value
		),
	}
	
	func get_count(resource_type: GameResource.Type) -> int:
		if not __resources.has(resource_type):
			return 0
		return __resources[resource_type].get_value()
		
	func increment(resource_type: GameResource.Type, amount: int = 1) -> void:
		__resources[resource_type].increment(amount)
		
	func decrement(resource_type: GameResource.Type, amount: int = 1) -> void:
		__resources[resource_type].decrement(amount)
