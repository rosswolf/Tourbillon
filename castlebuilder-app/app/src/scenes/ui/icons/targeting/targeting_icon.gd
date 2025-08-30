extends GameIcon
class_name TargetingIcon

const SMALL_FONT_SIZE: int = 20
const LARGE_FONT_SIZE: int = 30


func _ready() -> void:
	super._ready()

	
func get_label() -> Label:
	return %TargetingLabel

func get_small_font_size() -> int:
	return SMALL_FONT_SIZE
	
func get_large_font_size() -> int:
	return LARGE_FONT_SIZE
