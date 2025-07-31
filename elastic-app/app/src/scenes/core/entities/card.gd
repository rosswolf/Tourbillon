extends Entity

class_name Card

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

		
func activate_slot_effect(source: Entity, target: Entity) -> bool:
	if not __slot_effect._could_satisfy_costs(source, target) or \
			not __slot_effect._execute_satisfy_costs(source, target):
		return false
		
	return __slot_effect.activate(source)
	
func activate_instinct_effect(source: Entity, target: Entity) -> bool:
	if not __instinct_effect._could_satisfy_costs(source, target) or \
			not __instinct_effect._execute_satisfy_costs(source, target):
		return false
	
	GlobalGameManager.library.move_card_to_zone(instance_id, Library.Zone.BEING_PLAYED, Library.Zone.HAND)
	var succeeded = __instinct_effect.activate(source)
	if succeeded:
		GlobalGameManager.library.move_card_to_zone(instance_id, Library.Zone.GRAVEYARD, Library.Zone.BEING_PLAYED)
		GlobalSignals.signal_core_card_discarded(instance_id)
		GlobalSignals.signal_core_card_removed_from_hand(instance_id)
	else:
		# Effects need to return true to succeed, this will help us track down issues. 
		# Usually the issue is some void return instead of a boolean true
		assert(false, "Failed to activate effect " + __instinct_effect.effect_name)
		GlobalGameManager.library.move_card_to_zone(instance_id, Library.Zone.HAND, Library.Zone.BEING_PLAYED)
	return succeeded

#func _signal_and_activate_effect(effect: Effect, source: Entity, target: Entity) -> bool:
	#if not effect._execute_satisfy_costs(source, target):
		#return false
#
	#GlobalGameManager.library.move_card_to_zone(instance_id, Library.Zone.BEING_PLAYED, Library.Zone.HAND)
	#var succeeded = effect.activate(source)
	#if succeeded:
		#GlobalGameManager.library.move_card_to_zone(instance_id, Library.Zone.GRAVEYARD, Library.Zone.BEING_PLAYED)
		#GlobalSignals.signal_core_card_discarded(instance_id)
	#else:
		## Effects need to return true to succeed, this will help us track down issues. 
		## Usually the issue is some void return instead of a boolean true
		#assert(false, "Failed to activate effect " + effect.effect_name)
		#GlobalGameManager.library.move_card_to_zone(instance_id, Library.Zone.HAND, Library.Zone.BEING_PLAYED)
	#return succeeded

	
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
			
	func with_slot_effect(move_descriptor: String) -> EntityBuilder:
		__slot_effect = move_descriptor
		return self
		
	func with_instinct_effect(move_descriptor: String) -> EntityBuilder:
		__instinct_effect = move_descriptor
		return self
		
	func with_card_cost(required_resources: Dictionary) -> CardBuilder:
		for key in required_resources.keys():
			var num_required: int = required_resources[key] as int
			__required_resources[key] = num_required
		return self
		


	func build() -> Card:
		var card = Card.new()
		super.build_entity(card)
			
		if __slot_effect != "":
			card.__slot_effect = MoveDescriptorEffect.new(__slot_effect, null)
		
		var cost = Cost.new(__required_resources)
		
		if __instinct_effect != "":
			card.__instinct_effect = MoveDescriptorEffect.new(__instinct_effect, cost)
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
	builder.with_display_name(card_template_data.get("display_name"))
	builder.with_instinct_effect(card_template_data.get("instinct_effect",""))
	builder.with_slot_effect(card_template_data.get("slot_effect",""))
	
	if rarity == Card.RarityType.DEFAULT:
		# Use template_id for each character's default card 
		builder.with_instance_id(card_template_id)
	
	var card_cost = card_template_data.get("card_cost")
	if card_cost == null:
		assert(false, "Cost cant be empty in spreadsheet")
	
	builder.with_card_cost(card_cost)	
	builder.with_rules_text(card_template_data.get("rules_text",""))
	var card = builder.build()
	return card
		
