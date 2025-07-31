extends Resource
class_name GameResource

# When adding a new type here, be sure to update the get_resource_background_color function below
enum Type {
	UNKNOWN,
	GOLD,
	BLOCK,
	ARMOR,
	MAX_ARMOR,
	CURRENT_HEALTH,
	MAX_HEALTH,
	INSTINCT,
	TRAINING_POINTS,
	ENDURANCE,
	RED_TRIGGER,
	GREEN_TRIGGER,
	BLUE_TRIGGER,
	RANDOM_TRIGGER,
	ALL_TRIGGER,
	NONE
}

# The background color when displaying the cost on the card
static func get_activation_background_color(type: Type) -> Color:
	if type == Type.RED_TRIGGER:
		return Color.RED
	elif type == Type.BLUE_TRIGGER:
		return Color.BLUE
	elif type == Type.GREEN_TRIGGER:
		return Color.GREEN
	elif type == Type.ALL_TRIGGER:
		return Color.BLACK
	else:
		return Color.GRAY	 
		
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
		GameResource.Type.BLOCK: __SpecificResourceAccessor.new(
			func(): return GlobalGameManager.hero.block.amount,
			func(value): GlobalGameManager.hero.block.amount = value
		),
		GameResource.Type.CURRENT_HEALTH: __SpecificResourceAccessor.new(
			func(): return GlobalGameManager.hero.health.amount,
			func(value): GlobalGameManager.hero.health.amount = value
		),
		GameResource.Type.MAX_HEALTH: __SpecificResourceAccessor.new(
			func(): return GlobalGameManager.hero.health.max_amount,
			func(value): GlobalGameManager.hero.health.max_amount = value
		),
		GameResource.Type.GOLD: __SpecificResourceAccessor.new(
			func(): return GlobalGameManager.hero.gold.amount,
			func(value): GlobalGameManager.hero.gold.amount = value
		),
		GameResource.Type.INSTINCT: __SpecificResourceAccessor.new(
			func(): return GlobalGameManager.hero.instinct.amount,
			func(value): GlobalGameManager.hero.instinct.amount = value
		),
		GameResource.Type.ENDURANCE: __SpecificResourceAccessor.new(
			func(): return GlobalGameManager.hero.endurance.amount,
			func(value): GlobalGameManager.hero.endurance.amount = value
		),
		GameResource.Type.TRAINING_POINTS: __SpecificResourceAccessor.new(
			func(): return GlobalGameManager.hero.training_points.amount,
			func(value): GlobalGameManager.hero.training_points.amount = value
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
