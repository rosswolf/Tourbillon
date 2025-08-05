extends Control

class_name AirMeter2

@export var rightmost_style: bool = false
@export var air_color: Air.AirColor = Air.AirColor.UNKNOWN
@export var default_timer_max: float = 20.0
@export var default_max_energy: float = 7.0

@onready var timer: Timer = find_child("Timer")
@onready var progress_bar: ProgressBar = find_child("ProgressBar")  
@onready var label: Label = find_child("Label")
@onready var max_label: Label = find_child("MaxLabel")
@onready var units_display: Label = find_child("UnitsDisplay")
const MENU: String = "res://src/scenes/main_menu.tscn"

var __timer_max: float = 1.0
var timer_max: float:
	get:
		return max(1.0, __timer_max)
	set(value):
		__timer_max = max(1.0, value)

# Time elapsed since start (rises from 0 to timer_max)
var time_elapsed: float:
	get:
		return timer_max - timer.time_left
	set(value):
		var clamped_value = clamp(value, 0, timer_max)
		var new_time_left = timer_max - clamped_value
		timer.start(new_time_left)

var __max_energy: float = 1.0
var max_energy: float:
	get:
		return max(1.0, __max_energy)
	set(value):
		__max_energy = max(1.0, value)

# Core relationship: time is primary, units derive from time (now based on elapsed time)
var current_energy: float:
	get: 
		return (time_elapsed / timer_max) * max_energy

# Time remaining until game over
var time_remaining: float:
	get:
		return timer.time_left

func _ready():
	timer_max = default_timer_max
	max_energy = default_max_energy
	
	# Start the timer with full time (it will count down to 0, meaning time_elapsed goes up)
	timer.timeout.connect(_on_timer_timeout)
	timer.start(timer_max)
	
	# Connect to global signals
	GlobalSignals.core_time_replenished.connect(__on_time_replenished)
	GlobalSignals.core_time_set.connect(__on_time_set)
		
	GlobalSignals.core_max_time_set.connect(__on_max_time_set)
	GlobalSignals.core_max_time_added.connect(__on_max_time_added)	
		
	GlobalSignals.core_energy_set.connect(__on_energy_set)
	GlobalSignals.core_energy_replenished.connect(__on_energy_replenished)
		
	GlobalSignals.core_max_energy_added.connect(__on_max_energy_added)
	GlobalSignals.core_max_energy_set.connect(__on_max_energy_set)
	
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

# Signal handlers - replenish adds more energy (pushes meter up)
func __on_energy_replenished(target_color: Air.AirColor, amount: float):
	if target_color == air_color:
		add_energy_capped(amount)

func __on_energy_set(target_color: Air.AirColor, amount: float):
	if target_color == air_color:
		set_energy_capped(amount)

func __on_max_energy_added(target_color: Air.AirColor, amount: float):
	if target_color == air_color:
		add_max_energy(amount)

func __on_max_energy_set(target_color: Air.AirColor, amount: float):
	if target_color == air_color:
		set_max_energy(amount)

func __on_time_replenished(target_color: Air.AirColor, amount: float):
	if target_color == air_color:
		# Reduce time left in timer (increase elapsed time = more energy)
		var new_time_left = max(0, timer.time_left - amount)
		timer.start(new_time_left)
	
func __on_time_set(target_color: Air.AirColor, amount: float):
	if target_color == air_color:
		# Set specific elapsed time
		time_elapsed = amount

func __on_max_time_added(target_color: Air.AirColor, amount: float):
	if target_color == air_color:
		add_max_time(amount)

func __on_max_time_set(target_color: Air.AirColor, amount: float):
	if target_color == air_color:
		set_max_time(amount)

# Add units (converts to time and increases elapsed time - more energy for player to manage)
func add_energy_capped(amount: float):
	var time_per_unit: float = timer_max / max_energy
	var time_to_advance: float = amount * time_per_unit
	var new_time_left = max(0, timer.time_left - time_to_advance)
	timer.start(new_time_left)
	
# Set energy level (converts to elapsed time and restarts timer)
func set_energy_capped(amount: float):
	var time_per_unit: float = timer_max / max_energy
	var target_elapsed_time: float = clamp(amount * time_per_unit, 0, timer_max)
	var target_time_left: float = timer_max - target_elapsed_time
	timer.start(target_time_left)

# Spend energy (reduces elapsed time - moves meter down)
func spend_energy(amount: float):
	var time_per_unit: float = timer_max / max_energy
	var time_to_reduce: float = amount * time_per_unit
	var new_time_left = min(timer_max, timer.time_left + time_to_reduce)
	timer.start(new_time_left)

func add_max_energy(amount: float):
	var current_energy_amount: float = current_energy
	max_energy += amount
	# Keep the same energy amount (feels good when capacity increases)
	set_energy_capped(current_energy_amount)

func set_max_energy(new_max: float):
	var current_energy_amount: float = current_energy
	max_energy = new_max
	# Keep the same energy amount
	set_energy_capped(current_energy_amount)

func add_max_time(amount: float):
	var current_energy_amount: float = current_energy
	timer_max = timer_max + amount
	# Keep the same energy amount (feels good when capacity increases)
	set_energy_capped(current_energy_amount)

func remove_max_time(amount: float):
	var current_energy_amount: float = current_energy
	timer_max = max(1.0, timer_max - amount)  # Don't let it go below 1
	# Keep the same energy amount (makes capacity decreases feel bad, as intended)
	set_energy_capped(current_energy_amount)

func set_max_time(amount: float):
	var current_energy_amount: float = current_energy
	timer_max = amount
	# Keep the same energy amount
	set_energy_capped(current_energy_amount)

func pct(numerator: float, denominator: float):
	if denominator <= 0.001:
		return 0.0
	else:
		return 100.0 * numerator / denominator	

func start():
	timer.start(timer_max)

func _process(delta):
	# Display based on elapsed time (how full the meter is)
	progress_bar.value = pct(time_elapsed, timer_max)
	label.text = render_label(time_elapsed)
	max_label.text = render_label(timer_max)
	units_display.text = str(render_units_display_string(get_whole_remaining_units()))

func render_units_display_string(units: int):
	if units == 0:
		return ""
	elif units > 0 and units <= 10:	
		return str(units)
	else:
		return ">10"

func render_label(time_value: float):
	var minute: int = time_value / 60	
	var second: int = fmod(time_value, 60)
	var centisecond: int = int(fmod(time_value, 1.0) * 100)
	return str(minute) + ":" + "%02X" % second + "." + "%02X" % centisecond

func get_whole_remaining_units():
	return int(floor(current_energy))

# Game over when timer reaches 0 (meter is full)
func _on_timer_timeout():
	GlobalGameManager.end_game()
