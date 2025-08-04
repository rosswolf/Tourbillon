extends Entity
class_name EngineButtonEntity
static func _get_type_string():
	return "EngineButtonEntity"

var engine_slot: EngineSlot
var is_activation_button: bool

var __card: Card
var card: Card:
	get: 
		return __card
	set(new_value): 
		if new_value != __card:
			
			if __card != null:
				__card = null
				GlobalSignals.signal_core_card_unslotted(instance_id)
				
			__card = new_value
			if __card != null:
				GlobalSignals.signal_core_card_slotted(instance_id)
	
func _init():
	GlobalSignals.core_card_destroyed.connect(__on_core_card_destroyed)
	
func __on_core_card_destroyed(card_instance_id: String):
	if card and card.instance_id == card_instance_id:
		card = null
	
func get_card_instance_id():
	if card:
		return card.instance_id
	else:
		return ""
		
func activate_slot_effect(source: Entity, target: Entity):
	if not card:
		return false
	return card.activate_slot_effect(source, target)

func _get_type() -> Entity.EntityType:
	return Entity.EntityType.ENGINE_BUTTON
	
func _generate_instance_id() -> String:
	return "button_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())

func _requires_template_id() -> bool:
	return false
	
	
class EngineButtonEntityBuilder extends Entity.EntityBuilder:
	var __engine_slot: EngineSlot
	var __is_activation_button: bool
	
	func with_engine_slot(engine_slot: EngineSlot) -> EngineButtonEntityBuilder:
		__engine_slot = engine_slot
		return self
		
	func with_is_activation_button(is_activation_button: bool) -> EngineButtonEntityBuilder:
		__is_activation_button = is_activation_button
		return self
			
	func build() -> EngineButtonEntity:
		var button = EngineButtonEntity.new()
		super.build_entity(button)
		button.engine_slot = __engine_slot
		button.is_activation_button = __is_activation_button
		return button
