extends Control

@onready var animation_player := $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	GlobalSignals.core_game_over.connect(__on_game_over)
	%QuitToMain.pressed.connect(__on_quit_to_main_pressed)
	%ExitGame.pressed.connect(__on_exit_game_pressed)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func resume() -> void:
	hide()
	get_tree().paused = false 
	animation_player.play_backwards("blur")
	
func __on_game_over() -> void:
	show()	
	animation_player.play("blur")
	get_tree().paused = true


func __on_quit_to_main_pressed() -> void:
	resume()
	FadeToBlack.go_to_scene("res://src/scenes/main_menu.tscn")

func __on_exit_game_pressed() -> void:
	get_tree().quit()
