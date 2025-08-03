extends BattleEntity
class_name Hero
static func _get_type_string():
	return "Hero"


var image_name: String
var starting_relic: String


var gold: CappedResource
var time: TimeResource
var energy: EnergyResource

var force: CappedResource
var depth: CappedResource

func _init():
	time = TimeResource.new()

class TimeResource:

	func replenish_time(color: Air.AirColor, amount: float):
		GlobalSignals.signal_core_time_replenished(color, amount)
	
	func set_time_capped(color: Air.AirColor, amount: float):
		GlobalSignals.signal_core_time_set(color, amount)
		
	func add_max_time(color: Air.AirColor, amount: float):
		GlobalSignals.signal_core_max_time_added(color, amount)
	
	func set_max_time(color: Air.AirColor, amount: float):
		GlobalSignals.signal_core_max_time_set(color, amount)
	
class EnergyResource:
	func replenish_energy(color: Air.AirColor, amount: float):
		GlobalSignals.signal_core_energy_replenished(color, amount)
	
	func set_energy_capped(color: Air.AirColor, amount: float):
		GlobalSignals.signal_core_energy_set(color, amount)	

	func add_max_energy(color: Air.AirColor, amount: float):
		GlobalSignals.signal_core_max_energy_added(color, amount)
	
	func set_max_energy(color: Air.AirColor, amount: float):
		GlobalSignals.signal_core_max_energy_set(color, amount)
		

func get_type() -> Entity.EntityType:
	return Entity.EntityType.HERO



func reset_start_of_battle():
	pass

	
func signal_moved(new_position: int) -> void:
	GlobalSignals.signal_core_hero_moved(instance_id, new_position)

func signal_created() -> void:
	GlobalSignals.signal_core_hero_created(instance_id)
			
func _generate_instance_id() -> String:
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
	builder.with_starting_gold(hero_data.get("starting_gold"))

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
	var __starting_gold: int
	
	
	func with_image_name(image_name: String) -> HeroBuilder:
		__image_name = image_name
		return self
		
	
	func with_starting_gold(gold: int) -> HeroBuilder:
		__starting_gold = gold
		return self
	
	func build() -> Hero:
		var default_max: int = 9000
		
		var hero = Hero.new()
		super.build_entity(hero)
		
		hero.image_name = __image_name
		hero.starting_relic = __starting_relic
		#hero.time = hero.construct_capped_resource(5*60, 5*60*1000, false, GameResource.Type.TIME)
		hero.force = hero.construct_capped_resource(0, default_max, false, GameResource.Type.FORCE)
		hero.depth = hero.construct_capped_resource(10, default_max, false, GameResource.Type.DEPTH)
		#hero.energy = hero.construct_capped_resource(0, default_max, false, GameResource.Type.ENERGY)
		hero.gold = hero.construct_capped_resource(__starting_gold, default_max, false, GameResource.Type.GOLD)
		
		return hero
