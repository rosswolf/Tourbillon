extends Control

@onready var settings_container := $SettingsCenterContainer

const GAME: String = "res://src/scenes/game.tscn"


func _ready() -> void:
	%Play.pressed.connect(__play)
	%Settings.pressed.connect(__show_settings)
	%Quit.pressed.connect(__quit)
	%Close.pressed.connect(__close_settings)

func __play() -> void:
	GlobalGameManager.hero_template_id = "knight"
	FadeToBlack.go_to_scene(GAME)
	
func __show_settings() -> void:
	settings_container.set_mouse_filter(Control.MOUSE_FILTER_STOP)
	settings_container.show()
	

func __close_settings() -> void:
	settings_container.set_mouse_filter(Control.MOUSE_FILTER_IGNORE)
	settings_container.hide()
	
		
func __quit() -> void:
	get_tree().quit()
