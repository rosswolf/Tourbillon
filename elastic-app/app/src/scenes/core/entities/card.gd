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

func has_instinct_effect() -> bool:
	return __instinct_effect != null
	
func has_slot_effect() -> bool:
	# In Tourbillon, all cards can be slotted since there are no instinct effects
	# A card is slottable if it has any production or effects
	return production_interval != 0 or not on_fire_effect.is_empty() or not passive_effect.is_empty()
		
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
	
func __generate_instance_id() -> String:
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
		
	#TYPE_EXEMPTION(Resource costs from JSON data)
	func with_card_cost(required_resources: Dictionary) -> CardBuilder:
		for key in required_resources.keys():
			var num_required: int = required_resources[key] as int
			__required_resources[key] = num_required
		return self
	


	func build() -> Card:
		var card: Card = Card.new()
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
		
#TYPE_EXEMPTION(Card template data from JSON)
static func build_new_card_from_template(card_template_id: String, card_template_data: Dictionary) -> Card:
	if card_template_id != card_template_data.get("card_template_id"):
		assert(false, "card template id doesn't match as expected: " + card_template_id +  " " + str(card_template_data.get("card_template_id")))
	
	# Use StaticData's parse_enum to convert the string reference to enum value
	var rarity_value = card_template_data.get("card_rarity", Card.RarityType.UNKNOWN)
	var rarity: Card.RarityType = Card.RarityType.UNKNOWN
	
	# Handle both direct enum values and string references
	if rarity_value is int:
		rarity = rarity_value as Card.RarityType
	elif rarity_value is String:
		# Cast directly to int - will fail if spreadsheet is wrong
		rarity = StaticData.parse_enum(rarity_value) as int
	
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
	
	#builder.with_card_cost(card_template_data.get("card_cost"))
	
	# Handle rules_text - might be a dictionary from JSON parsing
	var rules_text_data = card_template_data.get("rules_text", "")
	#TYPE_EXEMPTION(JSON can contain dictionary for rules text)
	if rules_text_data is Dictionary:
		# Convert dictionary back to string format
		var text_parts: Array[String] = []
		for key in rules_text_data:
			text_parts.append(key + ": " + str(rules_text_data[key]))
		builder.with_rules_text("; ".join(text_parts))
	elif rules_text_data is String:
		builder.with_rules_text(rules_text_data)
	else:
		builder.with_rules_text("")
	
	var card: Card = builder.build()
	card.time_cost = int(card_template_data.get("time_cost", 2))
	card.production_interval = int(card_template_data.get("production_interval", 3))
	card.starting_progress = int(card_template_data.get("starting_progress", 0))
	#card.force_production = card_template_data.get("force_production", {})
	#card.force_consumption = card_template_data.get("force_consumption", {})
	#card.force_cost = card_template_data.get("force_cost", {})
	
	# Handle tags - could be array or comma-separated string
	var tags_data = card_template_data.get("tags", [] as Array[String])
	if tags_data is String:
		var split_tags: PackedStringArray = tags_data.split(",")
		card.tags = []
		for tag in split_tags:
			card.tags.append(tag.strip_edges())
	elif tags_data is Array[String]:
		card.tags = tags_data
	else:
		card.tags = []
	
	# Handle keywords similarly
	var keywords_data = card_template_data.get("keywords", [] as Array[String])
	if keywords_data is String and not keywords_data.is_empty():
		var split_keywords: PackedStringArray = keywords_data.split(",")
		card.keywords = []
		for keyword in split_keywords:
			card.keywords.append(keyword.strip_edges())
	elif keywords_data is Array[String]:
		card.keywords = keywords_data
	else:
		card.keywords = []
	
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
		
