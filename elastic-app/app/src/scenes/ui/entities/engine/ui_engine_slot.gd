extends UiTextureButton
class_name EngineSlot

@onready var top_container: HBoxContainer = $MarginContainer/MainPanel/VBoxContainer/TopBoxContainer
@onready var bottom_container: HBoxContainer = $MarginContainer/MainPanel/VBoxContainer/BottomBoxContainer


var is_activatable: bool
var timer_duration: float

var card_preview: CardUI

var CARD_UI = preload("res://src/scenes/ui/hand/card_ui.tscn")

func _ready() -> void:
	super._ready()
	
	deactivate_slot()
	create_button_entity(self, false)
	
	self.pressed.connect(__on_refresh_slot_manually)
	
	# Hide nodes we don't need yet
	await get_tree().process_frame
	top_container.visible = true
	bottom_container.visible = false
	
	GlobalSignals.core_slot_add_cooldown.connect(__on_cooldown)
	
	GlobalSignals.core_card_slotted.connect(__on_card_slotted)
	GlobalSignals.core_card_unslotted.connect(__on_card_unslotted)
	
func create_card_ui():	
	card_preview = CARD_UI.instantiate()
	card_preview.set_card_data(__button_entity.card)
	
	card_preview.position = Vector2(-170, 0)
	add_child(card_preview)
	# Start invisible and scale up
	var tween = create_tween()
	tween.tween_property(card_preview, "scale", Vector2(1.25, 1.25), 0.17)

func destroy_card_ui():	
	var tween = create_tween()
	tween.tween_property(card_preview, "scale", Vector2(.75,.75), 0.15)
	tween.tween_callback(card_preview.queue_free)
	card_preview = null
	
func __on_card_slotted(target_slot_id: String):
	if target_slot_id == __button_entity.instance_id:
		create_card_ui()
		%Name.text = __button_entity.card.display_name
		%MainPanel.visible = true
		reactivate_slot()
	
func __on_card_unslotted(target_slot_id: String):
	if target_slot_id == __button_entity.instance_id:
		%Name.text = ""
		%MainPanel.visible = false
		deactivate_slot()
		%Timer.stop()
		%ProgressBar.value = 0

func _process(delta):
	if %Timer.time_left != 0:
		%ProgressBar.value = pct(%Timer.time_left, timer_duration)

func __on_cooldown(instance_id: String, duration: float):
	if instance_id == __button_entity.get_card_instance_id():
	
		deactivate_slot()
		timer_duration = duration
		%Timer.one_shot = true
		%Timer.timeout.connect(func():reactivate_slot())
		%Timer.start(timer_duration)
		%ProgressBar.value = pct(%Timer.time_left, timer_duration)

func pct(numerator: float, denominator: float):
	if denominator <= 0.001:
		return 0.0
	else:
		return 100.0 * numerator / denominator	
	

							
func deactivate_slot() -> void:	
	is_activatable = false
	# Gray out the slot image
	

func reactivate_slot() -> void:	
	is_activatable = true
	# Restore normal colors

func __on_refresh_slot_manually() -> void:
	if is_activatable and __button_entity.card != null:
		__button_entity.activate_slot_effect(__button_entity.card, null)
		if card_preview:
			card_preview.refresh()
		
func _on_mouse_entered() -> void:
	super._on_mouse_entered()
	if __button_entity.get_card_instance_id() != "":
		create_card_ui()
		
func _on_mouse_exited() -> void:
	super._on_mouse_exited()
	if card_preview:
		destroy_card_ui()
