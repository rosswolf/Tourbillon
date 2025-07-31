extends BattleEntity
class_name Hero

enum HeroClass {
	UNKNOWN,
	KNIGHT,
	BERZERKER
}

var hero_class: HeroClass = HeroClass.UNKNOWN
var image_name: String
var starting_relic: String

var __targeting: Battleground.OrderPriority
var __default_targeting: Battleground.OrderPriority

var gold: CappedResource
var instinct: CappedResource
var training_points: CappedResource


func get_type() -> Entity.EntityType:
	return Entity.EntityType.HERO

func set_targeting(targeting: Battleground.OrderPriority) -> void:
	if targeting == Battleground.OrderPriority.IGNORE:
		return
		
	__targeting = targeting
	GlobalSignals.signal_core_targeting_changed(targeting)

func get_targeting() -> Battleground.OrderPriority:
	return __targeting

func reset_turn_resources():
	block.amount = 0
	instinct.amount = 3

func reset_start_of_battle():
	set_targeting(__default_targeting)

	
func signal_moved(new_position: int) -> void:
	GlobalSignals.signal_core_hero_moved(instance_id, new_position)

func signal_created() -> void:
	GlobalSignals.signal_core_hero_created(instance_id)
			
func _generate_instance_id() -> String:
	return "hero" + str(Time.get_unix_time_from_system()) + "_" + str(randi())

static func get_hero_class(hero_template_id: String) -> HeroClass:
	match hero_template_id:
		"knight":
			return HeroClass.KNIGHT
		"berzerker":
			return HeroClass.BERZERKER
		_:
			assert(false, "Unknown hero class template id")
			return HeroClass.UNKNOWN


static func load_hero(hero_template_id: String) -> Hero:
	var hero_data = StaticData.hero_data.get(hero_template_id)
	if hero_data == null:
		assert(false, "Hero template not found: " + hero_template_id)
		return null
	
	var builder = Hero.HeroBuilder.new()
	builder.with_template_id(hero_template_id)
	builder.with_display_name(hero_data.get("display_name"))
	builder.with_hero_class(get_hero_class(hero_template_id))
	builder.with_image_name(hero_data.get("image_name"))
	
	# Set starting stats
	builder.with_starting_health(hero_data.get("starting_health"))
	builder.with_starting_max_health(hero_data.get("starting_max_health"))
	builder.with_starting_armor(hero_data.get("starting_armor"))
	builder.with_starting_max_armor(hero_data.get("starting_max_armor"))
	builder.with_starting_relic(hero_data.get("starting_relic"))
	builder.with_starting_training_points(hero_data.get("starting_training"))
	builder.with_starting_instinct(hero_data.get("starting_instinct"))
	builder.with_starting_gold(hero_data.get("starting_gold"))
	builder.with_default_targeting(hero_data.get("default_targeting"))

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
	var __hero_class: HeroClass
	var __image_name: String
	var __starting_health: int
	var __starting_max_health: int
	var __starting_armor: int
	var __starting_max_armor: int
	var __starting_relic: String
	var __starting_training_points: int
	var __starting_instinct: int
	var __starting_gold: int
	var __default_targeting: Battleground.OrderPriority
	
	func with_hero_class(hero_class: HeroClass) -> HeroBuilder:
		__hero_class = hero_class
		return self
	
	func with_image_name(image_name: String) -> HeroBuilder:
		__image_name = image_name
		return self
		
	func with_starting_health(health: int) -> HeroBuilder:
		__starting_health = health
		return self
	
	func with_starting_max_health(max_health: int) -> HeroBuilder:
		__starting_max_health = max_health
		return self
	
	func with_starting_armor(armor: int) -> HeroBuilder:
		__starting_armor = armor
		return self
	
	func with_starting_max_armor(max_armor: int) -> HeroBuilder:
		__starting_max_armor = max_armor
		return self
	
	func with_starting_relic(relic: String) -> HeroBuilder:
		__starting_relic = relic
		return self
	
	func with_starting_training_points(training_points: int) -> HeroBuilder:
		__starting_training_points = training_points
		return self
	
	func with_starting_instinct(instinct: int) -> HeroBuilder:
		__starting_instinct = instinct
		return self
	
	func with_starting_gold(gold: int) -> HeroBuilder:
		__starting_gold = gold
		return self
	
	func with_default_targeting(targeting: Battleground.OrderPriority) -> HeroBuilder:
		__default_targeting = targeting
		return self
			
	func build() -> Hero:
		var default_max: int = 9000
		
		var hero = Hero.new()
		super.build_entity(hero)
		
		hero.hero_class = __hero_class
		hero.image_name = __image_name
		hero.starting_relic = __starting_relic
		hero.facing = Arena.Facing.RIGHT
		hero.__default_targeting = __default_targeting
		hero.health = hero.construct_capped_resource(__starting_health, __starting_max_health, true, GameResource.Type.CURRENT_HEALTH, GameResource.Type.MAX_HEALTH)
		hero.armor = hero.construct_capped_resource(__starting_armor, __starting_max_armor, false, GameResource.Type.ARMOR, GameResource.Type.MAX_ARMOR)
		hero.training_points = hero.construct_capped_resource(__starting_training_points, default_max, false, GameResource.Type.TRAINING_POINTS)
		hero.instinct = hero.construct_capped_resource(__starting_instinct, default_max, false, GameResource.Type.INSTINCT)
		hero.block = hero.construct_capped_resource(0, default_max, false, GameResource.Type.BLOCK)
		hero.gold = hero.construct_capped_resource(__starting_gold, default_max, false, GameResource.Type.GOLD)
		
		return hero
