extends Control

var default_timer_max: float = 300.0

const MENU: String = "res://src/scenes/main_menu.tscn"

var __timer_max: float = default_timer_max
var timer_max: float:
	get:
		return __timer_max
	set(value):
		__timer_max = value
		
var time_remaining: float:
	get: 
		return %Timer.time_left
	set(value):
		var new_value = min(timer_max, value)
		%Timer.start(new_value)

func _ready():
	print(timer_max)
	%Timer.wait_time = 300
	%Timer.timeout.connect(_on_timer_timeout)
	%Timer.start()
	%ProgressBar.value = pct(%Timer.time_left, timer_max)
	GlobalSignals.core_time_added.connect(__on_time_added)

func __on_time_added(amount: float):
	time_remaining = time_remaining + amount
	
func pct(numerator: float, denominator: float):
	if denominator <= 0.001:
		return 0.0
	else:
		return 100.0 * numerator / denominator	
	
func start():
	%Timer.start()

func _process(delta):
	%ProgressBar.value = pct(%Timer.time_left, timer_max)
	%Label.text = render_label(%Timer.time_left)
	%MaxLabel.text = render_label(timer_max)
	
func render_label(time_left: float):
	var minute: int = time_left / 60	
	var second: int = fmod(time_left, 60)
	var centisecond: int = int(fmod(time_left, 1.0) * 100)
	return str(minute) + ":" + str(second) + "." + "%02d" % centisecond

func _on_timer_timeout():
	print("done")
	#FadeToBlack.go_to_scene(MENU)
