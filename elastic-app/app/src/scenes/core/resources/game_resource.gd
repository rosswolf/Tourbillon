extends Resource
class_name GameResource

# When adding a new type here, be sure to update the get_resource_background_color function below
enum Type {
	UNKNOWN,
	GOLD,
	PURPLE_TIME,
	GREEN_TIME,
	BLUE_TIME,
	PURPLE_ENERGY,
	GREEN_ENERGY,
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
		GameResource.Type.PURPLE_TIME: __SpecificResourceAccessor.new(
			func(): return UiController.meters[Air.AirColor.PURPLE].time_remaining,
			func(value): GlobalSignals.signal_core_time_set(Air.AirColor.PURPLE, value)
		),
		GameResource.Type.GREEN_TIME: __SpecificResourceAccessor.new(
			func(): return UiController.meters[Air.AirColor.GREEN].time_remaining,
			func(value): GlobalSignals.signal_core_time_set(Air.AirColor.GREEN, value)
		),	
		GameResource.Type.BLUE_TIME: __SpecificResourceAccessor.new(
			func(): return UiController.meters[Air.AirColor.BLUE].time_remaining,
			func(value): GlobalSignals.signal_core_time_set(Air.AirColor.BLUE, value)
		),
		GameResource.Type.PURPLE_ENERGY: __SpecificResourceAccessor.new(
			func(): return UiController.meters[Air.AirColor.PURPLE].current_energy,
			func(value): GlobalSignals.signal_core_energy_set(Air.AirColor.PURPLE, value)
		),
		GameResource.Type.GREEN_ENERGY: __SpecificResourceAccessor.new(
			func(): return UiController.meters[Air.AirColor.GREEN].current_energy,
			func(value): GlobalSignals.signal_core_energy_set(Air.AirColor.GREEN, value)
		),
		GameResource.Type.BLUE_ENERGY: __SpecificResourceAccessor.new(
			func(): return UiController.meters[Air.AirColor.BLUE].current_energy,
			func(value): GlobalSignals.signal_core_energy_set(Air.AirColor.BLUE, value)
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
