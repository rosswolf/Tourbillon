class_name CardUI
extends Control

# UI Components
@onready var card_background: Control = $CardBackground
@onready var card_title: Control = $TitlePanel/Title
@onready var card_description: Control = $DescriptionPanel/Description
@onready var icon_container: Container = $IconContainer
@onready var tick_cost_label: Label = $IconContainer/TopHBoxContainer/TickCostCircle/CenterContainer/TickCostLabel  # Gray circle for tick cost
@onready var efficiency_label: Label = null  # Efficiency label removed for now
@onready var is_building: Control = $IsBuilding

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

func _ready() -> void:
	# Connect mouse input signals
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(__on_mouse_entered)
	mouse_exited.connect(__on_mouse_exited)

	# Set initial pivot point for rotation
	pivot_offset = size / 2

# Set card data and update UI
func set_card_data(card: Card) -> void:
	if not is_node_ready():
		await self.ready

	card_data = card


	# Cards with production are considered "slot" cards (green background)
	# DISABLED: Green background was making all gear cards look green
	# if card.production_interval > 0:
	#	card_background.texture =  PreloadScenes.CARD_BACKGROUND_UIDS["green_card"]


	# Update UI elements
	card_title.text = card.display_name
	card_description.text = card.rules_text

	# Show tick cost in gray circle (time_cost field)
	if tick_cost_label:
		tick_cost_label.text = str(card.time_cost) if card.time_cost > 0 else "0"

	# Calculate and show efficiency (for cards with production_interval)
	if efficiency_label:
		if card.production_interval > 0:
			# Efficiency = production per tick (simplified display)
			var efficiency: float = 1.0 / card.production_interval
			efficiency_label.text = "Eff: %.2f/tick" % efficiency
		elif card.production_interval == -1:
			# -1 means no production
			efficiency_label.text = ""
		else:
			# 0 or other invalid values - shouldn't happen but handle gracefully
			efficiency_label.text = ""

	# Energy cost icons can be added later if needed
	# add_slot_icon(energy_icons[card.cost.get_energy_color()], str(card.cost.get_energy_cost()), %TopHBoxContainer, GameIcon.TextSize.SMALL)

	# Cards with production interval are "buildings"
	# DISABLED: "IsBuilding" indicator was showing as a box in corner
	# if card.production_interval > 0:
	#	is_building.visible = true
	# else:
	#	is_building.visible = false
	if is_building:
		is_building.visible = false


func refresh() -> void:
	card_title.text = card_data.display_name
	card_description.text = card_data.rules_text

	# Update tick cost display
	if tick_cost_label:
		tick_cost_label.text = str(card_data.time_cost) if card_data.time_cost > 0 else "0"

	# Update efficiency display
	if efficiency_label:
		if card_data.production_interval > 0:
			var efficiency: float = 1.0 / card_data.production_interval
			efficiency_label.text = "Eff: %.2f/tick" % efficiency
		elif card_data.production_interval == -1:
			# -1 means no production
			efficiency_label.text = ""
		else:
			# 0 or other invalid values
			efficiency_label.text = ""

func add_slot_icon(icon_image: String, value: String, container: Container, font_size: GameIcon.TextSize) -> void:
	var slot_icon: SlotIcon = PreloadScenes.ICONS["slot"].instantiate()

	if not UidManager.SLOT_ICON_UIDS.has(name):
		print("[DEBUG] Couldn't load icon because not in SLOT_ICON_UIDS: " + name)

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

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Signal that a card was clicked for drag start
				GlobalSignals.signal_ui_card_clicked(card_data.instance_id)
				# Stop the event from propagating to prevent conflicts
				get_viewport().set_input_as_handled()
