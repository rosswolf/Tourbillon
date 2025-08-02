extends UiTextureButton
class_name EngineSlot

@onready var top_container: HBoxContainer = $VBoxContainer/TopBoxContainer
@onready var bottom_container: HBoxContainer = $VBoxContainer/BottomBoxContainer

var attached_card: Card
var is_activatable: bool

func _ready() -> void:
	super._ready()
	is_activatable = true
	create_button_entity(self, false)
	
	self.pressed.connect(__on_refresh_slot_manually)
	GlobalSignals.core_end_turn.connect(__on_end_turn)
	
	# Hide nodes we don't need yet
	await get_tree().process_frame
	top_container.visible = true
	bottom_container.visible = false

func __on_end_turn() -> void:
	pass
	#if not is_activatable:
	#	reactivate_slot()
	
func has_card() -> bool:
	return attached_card != null
	
func attach_card(card: Card) -> void:
	attached_card = card
	
	var move_pieces: Array[MoveParser.MovePiece] = attached_card.__slot_effect.move_list
	
	for move in move_pieces:
		var slot_icon: SlotIcon = PreloadScenes.ICONS["slot"].instantiate()
		
		if UidManager.SLOT_ICON_UIDS.has(move.name):
			slot_icon.set_slot_image(move.name)
		else:
			print("Couldn't load icon because not in SLOT_ICON_UIDS: " + move.name)
		
	
	# If we only have one icon, we need to increase the font size
	await get_tree().process_frame
	
func detach_card() -> void:
	if attached_card == null:
		return
	
	#TODO: should this not be in the UI code?
	if GlobalGameManager.relic_manager.has_relic("training_gloves"):	
		GlobalGameManager.library.move_card_to_zone2(attached_card.instance_id, Library.Zone.SLOTTED, Library.Zone.HAND)
	else:
		GlobalGameManager.library.move_card_to_zone2(attached_card.instance_id, Library.Zone.SLOTTED, Library.Zone.GRAVEYARD)
	attached_card = null

							
func deactivate_slot() -> void:	
	is_activatable = false
	# Gray out the slot image

func reactivate_slot() -> void:	
	is_activatable = true
	# Restore normal colors

func __on_refresh_slot_manually() -> void:
	if is_activatable:
		attached_card.__slot_effect.activate(attached_card)
		GlobalSignals.signal_ui_slot_activated(name, attached_card.instance_id)
		
	
