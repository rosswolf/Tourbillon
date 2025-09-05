extends GameIcon
class_name SlotIcon

const SMALL_FONT_SIZE: int = 20
const LARGE_FONT_SIZE: int = 30

func _ready() -> void:
	super._ready()

func set_slot_image(name: String) -> void:
	%SlotTexture.texture = GlobalUtilities.load_slot_icon_image(name)

func get_label() -> Label:
	return %IconLabel

func get_small_font_size() -> int:
	return SMALL_FONT_SIZE

func get_large_font_size() -> int:
	return LARGE_FONT_SIZE
