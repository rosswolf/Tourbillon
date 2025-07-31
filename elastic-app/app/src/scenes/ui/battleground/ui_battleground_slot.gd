extends VBoxContainer

class_name UiBattlegroundSlot

@onready var targeting_preview = %TargetingPreview

func add_targeting_preview_icon():
	targeting_preview.show()
	
func remove_targeting_preview_icon():
	targeting_preview.hide()
