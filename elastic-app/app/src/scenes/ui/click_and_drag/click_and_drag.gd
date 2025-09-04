extends Node

const IMAGE_CURSOR = preload("res://src/scenes/ui/click_and_drag/image_cursor.tscn")

var targeting_visual: Cursor = null
var card_image_uid: String = ""

func _ready() -> void:
	GlobalSignals.ui_changed_cursor_image.connect(__on_cursor_image_changed)
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and GlobalSelectionManager.is_card_hovered():
			GlobalSelectionManager.set_selected_force()
			add_dragging_visual()
		elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			if targeting_visual != null:
				if targeting_visual.is_valid_target():
					GlobalSelectionManager.activate_selected_onto_hovered(targeting_visual.position)
				else:
					GlobalSelectionManager._clear_selected_force()
				remove_dragging_visual()
				
				
func add_dragging_visual():
	targeting_visual = get_relevant_visual()
	%HUD.add_child(targeting_visual)
	targeting_visual.global_position = get_global_mouse_position()
	
func remove_dragging_visual() -> void:
	if targeting_visual != null:
		var last_pos = targeting_visual.position
		targeting_visual.queue_free()
		targeting_visual = null
		return last_pos
	else:
		return null
	
func get_relevant_visual() -> Node:
	var selected_instance_id = GlobalSelectionManager.get_selected()	
	var card = GlobalGameManager.instance_catalog.get_instance(selected_instance_id) as Card
	
	# Note that the cursor AND all of its child nodes need to have MOUSE_FILTER_IGNORE set
	var cursor = IMAGE_CURSOR.instantiate()
		
	if card:
		card_image_uid = card.cursor_image_uid
		cursor.update_image(card_image_uid)			
	return cursor

func __on_cursor_image_changed(image_uid: String) -> void:
	if targeting_visual == null:
		return
	if image_uid == "":
		# Restore the original image from the card
		targeting_visual.update_image(card_image_uid)
		return
	targeting_visual.update_image(image_uid)

func get_global_mouse_position() -> Vector2:
	var camera = get_viewport().get_camera_2d()
	if camera:
		return camera.get_global_mouse_position()
	else:
		return get_viewport().get_mouse_position()
