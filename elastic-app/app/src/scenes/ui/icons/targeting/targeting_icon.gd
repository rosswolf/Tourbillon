extends GameIcon
class_name TargetingIcon

const SMALL_FONT_SIZE: int = 20
const LARGE_FONT_SIZE: int = 30

var _targeting: Battleground.OrderPriority

func _ready() -> void:
	super._ready()

func set_targeting(targeting: Battleground.OrderPriority) -> void:
	_targeting = targeting
	
	get_label().text = Battleground.OrderPriority.find_key(targeting)
	get_label().visible = true
	
	
func get_label() -> Label:
	return %TargetingLabel

func get_small_font_size() -> int:
	return SMALL_FONT_SIZE
	
func get_large_font_size() -> int:
	return LARGE_FONT_SIZE
