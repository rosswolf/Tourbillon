extends TextureButton
class_name UiTextureButton

var __is_hovered: bool = false
var __button_entity: EngineButtonEntity

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
func create_button_entity(engine_slot: EngineSlot, is_activation_button: bool): 
	if not is_node_ready():
		await self.ready
	
	var builder: EngineButtonEntity.EngineButtonEntityBuilder = EngineButtonEntity.EngineButtonEntityBuilder.new()
	builder.with_engine_slot(engine_slot)
	builder.with_is_activation_button(is_activation_button)
	__button_entity = builder.build()

	
func _on_mouse_entered() -> void:
	__is_hovered = true
	GlobalSelectionManager.set_hovered(__button_entity.instance_id)

func _on_mouse_exited() -> void:
	__is_hovered = false
	GlobalSelectionManager.clear_hovered_known(__button_entity.instance_id)
	
func _exit_tree() -> void:
	if __is_hovered:
		_on_mouse_exited()
