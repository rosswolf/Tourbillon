extends PanelContainer
class_name MainMenuBar

var resource_labels: Dictionary[GameResource.Type, Label]

func _ready() -> void:
	GlobalSignals.core_hero_resource_changed.connect(_on_resource_changed)
	
	# Initalize the resource labels
	#resource_labels[GameResource.Type.CURRENT_HEALTH] = %CurrentHealthDisplay
	#resource_labels[GameResource.Type.MAX_HEALTH] = %MaxHealthDisplay
	#resource_labels[GameResource.Type.GOLD] = %GoldDisplay
	#resource_labels[GameResource.Type.INSTINCT] = %InstinctDisplay
	#resource_labels[GameResource.Type.TRAINING_POINTS] = %XPDisplay
	#resource_labels[GameResource.Type.ENDURANCE] = %EnduranceDisplay

func _on_resource_changed(type: GameResource.Type, value: int) -> void:
	if type not in resource_labels:
		return
	
	var label = resource_labels[type]
	label.text = str(value)
				

	
