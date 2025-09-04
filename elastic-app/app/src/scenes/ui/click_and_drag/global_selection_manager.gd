extends Node

var __hovered: String = ""
var __selected: String = ""

func _init() -> void:
	GlobalSignals.ui_card_hovered.connect(__on_card_hovered)
	GlobalSignals.ui_card_unhovered.connect(__on_card_unhovered)
	
func __on_card_hovered(instance_id: String) -> void:
	set_hovered(instance_id)
	
func __on_card_unhovered(instance_id: String) -> void:
	clear_hovered_known(instance_id)

func set_hovered(instance_id: String) -> void:
	if __hovered != "":
		print("hover wasnt unset") #This can legit happen for 2 adjacent bodies
	
	__hovered = instance_id

func clear_hovered_known(instance_id: String) -> void:
	if __hovered != instance_id:
		print("__hovered doesn't match " + __hovered + " " + instance_id)
	clear_hovered_force()

func clear_hovered_force() -> void:
	__hovered = ""

func get_hovered() -> String:
	return __hovered
	
func has_hovered() -> bool:
	return __hovered != ""

func is_card_hovered() -> bool:
	if __hovered == "":
		return false
	return __hovered.begins_with("card_") or __hovered.begins_with("building_")

func is_card_selected() -> bool:
	if __selected == "":
		return false
	return __selected.begins_with("card_")
			
func set_selected_known(instance_id: String) -> void:
	if __hovered != instance_id:
		assert(false, "_hovered doesnt match expected choice " + __hovered + " " + instance_id)
	else:
		set_selected_force()
		
func set_selected_force() -> void:
	if __hovered == "":
		assert(false, "forced choice when _hover was blank")
	else:
		__selected = __hovered
		GlobalSignals.signal_ui_selected_changed(__selected)
	
func __clear_selected_force() -> void:
	__selected = ""
	GlobalSignals.signal_ui_selected_changed(__selected)

func get_selected() -> String:
	return __selected
	
func has_selected() -> bool:
	return __selected != ""
	
func activate_selected_onto_hovered(last_pos: Vector2) -> void:
	if __selected == "":
		return
	else:
		print("execute: " + __selected + " " + __hovered)
		GlobalSignals.signal_ui_execute_selected_onto_hovered(__selected, __hovered)
		__clear_selected_force()
		
	
class Activation:
	var _source : String
	var _target : String
	
	func _init(source: String, target: String) -> void:
		_source = source
		_target = target
