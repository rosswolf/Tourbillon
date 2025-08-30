extends Control
class_name GameIcon

# For simplicity, icons only support two text sizes
# (Godot does not provide font size scaling in the same way as the TextureRect)
enum TextSize {
	VERY_SMALL,
	SMALL,
	LARGE
}

func _ready() -> void:
	pass # Replace with function body.

func get_label() -> Label:
	assert(false, "GameIcon Subclass didn't implement mandatory function get_label")
	return null

func get_very_small_font_size() -> int:
	return 10
	
func get_small_font_size() -> int:
	assert(false, "GameIcon Subclass didn't implement mandatory function get_small_font_size")
	return 0
	
func get_large_font_size() -> int:
	assert(false, "GameIcon Subclass didn't implement mandatory function get_large_font_size")
	return 0

# TODO: add the outline size functions

func set_text(value: int, size: TextSize, font_color: Color = Color.WHITE) -> void:
	var text = ""
	if value != -1:
		text = str(value)
	set_string_text(text, size, font_color)
	
func set_string_text(value: String, size: TextSize, font_color: Color = Color.WHITE) -> void:
	get_label().text = value
	set_label_font(size, font_color)
	
func set_label_font(size: TextSize, font_color: Color) -> void:
	var font_size: int
	var outline_size: int
	match size:
		TextSize.VERY_SMALL:
			font_size = get_very_small_font_size()
			outline_size = 2
		TextSize.SMALL:
			font_size = get_small_font_size()
			outline_size = 6
		TextSize.LARGE:
			font_size = get_large_font_size()
			outline_size = 8

	# Ensure the label has its own theme
	if get_label().theme == null:
		assert(false, "Every GameIcon should have a theme set on the label")
	
	get_label().theme = get_label().theme.duplicate()
	
	get_label().add_theme_font_size_override("font_size", font_size)
	get_label().add_theme_constant_override("outline_size", outline_size)
	get_label().add_theme_color_override("font_color", font_color)
	
	if font_color == Color.BLACK:
		get_label().add_theme_color_override("font_outline_color", Color.WHITE)
	
	# Force refresh
	get_label().queue_redraw()
	get_label().notify_property_list_changed()
