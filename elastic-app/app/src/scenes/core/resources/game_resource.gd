extends Resource
class_name GameResource

# When adding a new type here, be sure to update the get_resource_background_color function below
enum Type {
	UNKNOWN,
	GOLD,
	RED_TIME,
	ORANGE_TIME,
	BLUE_TIME,
	RED_ENERGY,
	ORANGE_ENERGY,
	BLUE_ENERGY,
	FORCE,
	DEPTH,
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
		GameResource.Type.GOLD: __SpecificResourceAccessor.new(
			func(): return GlobalGameManager.hero.gold.amount,
			func(value): GlobalGameManager.hero.gold.amount = value
		),
		# TODO
		GameResource.Type.RED_TIME: __SpecificResourceAccessor.new(
			func(): assert(false,""),
			func(value): assert(false,"")
		),
		GameResource.Type.ORANGE_TIME: __SpecificResourceAccessor.new(
			func(): assert(false,""),
			func(value): assert(false,"")
		),	
		GameResource.Type.BLUE_TIME: __SpecificResourceAccessor.new(
			func(): assert(false,""),
			func(value): assert(false,"")
		),
		GameResource.Type.RED_ENERGY: __SpecificResourceAccessor.new(
			func(): assert(false,""),
			func(value): assert(false,"")
		),
		GameResource.Type.ORANGE_ENERGY: __SpecificResourceAccessor.new(
			func(): assert(false,""),
			func(value): assert(false,"")
		),
		GameResource.Type.BLUE_ENERGY: __SpecificResourceAccessor.new(
			func(): assert(false,""),
			func(value): assert(false,"")
		),
		GameResource.Type.FORCE: __SpecificResourceAccessor.new(
			func(): return GlobalGameManager.hero.force.amount,
			func(value): GlobalGameManager.hero.force.amount = value
		),
		GameResource.Type.DEPTH: __SpecificResourceAccessor.new(
			func(): return GlobalGameManager.hero.depth.amount,
			func(value): GlobalGameManager.hero.depth.amount = value
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
