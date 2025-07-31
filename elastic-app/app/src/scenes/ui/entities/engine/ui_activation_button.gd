extends UiTextureButton
class_name ActivationButton

var engine_slot: EngineSlot

func _ready() -> void:
	super._ready()
	engine_slot = get_parent()
	create_button_entity(engine_slot, true)
	
	mouse_entered.connect(__on_mouse_entered)
	mouse_exited.connect(__on_mouse_exited)
	
	
func __on_mouse_entered() -> void:
	if card_activation_type_matches():
		__is_hovered = true
		GlobalSignals.signal_ui_changed_cursor_image(UidManager.UIDS["hand"])
		GlobalSelectionManager.set_hovered(__button_entity.instance_id)

func __on_mouse_exited() -> void:
	if card_activation_type_matches():
		__is_hovered = false
		GlobalSignals.signal_ui_changed_cursor_image("")
		GlobalSelectionManager.clear_hovered_known(__button_entity.instance_id)
	
func card_activation_type_matches() -> bool:
	if not GlobalSelectionManager.is_card_selected():
		return false
		
	var card: Card = GlobalGameManager.get_selected_card()
		
	return card.trigger_resource == engine_slot.trigger_resource
