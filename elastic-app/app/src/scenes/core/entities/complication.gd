extends Card
class_name Complication

## Tourbillon-specific card type that represents complications
## All cards in Tourbillon are complications placed on the mainplate

# Time and production fields
var time_cost: int = 2  # Cost in ticks to play this card
var production_interval: int = 3  # Fires every X ticks
var force_production: Dictionary = {}  # GameResource.Type -> amount produced
var force_consumption: Dictionary = {}  # GameResource.Type -> amount required

# Tag system for synergies
var tags: Array[String] = []

# Keywords that modify behavior
var keywords: Array[String] = []  # OVERBUILD, MOMENTARY, IMMOVABLE, EPHEMERAL

# Additional Tourbillon-specific effects
var on_fire_effect: String = ""  # Effect when production fires
var on_placed_effect: String = ""  # Effect when placed on mainplate
var on_replaced_effect: String = ""  # Effect when replaced by another
var passive_effect: String = ""  # Ongoing effect while on mainplate

func _get_type() -> Entity.EntityType:
	return Entity.EntityType.CARD  # Still a card for compatibility

## Get the time cost in ticks
func get_time_cost() -> int:
	return time_cost

## Get the production interval in ticks
func get_production_interval() -> int:
	return production_interval

## Get force consumption requirements
func get_force_consumption() -> Dictionary:
	return force_consumption

## Get force production amounts
func get_force_production() -> Dictionary:
	return force_production

## Check if has a specific tag
func has_tag(tag: String) -> bool:
	return tag in tags

## Count tags of a specific type on the mainplate
func count_tags_on_mainplate(tag: String) -> int:
	# TODO: Query mainplate for tag count
	return 0

## Check if has a specific keyword
func has_keyword(keyword: String) -> bool:
	return keyword in keywords

## Check if this is an Overbuild complication
func is_overbuild() -> bool:
	return has_keyword("OVERBUILD")

## Check if this is Momentary (destroys itself after playing)
func is_momentary() -> bool:
	return has_keyword("MOMENTARY")

## Check if this is Immovable (can't be destroyed by effects)
func is_immovable() -> bool:
	return has_keyword("IMMOVABLE")

## Check if this is Ephemeral (exiled instead of discarded)
func is_ephemeral() -> bool:
	return has_keyword("EPHEMERAL")

## Load a complication from template data
static func load_complication(hero_template_id: String, card_template_id: String) -> Complication:
	var card_data = StaticData.lookup_template(StaticData.card_data, card_template_id)
	if not card_data:
		assert(false, "Failed to find card template: " + card_template_id)
		return null
	
	var builder = ComplicationBuilder.new()
	builder.with_template_id(card_template_id)
	builder.with_hero_template_id(hero_template_id)
	
	# Set base card fields
	if card_data.has("display_name"):
		builder.with_display_name(card_data.display_name)
	if card_data.has("rules_text"):
		builder.with_rules_text(card_data.rules_text)
	if card_data.has("card_rarity"):
		builder.with_rarity(card_data.card_rarity)
	
	# Set Tourbillon-specific fields
	if card_data.has("time_cost"):
		builder.with_time_cost(card_data.time_cost)
	if card_data.has("production_interval"):
		builder.with_production_interval(card_data.production_interval)
	if card_data.has("force_production"):
		builder.with_force_production(card_data.force_production)
	if card_data.has("force_consumption"):
		builder.with_force_consumption(card_data.force_consumption)
	if card_data.has("tags"):
		builder.with_tags(card_data.tags)
	if card_data.has("keywords"):
		builder.with_keywords(card_data.keywords)
	
	return builder.build()

## Builder for complications
class ComplicationBuilder extends Card.CardBuilder:
	var __time_cost: int = 2
	var __production_interval: int = 3
	var __force_production: Dictionary = {}
	var __force_consumption: Dictionary = {}
	var __tags: Array[String] = []
	var __keywords: Array[String] = []
	
	func with_time_cost(cost: int) -> ComplicationBuilder:
		__time_cost = cost
		return self
	
	func with_production_interval(interval: int) -> ComplicationBuilder:
		__production_interval = interval
		return self
	
	func with_force_production(production: Dictionary) -> ComplicationBuilder:
		__force_production = production
		return self
	
	func with_force_consumption(consumption: Dictionary) -> ComplicationBuilder:
		__force_consumption = consumption
		return self
	
	func with_tags(tags: Array) -> ComplicationBuilder:
		__tags.clear()
		for tag in tags:
			__tags.append(str(tag))
		return self
	
	func with_keywords(keywords: Array) -> ComplicationBuilder:
		__keywords.clear()
		for keyword in keywords:
			__keywords.append(str(keyword))
		return self
	
	func build() -> Complication:
		var complication = Complication.new()
		
		# Build base card properties
		super.build_entity(complication)
		
		# Set complication-specific properties
		complication.time_cost = __time_cost
		complication.production_interval = __production_interval
		complication.force_production = __force_production.duplicate()
		complication.force_consumption = __force_consumption.duplicate()
		complication.tags = __tags.duplicate()
		complication.keywords = __keywords.duplicate()
		
		return complication