extends Control

class_name AirMeter

@export var rightmost_style: bool = false
@export var air_color: Air.AirColor = Air.AirColor.UNKNOWN
@export var default_timer_max: float = 20.0
@export var default_max_units: int = 1

@onready var timer: Timer = find_child("Timer")
@onready var progress_bar: ProgressBar = find_child("ProgressBar")  
@onready var label: Label = find_child("Label")
@onready var max_label: Label = find_child("MaxLabel")
@onready var units_display: Label = find_child("UnitsDisplay")
const MENU: String = "res://src/scenes/main_menu.tscn"

var __timer_max: float = 0.0
var timer_max: float:
	get:
		return __timer_max
	set(value):
		__timer_max = value

var __max_units: int = 0
var max_units: int:
	get:
		return __max_units
	set(value):
		__max_units = value

# Core relationship: time is master, units derive from time
var current_units: float:
	get: 
		return (time_remaining / timer_max) * max_units

var time_remaining: float:
	get: 
		return timer.time_left
	set(value):
		var new_value = min(timer_max, value)
		timer.start(new_value)

func _ready():
	timer_max = default_timer_max
	max_units = default_max_units
	timer.timeout.connect(_on_timer_timeout)
	timer.start(timer_max)
	progress_bar.value = pct(timer.time_left, timer_max)
	GlobalSignals.core_time_added.connect(__on_time_added)
	GlobalSignals.core_time_replenished.connect(__on_time_replenished)
	
	if rightmost_style:
		change_corner_radius()
		
	print(GlobalUtilities.get_enum_name(Air.AirColor, air_color))
	var c = Air.getColor(air_color)
	progress_bar.modulate = c

func change_corner_radius():
	var bg_style = progress_bar.get_theme_stylebox("background").duplicate()
	if bg_style is StyleBoxFlat:
		bg_style.corner_radius_bottom_right = 22
		progress_bar.add_theme_stylebox_override("background", bg_style)
	
	var fill_style = progress_bar.get_theme_stylebox("fill").duplicate()
	if fill_style is StyleBoxFlat:
		fill_style.corner_radius_bottom_right = 22
		progress_bar.add_theme_stylebox_override("fill", fill_style)

# Add units (converts to time and adds it)
func add_units(amount: float):
	var time_per_unit = timer_max / max_units
	var time_to_add = amount * time_per_unit
	time_remaining = time_remaining + time_to_add

# Spend units (converts to time and removes it)
func spend_units(amount: float):
	var time_per_unit = timer_max / max_units
	var time_to_remove = amount * time_per_unit
	time_remaining = max(0, time_remaining - time_to_remove)

# Increase max capacity (keeps current units percentage)
func add_max_units(amount: int):
	var current_percentage = time_remaining / timer_max
	max_units += amount
	# Keep the same time, so units automatically adjust via the getter

# Set max capacity (keeps current units percentage)
func set_max_units(new_max: int):
	var current_percentage = time_remaining / timer_max
	max_units = new_max
	# Keep the same time, so units automatically adjust

# Legacy time-based methods (now internally convert through units)
func __on_time_replenished(amount: float):
	# If this was meant to add time directly, keep it
	time_remaining = time_remaining + amount

func __on_time_added(amount: float):
	var total = time_remaining + amount
	timer_max = max(timer_max, total)
	time_remaining = time_remaining + amount

func pct(numerator: float, denominator: float):
	if denominator <= 0.001:
		return 0.0
	else:
		return 100.0 * numerator / denominator	

func start():
	timer.start()

func _process(delta):
	progress_bar.value = pct(timer.time_left, timer_max)
	label.text = render_label(timer.time_left)
	max_label.text = render_label(timer_max)
	units_display.text = str(render_units_display_string(get_whole_remaining_units()))

func render_units_display_string(units: int):
	if units == 0:
		return ""
	elif units > 0 and units <= 10:	
		return str(units)
	else:
		return ">10"

func render_label(time_left: float):
	var minute: int = time_left / 60	
	var second: int = fmod(time_left, 60)
	var centisecond: int = int(fmod(time_left, 1.0) * 100)
	return str(minute) + ":" + "%02d" % second + "." + "%02d" % centisecond

func get_whole_remaining_units():
	return int(floor(current_units))

func _on_timer_timeout():
	GlobalGameManager.end_game()
