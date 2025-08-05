extends Control
class_name CardSelection

@onready var animation_player := $AnimationPlayer
@onready var hbox := $PanelContainer/HBoxContainer

var cards: Array[Card] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()
	#process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	GlobalSignals.core_card_selection.connect(__on_card_selection)	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func resume() -> void:
	#GlobalSignals.signal_ui_started_battle()
	
	hide()
	#get_tree().paused = false 
	animation_player.play_backwards("blur")
	
func __on_card_selection(selection_id: String, target_zone: Library.Zone) -> void:
	#get_tree().paused = true
	
	# Remove any existing child nodes from hbox
	for child in hbox.get_children():
		child.queue_free()
	
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		
	cards = GlobalGameManager.library.get_cards_for_selection(selection_id)
	for card in cards:
		__add_card_as_button(card, target_zone)
		
	show()	
	animation_player.play("blur")		
	
func __add_card_as_button(card: Card, target_zone: Library.Zone) -> void:
	var card_ui: CardUI = PreloadScenes.NODES["card_ui"].instantiate()
	card_ui.set_card_data(card)
	card_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE # Disable mouse input on CardUI so button receives clicks
	
	add_child(card_ui)
	await get_tree().process_frame  # Wait for layout
		
	var button = Button.new()
	button.name = "CardButton" + card.name
	button.flat = true  # Remove button styling
	button.custom_minimum_size = Vector2(140, 200) 
	button.size = Vector2(140, 200) 
	#TODO: get the button size from the image size, couldn't get it to work

	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(__on_card_button_pressed.bind(card, target_zone))
	
	# Remove CardUI from temporary parent and add to button
	card_ui.reparent(button)
	hbox.add_child(button)
		

func __on_card_button_pressed(card: Card, target_zone: Library.Zone) -> void:
	GlobalGameManager.library.move_card_to_zone2(card.instance_id, Library.Zone.ANY, target_zone)
	cards.erase(card)
	
	for unselected_card in cards:
		if unselected_card.rarity == Card.RarityType.RARE:
			GlobalGameManager.library.add_card_to_zone(unselected_card, Library.Zone.RARE_LIBRARY)
		elif unselected_card.rarity == Card.RarityType.UNCOMMON:
			GlobalGameManager.library.add_card_to_zone(unselected_card, Library.Zone.UNCOMMON_LIBRARY)
		elif unselected_card.rarity == Card.RarityType.COMMON:
			GlobalGameManager.library.add_card_to_zone(unselected_card, Library.Zone.COMMON_LIBRARY)
	
	GlobalGameManager.library.shuffle_libraries()
			
	resume()
	
