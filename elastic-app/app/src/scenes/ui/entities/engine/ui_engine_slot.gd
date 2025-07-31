extends UiTextureButton
class_name EngineSlot

@onready var activation_button: ActivationButton = $ActivationButton
@onready var activation_image: TextureRect = $ActivationButton/ButtonImage
@onready var slotted_image: TextureRect = $SlottedImage
@onready var background_slot: TextureRect = $BackgroundSlot
@onready var top_container: HBoxContainer = $VBoxContainer/TopBoxContainer
@onready var bottom_container: HBoxContainer = $VBoxContainer/BottomBoxContainer
@onready var training_label: Label = $TrainingLabel

var attached_card: Card
var trigger_resource: GameResource.Type = GameResource.Type.UNKNOWN
var is_activatable: bool
var icon_counter: int

enum ConnectionType {
	ONE_WAY,
	TWO_WAY
}

enum Direction {
	UP,
	RIGHT,
	DOWN,
	LEFT
}

func _ready() -> void:
	super._ready()
	is_activatable = true
	icon_counter = 0
	create_button_entity(self, false)
	
	#self.pressed.connect(__on_refresh_slot_manually)
	GlobalSignals.core_end_turn.connect(__on_end_turn)
	
	# Hide nodes we don't need yet
	await get_tree().process_frame
	top_container.visible = true
	bottom_container.visible = false
	slotted_image.visible = false
	activation_button.visible = false
	hide_all_connections()

func __on_end_turn() -> void:
	pass
	#if not is_activatable:
	#	reactivate_slot()
	
func has_card() -> bool:
	return attached_card != null
	
func attach_card(card: Card) -> void:
	attached_card = card
	slotted_image.visible = true
	training_label.visible = false
	
	var move_pieces: Array[MoveParser.MovePiece] = attached_card.__slot_effect.move_list
	
	for move in move_pieces:
		var slot_icon: SlotIcon = PreloadScenes.ICONS["slot"].instantiate()
		
		if UidManager.SLOT_ICON_UIDS.has(move.name):
			slot_icon.set_slot_image(move.name)
		else:
			print("Couldn't load icon because not in SLOT_ICON_UIDS: " + move.name)
		
		add_icon(slot_icon, move.get_value())
	
	if icon_counter == 1:
		# If we only have one icon, we need to increase the font size
		await get_tree().process_frame
		var node: GameIcon = top_container.get_child(0)
		node.set_label_font(GameIcon.TextSize.LARGE, Color.WHITE)
	
func add_icon(slot_icon: SlotIcon, value: int) -> void:	
	# First, add the node
	if icon_counter < 2:
		top_container.add_child(slot_icon)	
	else:
		bottom_container.visible = true
		bottom_container.add_child(slot_icon)
	
	icon_counter += 1
	await get_tree().process_frame
	# Wait for the node to initialize, then set the label text
	slot_icon.set_text(value, GameIcon.TextSize.SMALL)		
		
	
func detach_card() -> void:
	if attached_card == null:
		return
	
	#TODO: should this not be in the UI code?
	if GlobalGameManager.relic_manager.has_relic("training_gloves"):	
		GlobalGameManager.library.move_card_to_zone(attached_card.instance_id, Library.Zone.HAND, Library.Zone.SLOTTED)
	else:
		GlobalGameManager.library.move_card_to_zone(attached_card.instance_id, Library.Zone.GRAVEYARD, Library.Zone.SLOTTED)
	attached_card = null
	slotted_image.texture = null
	slotted_image.visible = false

func set_training_value(value: int) -> void:
	training_label.set_text(str(value))
							
func deactivate_slot() -> void:	
	is_activatable = false
	# Gray out the slot image
	background_slot.modulate = Color(0.8, 0.8, 0.8, 0.8)
	slotted_image.modulate = Color(0.8, 0.8, 0.8, 0.8)

func reactivate_slot() -> void:	
	is_activatable = true
	# Restore normal colors
	background_slot.modulate = Color.WHITE
	slotted_image.modulate = Color.WHITE

