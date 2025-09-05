extends BattleEntity
class_name Hero
static func _get_type_string():
	return "Hero"


var image_name: String
var starting_relic: String


# Color resources (5)
var red: CappedResource
var blue: CappedResource
var green: CappedResource
var white: CappedResource
var purple: CappedResource

# Force resources (5)
var heat: CappedResource
var precision: CappedResource
var momentum: CappedResource
var balance: CappedResource
var entropy: CappedResource

func _init() -> void:
	# Initialize all 10 resources with proper signal callbacks
	var noop = func(v): pass

	# Color resources with signal emission
	red = CappedResource.new(0, 10,
		func(v): GlobalSignals.signal_core_hero_resource_changed(GameResource.Type.RED, v),
		noop)
	blue = CappedResource.new(0, 10,
		func(v): GlobalSignals.signal_core_hero_resource_changed(GameResource.Type.BLUE, v),
		noop)
	green = CappedResource.new(0, 10,
		func(v): GlobalSignals.signal_core_hero_resource_changed(GameResource.Type.GREEN, v),
		noop)
	white = CappedResource.new(0, 10,
		func(v): GlobalSignals.signal_core_hero_resource_changed(GameResource.Type.WHITE, v),
		noop)
	purple = CappedResource.new(0, 10,
		func(v): GlobalSignals.signal_core_hero_resource_changed(GameResource.Type.PURPLE, v),
		noop)

	# Force resources with signal emission
	heat = CappedResource.new(0, 10,
		func(v): GlobalSignals.signal_core_hero_resource_changed(GameResource.Type.HEAT, v),
		noop)
	precision = CappedResource.new(0, 10,
		func(v): GlobalSignals.signal_core_hero_resource_changed(GameResource.Type.PRECISION, v),
		noop)
	momentum = CappedResource.new(0, 10,
		func(v): GlobalSignals.signal_core_hero_resource_changed(GameResource.Type.MOMENTUM, v),
		noop)
	balance = CappedResource.new(0, 10,
		func(v): GlobalSignals.signal_core_hero_resource_changed(GameResource.Type.BALANCE, v),
		noop)
	entropy = CappedResource.new(0, 10,
		func(v): GlobalSignals.signal_core_hero_resource_changed(GameResource.Type.ENTROPY, v),
		noop)

# Legacy TimeResource and EnergyResource removed - use force system instead
func _get_type() -> Entity.EntityType:
	return Entity.EntityType.HERO



func reset_start_of_battle() -> void:
	pass

## Get a resource by type (colors or forces)
func get_force_resource(force_type: GameResource.Type) -> CappedResource:
	match force_type:
		# Color resources
		GameResource.Type.RED:
			return red
		GameResource.Type.BLUE:
			return blue
		GameResource.Type.GREEN:
			return green
		GameResource.Type.WHITE:
			return white
		GameResource.Type.PURPLE:
			return purple
		# Force resources
		GameResource.Type.HEAT:
			return heat
		GameResource.Type.PRECISION:
			return precision
		GameResource.Type.MOMENTUM:
			return momentum
		GameResource.Type.BALANCE:
			return balance
		GameResource.Type.ENTROPY:
			return entropy
		_:
			return null

## Check if hero has enough of a specific force
func has_force(force_type: GameResource.Type, amount: int) -> bool:
	var resource = get_force_resource(force_type)
	if resource:
		return resource.amount >= amount
	return false

## Check if hero has enough forces for a dictionary of requirements
#TYPE_EXEMPTION(Force requirements from card data)
func has_forces(requirements: Dictionary) -> bool:
	for force_type in requirements:
		var required_amount = requirements[force_type]
		if not has_force(force_type, required_amount):
			return false
	return true

## Consume a specific amount of a force
func consume_force(force_type: GameResource.Type, amount: int) -> bool:
	var resource = get_force_resource(force_type)
	if resource and resource.amount >= amount:
		resource.decrement(amount)
		return true
	return false

## Consume multiple forces based on requirements dictionary
#TYPE_EXEMPTION(Force requirements from card data)
func consume_forces(requirements: Dictionary) -> bool:
	# First check if we have all requirements
	if not has_forces(requirements):
		return false

	# Then consume them all
	for force_type in requirements:
		var amount = requirements[force_type]
		consume_force(force_type, amount)

	return true

## Add to a specific force
func add_force(force_type: GameResource.Type, amount: int) -> void:
	var resource = get_force_resource(force_type)
	if resource:
		resource.increment(amount)

## Add multiple forces from production dictionary
#TYPE_EXEMPTION(Force production from card data)
func add_forces(production: Dictionary) -> void:
	for force_type in production:
		var amount = production[force_type]
		add_force(force_type, amount)


func signal_moved(new_position: int) -> void:
	GlobalSignals.signal_core_hero_moved(instance_id, new_position)

func signal_created() -> void:
	GlobalSignals.signal_core_hero_created(instance_id)

func __generate_instance_id() -> String:
	return "hero" + str(Time.get_unix_time_from_system()) + "_" + str(randi())


static func load_hero(hero_template_id: String) -> Hero:
	var hero_data = StaticData.hero_data.get(hero_template_id)
	if hero_data == null:
		assert(false, "Hero template not found: " + hero_template_id)
		return null

	var builder = Hero.HeroBuilder.new()
	builder.with_template_id(hero_template_id)
	builder.with_display_name(hero_data.get("display_name"))
	builder.with_image_name(hero_data.get("image_name"))

	# Set starting stats
	# Gold/Inspiration handled as resource, not in builder

	return builder.build()

func construct_capped_resource(starting_value: int, max_value: int, can_die: bool, type: GameResource.Type,
		max_type: GameResource.Type = GameResource.Type.UNKNOWN):
	var on_max_change: Callable = func(dummy): pass
	var on_change: Callable = func(value): GlobalSignals.signal_core_hero_resource_changed(type, value)
	if max_type != GameResource.Type.UNKNOWN:
		on_max_change = func(value): GlobalSignals.signal_core_hero_resource_changed(max_type, value)
	var cr = CappedResource.new(starting_value, max_value, on_change, on_max_change, can_die)
	cr.send_signal()
	return cr


class HeroBuilder extends Entity.EntityBuilder:
	var __image_name: String
	var __starting_health: int
	var __starting_max_health: int
	var __starting_armor: int
	var __starting_max_armor: int
	var __starting_relic: String
	var __starting_training_points: int
	var __starting_instinct: int


	func with_image_name(image_name: String) -> HeroBuilder:
		__image_name = image_name
		return self


	func build() -> Hero:
		var default_max: int = 9000

		var hero: Hero = Hero.new()
		super.build_entity(hero)

		hero.image_name = __image_name
		hero.starting_relic = __starting_relic
		# Resources are initialized in _init(), not in builder

		return hero
