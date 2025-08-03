class_name CardUI
extends Control

# UI Components
@onready var card_background = $CardBackground
@onready var card_title = $TitlePanel/Title 
@onready var card_description = $DescriptionPanel/Description
@onready var icon_container = $IconContainer
@onready var durability_label = $TargetingBoxContainer/DurabilityLabel

#@onready var card_image = $ImagePanel/Image
#@onready var activation_color_panel = $ActivationContainer/ActivationColorPanel

# Card data
var card_data: Card

func _ready():
	# Connect mouse input signals
	#gui_input.connect(_on_gui_input)
	mouse_entered.connect(__on_mouse_entered)
	mouse_exited.connect(__on_mouse_exited)
	
	# Set initial pivot point for rotation
	pivot_offset = size / 2
	
# Set card data and update UI
func set_card_data(card: Card) -> void:
	if not is_node_ready():
		await self.ready
		
	card_data = card
	
	# Update UI elements
	card_title.text = card.display_name
	card_description.text = card.rules_text
	if card.durability.amount <= 0:
		durability_label.text = "Durability: " + str(card.durability.amount) + "/" + str(card.durability.max_amount)
	
	add_slot_icon("blue_energy", str(card.cost.get_energy_cost()), %TopHBoxContainer, GameIcon.TextSize.SMALL)
	
		

func add_slot_icon(name: String, value: String, container: Container, font_size: GameIcon.TextSize) -> void:
	var slot_icon: SlotIcon = PreloadScenes.ICONS["slot"].instantiate()
		
	if not UidManager.SLOT_ICON_UIDS.has(name):
		print("Couldn't load icon because not in SLOT_ICON_UIDS: " + name)
	
	slot_icon.set_slot_image(name)
	container.add_child(slot_icon)
	await get_tree().process_frame
	# Wait for the node to initialize, then set the label text
	slot_icon.set_string_text(value, font_size, Color.BLACK)	

					
# These mouse events are reached first, then the functions in the HandContainer second
func __on_mouse_entered() -> void:
	GlobalSignals.signal_ui_card_hovered(card_data.instance_id)

func __on_mouse_exited() -> void:
	GlobalSignals.signal_ui_card_unhovered(card_data.instance_id)
	
