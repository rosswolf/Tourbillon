extends Node
class_name ActivationLogic

static func activate(source: Entity, target: Entity) -> bool:
	var source_type = get_type(source)
	var target_type = get_type(target)
	
	if source_type == Entity.EntityType.CARD and target_type == Entity.EntityType.BATTLEGROUND:
		var card: Card = source as Card
		
		if not card.cost.satisfy(source, target):
			return false
		
		if card.has_instinct_effect():
			return activate_instinct(card)
		elif card.has_slot_effect():
			return slot_card_in_battleground(card)
		else:
			assert(false, "unexpected inactivation")
	elif source_type == Entity.EntityType.CARD and target_type == Entity.EntityType.ENGINE_BUTTON:
		var card: Card = source as Card
		if not card.cost.satisfy(source, target):
			return false
			
		if card.has_instinct_effect():
			return activate_instinct(card, target)
		elif card.has_slot_effect():
			return slot_card_in_battleground(card)
		else:
			assert(false, "unexpected inactivation")
				
	return false

static func get_type(entity: Entity):
	if entity == null:
		return Entity.EntityType.NONE
	else:
		return entity._get_type()


static func slot_card_in_battleground(card: Card) -> bool:	
	GlobalSignals.signal_core_card_slotted(card.instance_id)
	
	GlobalGameManager.library.move_card_to_zone2(card.instance_id, Library.Zone.HAND, Library.Zone.SLOTTED)
	GlobalSignals.signal_core_card_removed_from_hand(card.instance_id)
	
	return true
	
static func activate_instinct(card: Card, target: Entity = null) -> bool:
		
	return card.activate_instinct_effect(card, target)
	
