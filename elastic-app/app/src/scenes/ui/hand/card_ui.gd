class_name CardUI
extends Control

# UI Components
@onready var card_background = $CardBackground
@onready var card_title = $TitlePanel/Title 
@onready var card_description = $DescriptionPanel/Description
@onready var icon_container = $IconContainer
@onready var durability_label = $TargetingBoxContainer/DurabilityLabel
@onready var is_building = $IsBuilding

var energy_icons: Dictionary[GameResource.Type, String] = {
	GameResource.Type.GREEN_ENERGY: "green_energy",
	GameResource.Type.BLUE_ENERGY: "blue_energy",
	GameResource.Type.PURPLE_ENERGY: "purple_energy",
	GameResource.Type.NONE: "none_energy"
}

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
	
	
	if card.has_slot_effect():
		card_background.texture =  PreloadScenes.CARD_BACKGROUND_UIDS["green_card"]

	
	# Update UI elements
	card_title.text = card.display_name
	card_description.text = card.rules_text
	if card.durability.amount >= 0:
		durability_label.text = "Durability: " + str(card.durability.amount) + "/" + str(card.durability.max_amount)
	else:
		durability_label.text = ""
		
	add_slot_icon(energy_icons[card.cost.get_energy_color()], str(card.cost.get_energy_cost()), %TopHBoxContainer, GameIcon.TextSize.SMALL)
	
	if not card.has_instinct_effect() and card.has_slot_effect():
		is_building.visible = true
	else:
		is_building.visible = false
		

func refresh():
	card_title.text = card_data.display_name
	card_description.text = card_data.rules_text
	if card_data.durability.amount >= 0:
		durability_label.text = "Durability: " + str(card_data.durability.amount) + "/" + str(card_data.durability.max_amount)
	else:
		durability_label.text = ""

func add_slot_icon(icon_image: String, value: String, container: Container, font_size: GameIcon.TextSize) -> void:
	var slot_icon: SlotIcon = PreloadScenes.ICONS["slot"].instantiate()
		
	if not UidManager.SLOT_ICON_UIDS.has(name):
		print("Couldn't load icon because not in SLOT_ICON_UIDS: " + name)
	
	slot_icon.set_slot_image(icon_image)
	container.add_child(slot_icon)
	await get_tree().process_frame
	# Wait for the node to initialize, then set the label text
	slot_icon.set_string_text(value, font_size, Color.BLACK)	

					
# These mouse events are reached first, then the functions in the HandContainer second
func __on_mouse_entered() -> void:
	GlobalSignals.signal_ui_card_hovered(card_data.instance_id)

func __on_mouse_exited() -> void:
	GlobalSignals.signal_ui_card_unhovered(card_data.instance_id)
	
