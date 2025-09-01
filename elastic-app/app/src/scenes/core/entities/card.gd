extends Entity

class_name Card
static func _get_type_string():
	return "Card"

enum RarityType {
	UNKNOWN,
	STARTING, # Starts in hand
	COMMON,
	UNCOMMON,
	RARE,
	DEFAULT # Starts slotted in engine
}

var group_template_id: String
var rarity: RarityType
var rules_text: String
var art_image_uid: String
var cursor_image_uid: String

# Cost to play the card.  Usually resources.  
var cost: Cost

var __instinct_effect: MoveDescriptorEffect
var __slot_effect: MoveDescriptorEffect

var trigger_resource: GameResource.Type = GameResource.Type.UNKNOWN

var durability: CappedResource

# Tourbillon-specific fields (cards become gears when played)
var time_cost: int = 2  # Cost in ticks to play this card
var production_interval: int = 3  # Fires every X ticks (30 beats)
var starting_progress: int = 0  # Initial timer progress in beats
var force_production: Dictionary[GameResource.Type, int] = {}  # Force type -> amount produced
var force_consumption: Dictionary[GameResource.Type, int] = {}  # Force type -> amount required
var force_cost: Dictionary[GameResource.Type, int] = {}  # Additional cost to play
var tags: Array[String] = []  # Tags for synergies
var keywords: Array[String] = []  # OVERBUILD, MOMENTARY, IMMOVABLE, EPHEMERAL

# Effect trigger strings
var on_play_effect: String = ""  # When played from hand
var on_place_effect: String = ""  # When placed on mainplate
var on_fire_effect: String = ""  # When producing
var on_ready_effect: String = ""  # When entering ready state
var on_replace_effect: String = ""  # When another gear replaces this
var on_destroy_effect: String = ""  # When destroyed
var on_discard_effect: String = ""  # When discarded from hand
var on_draw_effect: String = ""  # When drawn from deck
var on_exhaust_effect: String = ""  # When deck exhausted
var passive_effect: String = ""  # Ongoing effect while on mainplate
var conditional_effect: String = ""  # Effect with conditions

func has_instinct_effect():
	return __instinct_effect != null
	
func has_slot_effect():
	return __slot_effect != null
		
func activate_slot_effect(source: Entity, target: Entity) -> bool:
	if not __slot_effect._could_satisfy_costs(source, target) or \
			not __slot_effect._execute_satisfy_costs(source, target):
		return false
		
	var result = __slot_effect.activate(source)
	if result:
		GlobalSignals.signal_core_slot_activated(instance_id)
	return result
	
func activate_instinct_effect(source: Entity, target: Entity) -> bool:
	
	if not __instinct_effect._is_valid_source(source):
		return false
	
	if not __instinct_effect._is_valid_target(target):
		return false
	
	if not __instinct_effect._could_satisfy_costs(source, target) or \
			not __instinct_effect._execute_satisfy_costs(source, target):
		return false
	
	GlobalGameManager.library.move_card_to_zone2(instance_id, Library.Zone.HAND, Library.Zone.BEING_PLAYED)
	var succeeded = __instinct_effect.activate(source)
	if succeeded:
		GlobalGameManager.library.move_card_to_zone2(instance_id, Library.Zone.BEING_PLAYED, Library.Zone.GRAVEYARD)
		GlobalSignals.signal_core_card_played(instance_id)
		GlobalSignals.signal_core_card_removed_from_hand(instance_id)
	else:
		# Effects need to return true to succeed, this will help us track down issues. 
		# Usually the issue is some void return instead of a boolean true
		assert(false, "Failed to activate effect " + __instinct_effect.effect_name)
		GlobalGameManager.library.move_card_to_zone2(instance_id, Library.Zone.BEING_PLAYED, Library.Zone.HAND)
	return succeeded
	
func _get_type() -> Entity.EntityType:
	return Entity.EntityType.CARD
	
func _generate_instance_id() -> String:
	return "card_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())

class CardBuilder extends Entity.EntityBuilder:
	# Card properties to build
	var __group_template_id: String = ""
	var __card_rarity: Card.RarityType = Card.RarityType.UNKNOWN
	var __art_image_uid: String = ""
	var __cursor_image_uid: String = ""
	var __rules_text: String = ""
	var __required_resources: Dictionary[GameResource.Type, int] = {}
	var __slot_effect: String
	var __instinct_effect: String
	var __trigger_resource: GameResource.Type = GameResource.Type.UNKNOWN
	var __max_durability: int = StaticData.get_int("default_card_durability")
	
	func with_group_template_id(group_template_id: String) -> CardBuilder:
		__group_template_id = group_template_id
		return self
	
	func with_rarity(type: Card.RarityType) -> CardBuilder:
		__card_rarity = type
		return self
	
	func with_art_image_uid(art_image_uid: String) -> CardBuilder:
		__art_image_uid = art_image_uid
		return self
	
	func with_cursor_image_uid(cursor_image_uid: String) -> CardBuilder:
		__cursor_image_uid = cursor_image_uid
		return self
			
	func with_rules_text(rules_text: String) -> CardBuilder:
		__rules_text = rules_text
		return self
			
	func with_slot_effect(move_descriptor: String) -> CardBuilder:
		__slot_effect = move_descriptor
		return self
		
	func with_instinct_effect(move_descriptor: String) -> CardBuilder:
		__instinct_effect = move_descriptor
		return self
		
	func with_card_cost(required_resources: Dictionary) -> CardBuilder:
		for key in required_resources.keys():
			var num_required: int = required_resources[key] as int
			__required_resources[key] = num_required
		return self
	
	func with_durability(durability_in: int) -> CardBuilder:
		__max_durability = durability_in
		return self


	func build() -> Card:
		var card = Card.new()
		super.build_entity(card)
			
		if __slot_effect != "":
			card.__slot_effect = MoveDescriptorEffect.new(__slot_effect)
		
		var cost = Cost.new(__required_resources)
		
		if __instinct_effect != "":
			card.__instinct_effect = MoveDescriptorEffect.new(__instinct_effect)
		card.group_template_id = __group_template_id
		card.rarity = __card_rarity
		#card.art_image_uid = __art_image_uid
		card.cursor_image_uid = __cursor_image_uid
		card.rules_text = __rules_text
		card.cost = cost
		card.trigger_resource = __trigger_resource
		
		var on_change: Callable = func(value): if value == 0: GlobalSignals.signal_core_card_destroyed(card.instance_id)
		var none: Callable = func(value): pass
		card.durability = CappedResource.new(__max_durability, __max_durability, on_change, none, true)
		return card

