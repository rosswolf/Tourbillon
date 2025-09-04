extends Control

const MAIN_MENU = "res://src/scenes/main_menu.tscn"

func _ready() -> void:
	%Timer.wait_time = 7
	%Timer.timeout.connect(func():FadeToBlack.go_to_scene(MAIN_MENU))
	%Timer.start()
