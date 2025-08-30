extends Control
class_name Cursor

func is_valid_target():
	# Always return true, since we check valid targets later on... leaving this for now in case
	# we want to change the model. 
	return true

func update_image(texture_uid: String) -> void:
	pass
