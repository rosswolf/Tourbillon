extends PanelContainer
class_name MainMenuBar

var resource_labels: Dictionary[GameResource.Type, Label]

func _ready() -> void:
	GlobalSignals.core_hero_resource_changed.connect(_on_resource_changed)

	# Initialize the resource labels for Tourbillon forces
	# Color forces
	if has_node("%RedDisplay"):
		resource_labels[GameResource.Type.RED] = %RedDisplay
	if has_node("%BlueDisplay"):
		resource_labels[GameResource.Type.BLUE] = %BlueDisplay
	if has_node("%GreenDisplay"):
		resource_labels[GameResource.Type.GREEN] = %GreenDisplay
	if has_node("%WhiteDisplay"):
		resource_labels[GameResource.Type.WHITE] = %WhiteDisplay
	if has_node("%PurpleDisplay"):
		resource_labels[GameResource.Type.PURPLE] = %PurpleDisplay

	# Physical forces
	if has_node("%HeatDisplay"):
		resource_labels[GameResource.Type.HEAT] = %HeatDisplay
	if has_node("%PrecisionDisplay"):
		resource_labels[GameResource.Type.PRECISION] = %PrecisionDisplay
	if has_node("%MomentumDisplay"):
		resource_labels[GameResource.Type.MOMENTUM] = %MomentumDisplay
	if has_node("%BalanceDisplay"):
		resource_labels[GameResource.Type.BALANCE] = %BalanceDisplay
	if has_node("%EntropyDisplay"):
		resource_labels[GameResource.Type.ENTROPY] = %EntropyDisplay

func _on_resource_changed(type: GameResource.Type, value: int) -> void:
	if type not in resource_labels:
		return

	var label = resource_labels[type]
	label.text = str(value)



