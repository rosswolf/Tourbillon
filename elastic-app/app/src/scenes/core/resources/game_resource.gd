extends Resource
class_name GameResource

# When adding a new type here, be sure to update the get_resource_background_color function below
enum Type {
	UNKNOWN,
	# Player stats
	HP,        # Player health points
	# Color resources (5) - Basic color-based resources
	RED,
	BLUE,
	GREEN,
	WHITE,
	PURPLE,
	# Force resources (5) - Thematic mechanical resources
	HEAT,      # Friction and combustion energy
	PRECISION, # Control and accuracy
	MOMENTUM,  # Perpetual motion and growth
	BALANCE,   # Regulation and stability
	ENTROPY,   # Decay and chaos
	# Special (Per-run currency)
	INSPIRATION,  # Currency earned from defeating gremlins, spent at workshops
	# TODO: Implement INSPIRATION system:
	# - Award on gremlin defeat (amount based on gremlin difficulty)
	# - Track separately from forces (doesn't reset between combats)
	# - Spend at workshops for cards/upgrades
	# - Reset at end of run
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
		# Player stats
		GameResource.Type.HP: __SpecificResourceAccessor.new(
			func(): return GlobalGameManager.hero.hp.amount if GlobalGameManager.hero and GlobalGameManager.hero.hp else 0,
			func(value): if GlobalGameManager.hero and GlobalGameManager.hero.hp: GlobalGameManager.hero.hp.amount = value
		),
		# Color resources (5)
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
		# Force resources (5)
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
		# Special currency
		# TODO: INSPIRATION implementation
		# Currently stubbed - will need proper storage that persists between combats
		GameResource.Type.INSPIRATION: __SpecificResourceAccessor.new(
			func(): return GlobalGameManager.hero.inspiration.amount if GlobalGameManager.hero and GlobalGameManager.hero.has("inspiration") else 0,
			func(value): if GlobalGameManager.hero and GlobalGameManager.hero.has("inspiration"): GlobalGameManager.hero.inspiration.amount = value
		),
	}

	func get_count(resource_type: GameResource.Type) -> int:
		assert(__resources.has(resource_type), "Resource type must exist: " + str(resource_type))
		return __resources[resource_type].get_value()

	func increment(resource_type: GameResource.Type, amount: int = 1) -> void:
		__resources[resource_type].increment(amount)

	func decrement(resource_type: GameResource.Type, amount: int = 1) -> void:
		__resources[resource_type].decrement(amount)
