extends Node
class_name ActivationLogic

# Preload SimpleEffectProcessor
const SimpleEffectProcessor = preload("res://src/scenes/core/effects/simple_effect_processor.gd")

static func activate(source: Entity, target: Entity) -> bool:
	var source_type = get_type(source)
	var target_type = get_type(target)
	
	# Handle card being dropped on engine button (the slot entity)
	if source_type == Entity.EntityType.CARD and target_type == Entity.EntityType.ENGINE_BUTTON:
		var card: Card = source as Card
		var button: EngineButtonEntity = target as EngineButtonEntity
		
		if not card.cost.satisfy(source, target):
			return false
		
		# In Tourbillon, all cards can be slotted (no more instinct effects)
		if card.has_slot_effect():
			return slot_card_in_button(card, button)
		else:
			# Card has no production or effects - still allow slotting for passive cards
			push_warning("Card without production/effects being slotted: " + card.display_name)
			return slot_card_in_button(card, button)
				
	return false

static func get_type(entity: Entity):
	if entity == null:
		return Entity.EntityType.NONE
	else:
		return entity._get_type()


static func slot_card_in_button(card: Card, button: EngineButtonEntity) -> bool:
	# Just validate basic requirements then signal the UI
	if not button.engine_slot:
		push_error("Button has no engine slot")
		return false
		
	if not button.engine_slot.can_accept_card():
		push_warning("Cannot place card on inactive slot")
		return false
	
	# Signal that a card was dropped on this button
	# The UI layer will handle coordinate mapping and forward to core
	GlobalSignals.signal_ui_card_dropped_on_slot(card.instance_id, button.instance_id)
	
	# Temporarily store the card reference
	# The actual placement will be confirmed by core signals
	button.card = card
	
	return true
	
static func activate_instinct(card: Card, target: Entity = null) -> bool:
		
	return card.activate_instinct_effect(card, target)
	
