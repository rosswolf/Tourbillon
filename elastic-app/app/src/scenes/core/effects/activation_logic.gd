extends Node
class_name ActivationLogic

static func activate(source: Entity, target: Entity) -> bool:
	var source_type = get_type(source)
	var target_type = get_type(target)
	
	# Handle card being dropped on battleground (which contains the engine slots)
	# Since there are no instinct effects anymore, cards need to be dropped on ENGINE_BUTTON entities
	if source_type == Entity.EntityType.CARD and target_type == Entity.EntityType.BATTLEGROUND:
		var card: Card = source as Card
		
		if not card.cost.satisfy(source, target):
			return false
		
		# All cards must be slotted now - no instinct effects exist
		# This shouldn't happen but provide a clear error message
		push_warning("Card dropped on battleground instead of engine slot: " + card.display_name)
		push_warning("Cards must be dropped on specific engine slots to be played")
		return false
	elif source_type == Entity.EntityType.CARD and target_type == Entity.EntityType.ENGINE_BUTTON:
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
	# Validate that the slot is active (within the valid grid)
	if button.engine_slot and button.engine_slot.has_method("can_accept_card"):
		if not button.engine_slot.can_accept_card():
			push_warning("Cannot place card on inactive slot")
			return false
	
	# Check if there's already a card in the slot (overbuild scenario)
	var existing_card: Card = button.card
	if existing_card != null:
		print("[OVERBUILD] Replacing ", existing_card.display_name, " with ", card.display_name)
		
		# Handle replacement as described in PRD section 2.0.4
		# 1. Trigger replacement effects on the old card (if any)
		if existing_card.has_method("trigger_replacement_effects"):
			existing_card.trigger_replacement_effects()
		
		# 2. Move the old card to discard pile
		GlobalGameManager.library.move_card_to_zone2(existing_card.instance_id, Library.Zone.SLOTTED, Library.Zone.GRAVEYARD)
		
		# 3. Signal that the old card was unslotted and discarded
		GlobalSignals.signal_core_card_unslotted(button.instance_id)
		GlobalSignals.signal_core_card_discarded(existing_card.instance_id)
		
		# Clear the slot reference (button.card setter will handle signals)
		button.card = null
	
	# Now slot the new card
	GlobalGameManager.library.move_card_to_zone2(card.instance_id, Library.Zone.HAND, Library.Zone.SLOTTED)
	
	button.card = card
	GlobalSignals.signal_core_card_removed_from_hand(card.instance_id)
	
	# CRITICAL: Also place the card on the core Mainplate entity for beat processing
	if GlobalGameManager.mainplate and button.engine_slot:
		var grid_pos = button.engine_slot.grid_position
		# Convert UI grid position (0-7) to logical position (0-3)
		# The 4x4 grid is centered at positions 2-5 in the 8x8 display
		var logical_pos = grid_pos - Vector2i(2, 2)
		if GlobalGameManager.mainplate.is_valid_position(logical_pos):
			GlobalGameManager.mainplate.place_card(card, logical_pos)
		else:
			push_warning("Invalid mainplate position for card placement: ", logical_pos)
	
	# Emit the slotted signal so the slot UI and Tourbillon system can respond
	GlobalSignals.signal_core_card_slotted(button.instance_id)
	
	# Also emit card played signal for Tourbillon time advancement
	GlobalSignals.signal_core_card_played(card.instance_id)
	
	return true
	
static func activate_instinct(card: Card, target: Entity = null) -> bool:
		
	return card.activate_instinct_effect(card, target)
	
