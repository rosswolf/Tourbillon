extends GameIcon
class_name RelicIcon

var __relic: Relic

const SMALL_FONT_SIZE: int = 20
const LARGE_FONT_SIZE: int = 30

func _ready() -> void:
	super._ready()
	
func set_relic(relic: Relic) -> void:
	__relic = relic
	
	if relic.starting_value != "-1":
		get_label().text = relic.starting_value
		get_label().visible = true
	
	%RelicTexture.texture = GlobalUtilities.load_image(relic.image_name)
	
func get_label() -> Label:
	return %RelicLabel

func get_small_font_size() -> int:
	return SMALL_FONT_SIZE
	
func get_large_font_size() -> int:
	return LARGE_FONT_SIZE
		
