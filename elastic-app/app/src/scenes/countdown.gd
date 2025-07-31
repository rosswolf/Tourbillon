extends Control
const GAME: String = "res://src/scenes/game.tscn"

func _ready():
	%Timer.start()
	%Timer.timeout.connect(_on_timer_timeout)  # Connect to the timer's signal
	
func render_label():
	var time_left: float = %Timer.time_left
	var second: int = fmod(time_left, 60)
	if second > 3:
		return "Take a deep breath"
	elif second == 0:
		return ""
	else:
		return str(second)
	
func _process(delta):
	%Label.text = render_label()

func _on_timer_timeout():
	FadeToBlack.go_to_scene(GAME, Color.WHITE)
