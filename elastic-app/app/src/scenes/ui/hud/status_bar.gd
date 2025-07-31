extends Control


@onready var container: VBoxContainer
var status_items: Dictionary = {}  # Dictionary to track status items by enum
var status_bar_width = 36
var top_margin = 80  # Space for MenuBar
var left_margin = 20  # Space from the left edge of the screen

func _ready() -> void:
	GlobalSignals.core_hero_resource_changed.connect(_on_status_item_updated)
	
	# Set up the main status bar container with top margin
	anchor_left = 0.0
	anchor_right = 0.0
	anchor_top = 0.0
	anchor_bottom = 1.0
	
	offset_left = left_margin
	offset_right = status_bar_width
	offset_top = top_margin  # Start below the MenuBar
	offset_bottom = 0
	
	custom_minimum_size.x = status_bar_width
	# Create the VBoxContainer for vertical stacking
	container = VBoxContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_theme_constant_override("separation", 5)  # Space between items
	add_child(container)
	
	initialize_base_resources()

func add_status_item(item: Control) -> void:
	container.add_child(item)

func add_status_item_with_type(item: Control, type: GameResource.Type) -> void:
	container.add_child(item)
	status_items[type] = item

func add_status_item_at_position(item: Control, position: int) -> void:
	container.add_child(item)
	container.move_child(item, position)

func add_status_item_at_position_with_type(item: Control, position: int, type: GameResource.Type) -> void:
	container.add_child(item)
	container.move_child(item, position)
	status_items[type] = item

func remove_status_item(item: Control) -> void:
	if item.get_parent() == container:
		# Remove from dictionary if it exists
		for key in status_items.keys():
			if status_items[key] == item:
				status_items.erase(key)
				break
		container.remove_child(item)
		item.queue_free()

func remove_status_item_by_type(type: GameResource.Type) -> void:
	if type in status_items:
		var item = status_items[type]
		status_items.erase(type)
		if item.get_parent() == container:
			container.remove_child(item)
			item.queue_free()

func remove_status_item_at_index(index: int) -> void:
	if index >= 0 and index < container.get_child_count():
		var item = container.get_child(index)
		remove_status_item(item)

func clear_status_items() -> void:
	for child in container.get_children():
		child.queue_free()
	status_items.clear()

func get_status_item_count() -> int:
	return container.get_child_count()

func get_status_item_by_type(type: GameResource.Type) -> Control:
	return status_items.get(type, null)

func has_status_item_type(type: GameResource.Type) -> bool:
	return type in status_items

func update_status_item_text(type: GameResource.Type, new_text: String) -> void:
	if type in status_items:
		var item = status_items[type]
		# Assuming the item has a label as the second child (after the icon)
		if item.get_child_count() > 1:
			var label = item.get_child(1) as Label
			if label:
				label.text = new_text

func _on_status_item_updated(type: GameResource.Type, value: int) -> void:
	update_status_item_text(type, str(value))
	
# Helper function to create a status item with icon and text overlaid
func create_icon_text_status(texture_path: String, text: String, color: Color = Color.WHITE) -> Control:
	var container = Control.new()
	container.custom_minimum_size = Vector2(32, 32)
	
	var icon_rect = TextureRect.new()
	icon_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_rect.scale = icon_rect.scale * 1.5
	if texture_path == "":
		print("Image not specified as string path")
	else:
		var loaded_texture = load(texture_path)
		if loaded_texture is Texture2D:
			icon_rect.texture = loaded_texture
		else:
			push_warning("Invalid texture path: %s" % texture_path)
			
	var label = Label.new()
	label.text = text
	label.modulate = color
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Create LabelSettings for outline
	var label_settings = LabelSettings.new()
	label_settings.font_size = 14
	label_settings.outline_color = Color.BLACK
	label_settings.outline_size = 3  # Adjust thickness as needed
	# Apply the settings to the label
	label.label_settings = label_settings
	
	container.add_child(icon_rect)
	container.add_child(label)
	
	return container

func initialize_base_resources() -> void:
	init_individual_resource("res://owned_assets/goldcoin.png", GameResource.Type.GOLD)
	init_individual_resource("res://cc0_assets/tile427.png",GameResource.Type.TRAINING_POINTS)
	init_individual_resource("res://cc0_assets/tile446.png", GameResource.Type.INSTINCT)
	init_individual_resource("res://cc0_assets/tile422.png", GameResource.Type.ENDURANCE)


func init_individual_resource(resource: String, type: GameResource.Type):
	var item = create_icon_text_status(resource, "0", Color.WHITE)
	add_status_item_with_type(item, type)