func __on_refresh_slot_manually() -> void:
	# Player can left click on slot to refresh using endurance
	if not is_activatable and GlobalGameManager.relic_manager.has_relic("training_gloves"):
		GlobalGameManager.hero.endurance.decrement(1)
		reactivate_slot()
		
func activate(trigger_card: Card) -> void:
	if has_card() and is_activatable:
		deactivate_slot()
		
		attached_card.__slot_effect.activate(trigger_card)

		# Emit signal to notify the template that this slot was activated
		GlobalSignals.signal_ui_slot_activated(name, trigger_card.instance_id)

# Connection visual management functions

func show_connection(direction: Direction, connection_type: ConnectionType) -> void:
	var connection_node = __get_connection_node(direction, connection_type)
	if connection_node:
		connection_node.visible = true

func hide_connection(direction: Direction) -> void:
	# Hide both one-way and two-way connections for this direction
	var one_way_node = __get_connection_node(direction, ConnectionType.ONE_WAY)
	var two_way_node = __get_connection_node(direction, ConnectionType.TWO_WAY)
	
	if one_way_node:
		one_way_node.visible = false
	if two_way_node:
		two_way_node.visible = false

func hide_all_connections() -> void:
	%UpOneWay.visible = false
	%RightOneWay.visible = false
	%DownOneWay.visible = false
	%LeftOneWay.visible = false
	%UpTwoWay.visible = false
	%RightTwoWay.visible = false
	%DownTwoWay.visible = false
	%LeftTwoWay.visible = false

func __get_connection_node(direction: Direction, connection_type: ConnectionType) -> TextureRect:
	match [direction, connection_type]:
		[Direction.UP, ConnectionType.ONE_WAY]:
			return %UpOneWay
		[Direction.UP, ConnectionType.TWO_WAY]:
			return %UpTwoWay
		[Direction.RIGHT, ConnectionType.ONE_WAY]:
			return %RightOneWay
		[Direction.RIGHT, ConnectionType.TWO_WAY]:
			return %RightTwoWay
		[Direction.DOWN, ConnectionType.ONE_WAY]:
			return %DownOneWay
		[Direction.DOWN, ConnectionType.TWO_WAY]:
			return %DownTwoWay
		[Direction.LEFT, ConnectionType.ONE_WAY]:
			return %LeftOneWay
		[Direction.LEFT, ConnectionType.TWO_WAY]:
			return %LeftTwoWay
		_:
			return null

# Utility functions to check current connections

func has_connection_in_direction(direction: Direction) -> bool:
	var one_way_node = __get_connection_node(direction, ConnectionType.ONE_WAY)
	var two_way_node = __get_connection_node(direction, ConnectionType.TWO_WAY)
	
	return (one_way_node and one_way_node.visible) or (two_way_node and two_way_node.visible)

func get_connection_type_in_direction(direction: Direction) -> ConnectionType:
	var two_way_node = __get_connection_node(direction, ConnectionType.TWO_WAY)
	if two_way_node and two_way_node.visible:
		return ConnectionType.TWO_WAY
	
	var one_way_node = __get_connection_node(direction, ConnectionType.ONE_WAY)
	if one_way_node and one_way_node.visible:
		return ConnectionType.ONE_WAY
	
	# Return a default if no connection (this shouldn't happen if used correctly)
	return ConnectionType.ONE_WAY

func set_activation_type(type: GlobalUtilities.TriggerType) -> void:
	activation_button.visible = true
	trigger_resource = GlobalUtilities.get_associated_trigger_resource(type)
	
	# Load the corresponding image
	if trigger_resource == GameResource.Type.GREEN_TRIGGER:
		activation_image.texture = GlobalUtilities.load_image("green_activation_trigger_button")
	elif trigger_resource == GameResource.Type.RED_TRIGGER:
		activation_image.texture = GlobalUtilities.load_image("red_activation_trigger_button")
	elif trigger_resource == GameResource.Type.BLUE_TRIGGER:
		activation_image.texture = GlobalUtilities.load_image("blue_activation_trigger_button")
	else:
		printerr("Attempted to load undefined trigger type")
