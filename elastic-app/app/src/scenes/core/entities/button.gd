extends Entity
class_name EngineButtonEntity

var engine_slot: EngineSlot
var is_activation_button: bool

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
