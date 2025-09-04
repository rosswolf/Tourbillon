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
	# Minimal routing - validate slot and delegate to mainplate
	if button.engine_slot:
		if not button.engine_slot.can_accept_card():
			push_warning("Cannot place card on inactive slot")
			return false
	
	# Get logical position from button's slot
	if not button.engine_slot:
		push_error("Button has no engine slot")
		return false
	
	# Get the UI mainplate to convert physical to logical position
	var ui_mainplate = get_tree().get_nodes_in_group("ui_mainplate").front() as UIMainplate
	if not ui_mainplate or not ui_mainplate.grid_mapper:
		push_error("No UI mainplate or grid mapper found")
		return false
		
	var physical_pos = button.engine_slot.grid_position
	var logical_pos = ui_mainplate.grid_mapper.to_logical(physical_pos)
	
	if logical_pos == null:
		push_warning("Physical position %s is not in active grid" % physical_pos)
		return false
	
	# Delegate ALL business logic to mainplate
	if GlobalGameManager.mainplate:
		# The mainplate handles everything:
		# - Overbuild logic
		# - Zone moves  
		# - Bonus squares
		# - Card state
		# - Signals
		var success = GlobalGameManager.mainplate.request_card_placement(card, logical_pos)
		
		# Update button reference only if successful
		if success:
			button.card = card
		
		return success
	else:
		push_error("No mainplate found")
		return false
	
static func activate_instinct(card: Card, target: Entity = null) -> bool:
		
	return card.activate_instinct_effect(card, target)
	
