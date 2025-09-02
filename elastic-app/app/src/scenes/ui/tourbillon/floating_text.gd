extends Node2D
class_name FloatingText

## Simple floating text that animates up and fades out

@onready var label: Label = $Label

var text: String = ""
var color: Color = Color.WHITE
var duration: float = 1.0
var rise_distance: float = 50.0

func _ready() -> void:
	if label:
		label.text = text
		label.modulate = color
		__animate()

func setup(text_value: String, color_value: Color, duration_value: float = 1.0) -> void:
	text = text_value
	color = color_value
	duration = duration_value

func __animate() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Float upward
	tween.tween_property(self, "position:y", position.y - rise_distance, duration)
	
	# Fade out
	tween.tween_property(label, "modulate:a", 0.0, duration)
	
	# Scale slightly
	tween.tween_property(label, "scale", Vector2(1.2, 1.2), duration * 0.3)
	
	# Queue free when done
	tween.chain().tween_callback(queue_free)