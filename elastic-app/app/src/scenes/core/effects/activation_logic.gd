extends Node
class_name ActivationLogic

static func activate(source: Entity, target: Entity) -> bool:
	var source_type = get_type(source)
	var target_type = get_type(target)
	
	if source_type == Entity.EntityType.CARD and target_type == Entity.EntityType.BATTLEGROUND:
		return activate_instinct(source)
	
	if source_type == Entity.EntityType.CARD and target_type == Entity.EntityType.ENGINE_BUTTON:
		var button_entity: EngineButtonEntity = target as EngineButtonEntity
		
		if button_entity.is_activation_button:
			return activate_engine(source, button_entity)
		else:
			return slot_card_in_engine(source, button_entity)
			
	return false

static func get_type(entity: Entity):
	if entity == null:
		return Entity.EntityType.NONE
	else:
		return entity._get_type()

static func activate_engine(card: Card, button: EngineButtonEntity) -> bool:
	if not button.engine_slot.is_activatable or not button.engine_slot.has_card():
		#TODO: give some feedback to user that this activation would do nothing because
		# the first slot is not activatable
		return false
		
	GlobalGameManager.library.move_card_to_zone(card.instance_id, Library.Zone.BEING_PLAYED, Library.Zone.HAND)
	button.engine_slot.activate(card)
	GlobalGameManager.library.move_card_to_zone(card.instance_id, Library.Zone.GRAVEYARD, Library.Zone.BEING_PLAYED)
	GlobalSignals.signal_core_card_discarded(card.instance_id)
	GlobalSignals.signal_core_card_removed_from_hand(card.instance_id)
	
	return true

static func slot_card_in_engine(card: Card, button: EngineButtonEntity) -> bool:
	if card.group_template_id == "curse":
		# TODO: UI popup that says you can't slot a curse card
		return false
	
	if button.engine_slot.has_card():
		# TODO: UI popup that says the slot already has an attached card
		return false
	
	var training_value: int = int(button.engine_slot.training_label.text)
	if not GlobalGameManager.have_enough_training_points(training_value):
		# TODO: UI popup that player cant slot because not enough TP
		return false
	
	GlobalGameManager.hero.training_points.decrement(training_value)
	
	button.engine_slot.attach_card(card)
	GlobalGameManager.library.move_card_to_zone(card.instance_id, Library.Zone.SLOTTED, Library.Zone.HAND)
	GlobalSignals.signal_core_card_removed_from_hand(card.instance_id)
	
	return true
	
static func activate_instinct(card: Card) -> bool:	
	if card.__instinct_effect == null:
		#TODO: check if this will actually be null
		return false
		
	return card.activate_instinct_effect(card, null)
	
