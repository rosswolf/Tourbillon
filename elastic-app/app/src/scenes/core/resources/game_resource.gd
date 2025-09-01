extends Resource
class_name GameResource

# When adding a new type here, be sure to update the get_resource_background_color function below
enum Type {
	UNKNOWN,
	GOLD,
	# Time resources (fill automatically)
	HEAT_TIME,        # Red (was PURPLE_TIME)
	PRECISION_TIME,   # Blue (was BLUE_TIME)
	MOMENTUM_TIME,    # Green (was GREEN_TIME)
	BALANCE_TIME,     # White (NEW)
	ENTROPY_TIME,     # Purple (NEW)
	INSPIRATION_TIME, # Gold (NEW)
	# Energy resources (consumed on use)
	HEAT_ENERGY,        # Red (was PURPLE_ENERGY)
	PRECISION_ENERGY,   # Blue (was BLUE_ENERGY)
	MOMENTUM_ENERGY,    # Green (was GREEN_ENERGY)
	BALANCE_ENERGY,     # White (NEW)
	ENTROPY_ENERGY,     # Purple (NEW)
	INSPIRATION_ENERGY, # Gold (NEW)
	# Legacy resources
	FORCE,
	DEPTH,
	NONE,
	# Legacy aliases for backward compatibility
	PURPLE_TIME = HEAT_TIME,
	BLUE_TIME = PRECISION_TIME,
	GREEN_TIME = MOMENTUM_TIME,
	PURPLE_ENERGY = HEAT_ENERGY,
	BLUE_ENERGY = PRECISION_ENERGY,
	GREEN_ENERGY = MOMENTUM_ENERGY
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
		# Time resources
		GameResource.Type.HEAT_TIME: __SpecificResourceAccessor.new(
			func(): return UiController.meters.get(Air.AirColor.HEAT, {}).get("time_remaining", 0) if UiController.meters.has(Air.AirColor.HEAT) else 0,
			func(value): GlobalSignals.signal_core_time_set(Air.AirColor.HEAT, value),
		),
		GameResource.Type.PRECISION_TIME: __SpecificResourceAccessor.new(
			func(): return UiController.meters.get(Air.AirColor.PRECISION, {}).get("time_remaining", 0) if UiController.meters.has(Air.AirColor.PRECISION) else 0,
			func(value): GlobalSignals.signal_core_time_set(Air.AirColor.PRECISION, value)
		),
		GameResource.Type.MOMENTUM_TIME: __SpecificResourceAccessor.new(
			func(): return UiController.meters.get(Air.AirColor.MOMENTUM, {}).get("time_remaining", 0) if UiController.meters.has(Air.AirColor.MOMENTUM) else 0,
			func(value): GlobalSignals.signal_core_time_set(Air.AirColor.MOMENTUM, value)
		),
		GameResource.Type.BALANCE_TIME: __SpecificResourceAccessor.new(
			func(): return UiController.meters.get(Air.AirColor.BALANCE, {}).get("time_remaining", 0) if UiController.meters.has(Air.AirColor.BALANCE) else 0,
			func(value): GlobalSignals.signal_core_time_set(Air.AirColor.BALANCE, value)
		),
		GameResource.Type.ENTROPY_TIME: __SpecificResourceAccessor.new(
			func(): return UiController.meters.get(Air.AirColor.ENTROPY, {}).get("time_remaining", 0) if UiController.meters.has(Air.AirColor.ENTROPY) else 0,
			func(value): GlobalSignals.signal_core_time_set(Air.AirColor.ENTROPY, value)
		),
		GameResource.Type.INSPIRATION_TIME: __SpecificResourceAccessor.new(
			func(): return UiController.meters.get(Air.AirColor.INSPIRATION, {}).get("time_remaining", 0) if UiController.meters.has(Air.AirColor.INSPIRATION) else 0,
			func(value): GlobalSignals.signal_core_time_set(Air.AirColor.INSPIRATION, value)
		),
		# Energy resources
		GameResource.Type.HEAT_ENERGY: __SpecificResourceAccessor.new(
			func(): return UiController.meters.get(Air.AirColor.HEAT, {}).get("current_energy", 0) if UiController.meters.has(Air.AirColor.HEAT) else 0,
			func(value): GlobalSignals.signal_core_energy_set(Air.AirColor.HEAT, value)
		),
		GameResource.Type.PRECISION_ENERGY: __SpecificResourceAccessor.new(
			func(): return UiController.meters.get(Air.AirColor.PRECISION, {}).get("current_energy", 0) if UiController.meters.has(Air.AirColor.PRECISION) else 0,
			func(value): GlobalSignals.signal_core_energy_set(Air.AirColor.PRECISION, value)
		),
		GameResource.Type.MOMENTUM_ENERGY: __SpecificResourceAccessor.new(
			func(): return UiController.meters.get(Air.AirColor.MOMENTUM, {}).get("current_energy", 0) if UiController.meters.has(Air.AirColor.MOMENTUM) else 0,
			func(value): GlobalSignals.signal_core_energy_set(Air.AirColor.MOMENTUM, value)
		),
		GameResource.Type.BALANCE_ENERGY: __SpecificResourceAccessor.new(
			func(): return UiController.meters.get(Air.AirColor.BALANCE, {}).get("current_energy", 0) if UiController.meters.has(Air.AirColor.BALANCE) else 0,
			func(value): GlobalSignals.signal_core_energy_set(Air.AirColor.BALANCE, value)
		),
		GameResource.Type.ENTROPY_ENERGY: __SpecificResourceAccessor.new(
			func(): return UiController.meters.get(Air.AirColor.ENTROPY, {}).get("current_energy", 0) if UiController.meters.has(Air.AirColor.ENTROPY) else 0,
			func(value): GlobalSignals.signal_core_energy_set(Air.AirColor.ENTROPY, value)
		),
		GameResource.Type.INSPIRATION_ENERGY: __SpecificResourceAccessor.new(
			func(): return UiController.meters.get(Air.AirColor.INSPIRATION, {}).get("current_energy", 0) if UiController.meters.has(Air.AirColor.INSPIRATION) else 0,
			func(value): GlobalSignals.signal_core_energy_set(Air.AirColor.INSPIRATION, value)
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
