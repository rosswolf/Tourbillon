extends Control

@onready var animation_player := $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	GlobalSignals.core_game_over.connect(__on_game_over)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func resume():
	hide()
	get_tree().paused = false 
	animation_player.play_backwards("blur")
	
func __on_game_over():
	show()	
	animation_player.play("blur")
	get_tree().paused = true


func __on_quit_to_main_pressed() -> void:
	resume()
	GlobalSignals.signal_ui_quit_to_main()

func __on_exit_game_pressed() -> void:
	get_tree().quit()
