extends TextureButton
class_name EngineSlotSimple

## Pure UI marker for mainplate slots - no game logic
## Just visual representation and input handling

@onready var name_label: Label = $%Name
@onready var progress_bar: ProgressBar = $%ProgressBar
@onready var main_panel: Panel = $%MainPanel

# Visual state only
var grid_position: Vector2i = Vector2i(-1, -1)
var is_active_slot: bool = false
var is_bonus_square: bool = false
var bonus_type: String = ""
var is_occupied: bool = false

# Signals for interaction
signal slot_clicked(grid_position: Vector2i)
signal slot_hovered(grid_position: Vector2i)
signal slot_unhovered(grid_position: Vector2i)

func _ready() -> void:
	pressed.connect(__on_pressed)
	mouse_entered.connect(__on_mouse_entered)
	mouse_exited.connect(__on_mouse_exited)

	# Start with empty visuals
	__update_empty_visual()

## Set the grid position for this slot
func set_grid_position(pos: Vector2i) -> void:
	grid_position = pos

## Set whether this slot is active (can accept cards)
func set_active(active: bool) -> void:
	is_active_slot = active
	if active:
		mouse_filter = Control.MOUSE_FILTER_STOP
		disabled = false
		modulate = Color.WHITE
	else:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		disabled = true
		modulate = Color(0.3, 0.3, 0.3, 0.1)

## Set this slot as a bonus square
func set_as_bonus_square(type: String = "draw_one_card") -> void:
	is_bonus_square = true
	bonus_type = type
	__update_bonus_visual()

## Update visual when card is placed
func set_occupied_visual(card_name: String, texture: Texture2D = null) -> void:
	is_occupied = true
	name_label.text = card_name
	main_panel.visible = true
	if texture:
		texture_normal = texture

## Update visual when card is removed
func set_empty_visual() -> void:
	is_occupied = false
	__update_empty_visual()

## Show production progress (0-100)
func show_progress(percent: float, is_ready: bool = false) -> void:
	progress_bar.visible = true
	progress_bar.value = percent

	# Color based on state
	if is_ready:
		progress_bar.modulate = Color(0.0, 1.0, 0.0, 1.0)  # Green
	else:
		progress_bar.modulate = Color(1.0, 1.0, 0.0, 1.0)  # Yellow

## Hide progress bar
func hide_progress() -> void:
	progress_bar.visible = false

## Visual highlight for hover/selection
func set_highlighted(highlighted: bool) -> void:
	if highlighted:
		modulate = Color(1.2, 1.2, 1.2)
	else:
		modulate = Color.WHITE
		if is_bonus_square:
			__update_bonus_visual()

## Private methods

func __on_pressed() -> void:
	if is_active_slot:
		slot_clicked.emit(grid_position)

func __on_mouse_entered() -> void:
	if is_active_slot:
		slot_hovered.emit(grid_position)
		set_highlighted(true)

func __on_mouse_exited() -> void:
	if is_active_slot:
		slot_unhovered.emit(grid_position)
		set_highlighted(false)

func __update_empty_visual() -> void:
	name_label.text = ""
	main_panel.visible = is_active_slot
	progress_bar.visible = false
	texture_normal = null

func __update_bonus_visual() -> void:
	match bonus_type:
		"draw_two_cards":
			modulate = Color(1.3, 0.9, 1.3)  # Purple
		"draw_one_card":
			modulate = Color(1.2, 1.2, 0.8)  # Yellow
		_:
			modulate = Color.WHITE