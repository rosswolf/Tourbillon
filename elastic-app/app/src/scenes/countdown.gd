extends Control
const GAME: String = "res://src/scenes/game.tscn"

func _ready() -> void:
	%Timer.start()
	%Timer.timeout.connect(_on_timer_timeout)  # Connect to the timer's signal
	
func render_label() -> String:
	var time_left: float = %Timer.time_left
	var second: int = fmod(time_left, 60)
	if second > 3:
		return "Take a deep breath"
	elif second == 0:
		return ""
	else:
		return str(second)
	
func _process(delta: float) -> void:
	%Label.text = render_label()

func _on_timer_timeout() -> void:
	FadeToBlack.go_to_scene(GAME, Color.WHITE)
