extends Resource
class_name GameResource

# When adding a new type here, be sure to update the get_resource_background_color function below
enum Type {
	UNKNOWN,
	GOLD,
	# Core force resources
	HEAT,        # Red (was PURPLE)
	PRECISION,   # Blue (was BLUE)
	MOMENTUM,    # Green (was GREEN)
	BALANCE,     # White (NEW)
	ENTROPY,     # Purple (NEW)
	INSPIRATION, # Gold (NEW)
	# Legacy time resources (keeping for compatibility)
	PURPLE_TIME,
	GREEN_TIME,
	BLUE_TIME,
	PURPLE_ENERGY,
	GREEN_ENERGY,
	BLUE_ENERGY,
	# Legacy resources
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
			func(): return GlobalGameManager.hero.gold.amount if GlobalGameManager.hero and GlobalGameManager.hero.gold else 0,
			func(value): if GlobalGameManager.hero and GlobalGameManager.hero.gold: GlobalGameManager.hero.gold.amount = value
		),
		# Core force resources
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
		GameResource.Type.INSPIRATION: __SpecificResourceAccessor.new(
			func(): return GlobalGameManager.hero.inspiration.amount if GlobalGameManager.hero and GlobalGameManager.hero.inspiration else 0,
			func(value): if GlobalGameManager.hero and GlobalGameManager.hero.inspiration: GlobalGameManager.hero.inspiration.amount = value
		),
		# Legacy time resources (keeping for compatibility)
		GameResource.Type.PURPLE_TIME: __SpecificResourceAccessor.new(
			func(): return UiController.meters[Air.AirColor.PURPLE].time_remaining if UiController.meters.has(Air.AirColor.PURPLE) else 0,
			func(value): GlobalSignals.signal_core_time_set(Air.AirColor.PURPLE, value),
		),
		GameResource.Type.GREEN_TIME: __SpecificResourceAccessor.new(
			func(): return UiController.meters[Air.AirColor.GREEN].time_remaining if UiController.meters.has(Air.AirColor.GREEN) else 0,
			func(value): GlobalSignals.signal_core_time_set(Air.AirColor.GREEN, value)
		),	
		GameResource.Type.BLUE_TIME: __SpecificResourceAccessor.new(
			func(): return UiController.meters[Air.AirColor.BLUE].time_remaining if UiController.meters.has(Air.AirColor.BLUE) else 0,
			func(value): GlobalSignals.signal_core_time_set(Air.AirColor.BLUE, value)
		),
		GameResource.Type.PURPLE_ENERGY: __SpecificResourceAccessor.new(
			func(): return UiController.meters[Air.AirColor.PURPLE].current_energy if UiController.meters.has(Air.AirColor.PURPLE) else 0,
			func(value): GlobalSignals.signal_core_energy_set(Air.AirColor.PURPLE, value)
		),
		GameResource.Type.GREEN_ENERGY: __SpecificResourceAccessor.new(
			func(): return UiController.meters[Air.AirColor.GREEN].current_energy if UiController.meters.has(Air.AirColor.GREEN) else 0,
			func(value): GlobalSignals.signal_core_energy_set(Air.AirColor.GREEN, value)
		),
		GameResource.Type.BLUE_ENERGY: __SpecificResourceAccessor.new(
			func(): return UiController.meters[Air.AirColor.BLUE].current_energy if UiController.meters.has(Air.AirColor.BLUE) else 0,
			func(value): GlobalSignals.signal_core_energy_set(Air.AirColor.BLUE, value)
		),
		GameResource.Type.FORCE: __SpecificResourceAccessor.new(
			func(): return GlobalGameManager.hero.force.amount if GlobalGameManager.hero and GlobalGameManager.hero.force else 0,
			func(value): if GlobalGameManager.hero and GlobalGameManager.hero.force: GlobalGameManager.hero.force.amount = value
		),
		GameResource.Type.DEPTH: __SpecificResourceAccessor.new(
			func(): return GlobalGameManager.hero.depth.amount if GlobalGameManager.hero and GlobalGameManager.hero.depth else 0,
			func(value): if GlobalGameManager.hero and GlobalGameManager.hero.depth: GlobalGameManager.hero.depth.amount = value
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
