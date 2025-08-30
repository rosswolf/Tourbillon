extends CanvasLayer

@onready var color_rect: ColorRect = $FadeColorRect

@export var switch_duration: float = 1.0


func _ready() -> void:
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	color_rect.modulate.a = 0


func go_to_scene(scene: String, fade_color: Color = Color.BLACK, fade_duration: float = switch_duration):
	
	
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	color_rect.color = fade_color
	
	var tween = get_tree().create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(color_rect, "modulate:a", 1, fade_duration / 2.0)
	await tween.finished
	
	get_tree().change_scene_to_file(scene)
	get_tree().paused = false
	
	tween = get_tree().create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(color_rect, "modulate:a", 0, fade_duration / 2.0)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
