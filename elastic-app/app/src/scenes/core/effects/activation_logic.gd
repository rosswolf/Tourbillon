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
		else:
			return false
	elif source_type == Entity.EntityType.CARD and target_type == Entity.EntityType.ENGINE_BUTTON:
		var card: Card = source as Card
		var button: EngineButtonEntity = target as EngineButtonEntity
		
		if not card.cost.satisfy(source, target):
			return false
			
		if card.has_instinct_effect():
			return activate_instinct(card, target)
		elif card.has_slot_effect():
			return slot_card_in_button(card, button)
		else:
			assert(false, "unexpected inactivation")
				
	return false

static func get_type(entity: Entity):
	if entity == null:
		return Entity.EntityType.NONE
	else:
		return entity._get_type()


static func slot_card_in_button(card: Card, button: EngineButtonEntity) -> bool:	
	
	GlobalGameManager.library.move_card_to_zone2(card.instance_id, Library.Zone.HAND, Library.Zone.SLOTTED)
	
	button.card = card
	GlobalSignals.signal_core_card_removed_from_hand(card.instance_id)
	
	# Emit the slotted signal so the slot UI and Tourbillon system can respond
	GlobalSignals.signal_core_card_slotted(button.instance_id)
	
	# Also emit card played signal for Tourbillon time advancement
	GlobalSignals.signal_core_card_played(card.instance_id)
	
	return true
	
static func activate_instinct(card: Card, target: Entity = null) -> bool:
		
	return card.activate_instinct_effect(card, target)
	
