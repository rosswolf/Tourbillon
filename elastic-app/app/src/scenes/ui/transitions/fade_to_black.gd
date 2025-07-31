extends CanvasLayer

@onready var color_rect: ColorRect = $FadeColorRect

@export var switch_duration: float = 1.0
var current_scene: String = ""

func _init():	
	current_scene = "res://src/scenes/main_menu.tscn"

func _ready() -> void:
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	color_rect.modulate.a = 0


func go_to_scene(scene: String):
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var tween = get_tree().create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(color_rect, "modulate:a", 1, switch_duration / 2.0)
	await tween.finished
	
	get_tree().change_scene_to_file(scene)
	get_tree().paused = false
	current_scene = scene
	
	tween = get_tree().create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(color_rect, "modulate:a", 0, switch_duration / 2.0)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