static func load_card(group_template_id: String, card_template_id: String) -> Card:
	if StaticData.card_data.has(card_template_id):
		var entry = StaticData.card_data.get(card_template_id)
		var card: Card
		if entry.get("group_template_id", "") == group_template_id:
			card = build_new_card_from_template(card_template_id, entry)
		return card
	else:
		printerr("Unknown card: " + card_template_id)
		return null

static func load_cards_by_count(group_template_id: String, card_template_id: String) -> Array[Card]:
	if StaticData.card_data.has(card_template_id):
		var cards: Array[Card]
		var entry = StaticData.card_data.get(card_template_id)
		if entry.get("group_template_id", "") == group_template_id:
			var card_count = entry.get("card_count", 1)
			for i in range(card_count):
				var card = build_new_card_from_template(card_template_id, entry)
				cards.append(card)
		return cards
	else:
		printerr("Unknown card: " + card_template_id)
		return []
				
#static func load_starting_cards(group_template_id: String, card_template_ids: Array[String]):
	#var results: Array[Card] = []
	#for t_id in card_template_ids:
		#var card = load_card(group_template_id, t_id)
		#if card != null:
			#results.append(card)
	#return results

static func load_cards(group_template_id: String, card_template_ids: Array[String]) -> Array[Card]:
	var results: Array[Card] = []
	for t_id in card_template_ids:	
		var cards: Array[Card] = load_cards_by_count(group_template_id, t_id)
		if not cards.is_empty():
			results.append_array(cards)
	return results
		
static func build_new_card_from_template(card_template_id: String, card_template_data: Dictionary) -> Card:
	if card_template_id != card_template_data.get("card_template_id"):
		assert(false, "card template id doesn't match as expected: " + card_template_id +  " " + str(card_template_data.get("card_template_id")))
	
	var rarity: Card.RarityType = card_template_data.get("card_rarity")
	
	var builder: CardBuilder = CardBuilder.new()
	builder.with_template_id(card_template_id)
	builder.with_group_template_id(card_template_data.get("group_template_id"))
	builder.with_rarity(rarity)
	#builder.with_art_image_uid(card_template_data.get("art_image_uid"))
	builder.with_cursor_image_uid(card_template_data.get("cursor_image_uid"))
	builder.with_display_name(card_template_data.get("display_name",""))
	builder.with_instinct_effect(card_template_data.get("instinct_effect",""))
	builder.with_slot_effect(card_template_data.get("slot_effect",""))
	
	if rarity == Card.RarityType.DEFAULT:
		# Use template_id for each character's default card 
		builder.with_instance_id(card_template_id)
	
	builder.with_durability(int(card_template_data.get("durability_max", 1)))
	builder.with_card_cost(card_template_data.get("card_cost"))
	builder.with_rules_text(card_template_data.get("rules_text",""))
	
	# Load Tourbillon-specific fields
	var card = builder.build()
	card.time_cost = card_template_data.get("time_cost", 2)
	card.production_interval = card_template_data.get("production_interval", 3)
	card.starting_progress = card_template_data.get("starting_progress", 0)
	card.force_production = card_template_data.get("force_production", {})
	card.force_consumption = card_template_data.get("force_consumption", {})
	card.force_cost = card_template_data.get("force_cost", {})
	card.tags = card_template_data.get("tags", [])
	card.keywords = card_template_data.get("keywords", [])
	
	# Load effect strings
	card.on_play_effect = card_template_data.get("on_play_effect", "")
	card.on_place_effect = card_template_data.get("on_place_effect", "")
	card.on_fire_effect = card_template_data.get("on_fire_effect", "")
	card.on_ready_effect = card_template_data.get("on_ready_effect", "")
	card.on_replace_effect = card_template_data.get("on_replace_effect", "")
	card.on_destroy_effect = card_template_data.get("on_destroy_effect", "")
	card.on_discard_effect = card_template_data.get("on_discard_effect", "")
	card.on_draw_effect = card_template_data.get("on_draw_effect", "")
	card.on_exhaust_effect = card_template_data.get("on_exhaust_effect", "")
	card.passive_effect = card_template_data.get("passive_effect", "")
	card.conditional_effect = card_template_data.get("conditional_effect", "")
	
	return card
		
