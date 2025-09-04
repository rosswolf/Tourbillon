extends Control
var __sprite: AnimatedSprite2D

func set_sprite(sprite: AnimatedSprite2D, size: Vector2) -> void:
	
	%ReferenceAnimatedSprite2D.hide()
	
	
	if __sprite != null:
		remove_child(__sprite)
	
	add_child(sprite)
	__sprite = sprite
	
	# Set min_size to the largest frame across all animations
	__update_min_size(size)

func __update_min_size(size: Vector2) -> void:
	if __sprite == null or __sprite.sprite_frames == null:
		return
	# Set fixed minimum size regardless of sprite content
	
	custom_minimum_size = size
	__sprite.position = size / 2.0
	print("Set fixed size: ", custom_minimum_size)
