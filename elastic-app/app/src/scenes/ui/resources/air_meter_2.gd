extends Control

class_name AirMeter2

@export var rightmost_style: bool = false
@export var air_color: Air.AirColor = Air.AirColor.UNKNOWN
@export var default_timer_max: float = 20.0
@export var default_max_energy: float = 7.0
@export var starting_energy: float = 0.0  # Starting amount of units

@onready var timer: Timer = find_child("Timer")
@onready var progress_bar: ProgressBar = find_child("ProgressBar")  
@onready var label: Label = find_child("Label")
@onready var max_label: Label = find_child("MaxLabel")
@onready var units_display: Label = find_child("UnitsDisplay")
const MENU: String = "res://src/scenes/main_menu.tscn"

# Single timer that tracks remaining time until full
@onready var fill_timer: Timer = Timer.new()

var __timer_max: float = 1.0
var timer_max: float:
	get:
		return max(1.0, __timer_max)
	set(value):
		__timer_max = max(1.0, value)
		# When max time changes, maintain current units and update timer
		current_units = __current_units  # Trigger setter to recalculate

var __max_energy: float = 1.0
var max_energy: float:
	get:
		return max(1.0, __max_energy)
	set(value):
		__max_energy = max(1.0, value)
		# When max energy changes, maintain current units and update timer
		current_units = __current_units  # Trigger setter to recalculate

# PRIMARY STATE: Everything is based on units
var __current_units: float = 0.0
var __base_units: float = 0.0  # Units at the time we started the timer
var current_units: float:
	get:
		return __current_units
	set(value):
		__current_units = clamp(value, 0.0, max_energy)
		# Update the timer whenever units change
		__update_timer_from_units()

# Derived values from units
var current_time: float:
	get:
		return (current_units / max_energy) * timer_max

var current_energy: float:
	get:
		return current_units

# Get the actual time remaining until the meter is full
var time_until_full: float:
	get:
		if fill_timer.is_stopped():
			return timer_max - current_time
		else:
			return fill_timer.time_left


func _ready():
	timer_max = default_timer_max
	max_energy = default_max_energy
	
	# Start with specified starting amount
	current_units = starting_energy
	
	# Setup fill timer - this is a one-shot timer that counts down to game end
	add_child(fill_timer)
	fill_timer.one_shot = true
	fill_timer.timeout.connect(__on_fill_timer_timeout)
	
	# Ensure timer is started
	__update_timer_from_units()
	
	progress_bar.value = pct(current_time, timer_max)
	
	# Connect signals with renamed "fill" instead of "replenished"
	GlobalSignals.core_time_filled.connect(__on_time_filled)
	GlobalSignals.core_time_set.connect(__on_time_set)
	GlobalSignals.core_time_removed.connect(__on_time_removed)
		
	GlobalSignals.core_max_time_set.connect(__on_max_time_set)
	GlobalSignals.core_max_time_added.connect(__on_max_time_added)	
		
	GlobalSignals.core_energy_set.connect(__on_energy_set)
	GlobalSignals.core_energy_filled.connect(__on_energy_filled)
	GlobalSignals.core_energy_removed.connect(__on_energy_removed)
		
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

func __on_fill_timer_timeout():
	# Timer has expired, meter is full
	__current_units = max_energy  # Set directly to avoid retriggering timer
	GlobalGameManager.end_game()

func __update_timer_from_units():
	# Calculate time position from current units
	var time_position = (current_units / max_energy) * timer_max
	var remaining_time = timer_max - time_position
	
	print("UPDATE TIMER: units=", current_units, " time_pos=", time_position, " remaining=", remaining_time)
	
	if remaining_time <= 0.001:  # Use small epsilon to avoid float precision issues
		# Already at max, stop timer and trigger game end
		fill_timer.stop()
		__current_units = max_energy  # Ensure we're exactly at max
		GlobalGameManager.end_game()
	else:
		# Start/restart timer with the remaining time
		fill_timer.stop()
		fill_timer.wait_time = remaining_time
		fill_timer.start()
		# Store the base units when we start the timer
		__base_units = __current_units
		print("Timer started with ", remaining_time, " seconds")

# Time-based operations (convert to units)
func __on_time_filled(target_color: Air.AirColor, amount: float):
	if target_color == air_color:
		# Convert time to units proportionally
		var units_to_add = (amount / timer_max) * max_energy
		current_units += units_to_add

func __on_time_removed(target_color: Air.AirColor, amount: float):
	if target_color == air_color:
		# Convert time to units proportionally
		var units_to_remove = (amount / timer_max) * max_energy
		current_units -= units_to_remove
	
func __on_time_set(target_color: Air.AirColor, amount: float):
	if target_color == air_color:
		# Convert time to units proportionally
		var units_to_set = (amount / timer_max) * max_energy
		current_units = units_to_set

func __on_max_time_added(target_color: Air.AirColor, amount: float):
	if target_color == air_color:
		add_max_time(amount)

func __on_max_time_set(target_color: Air.AirColor, amount: float):
	if target_color == air_color:
		set_max_time(amount)

# Energy/Unit-based operations (direct)
func __on_energy_filled(target_color: Air.AirColor, amount: float):
	if target_color == air_color:
		current_units += amount

func __on_energy_removed(target_color: Air.AirColor, amount: float):
	if target_color == air_color:
		current_units -= amount

func __on_energy_set(target_color: Air.AirColor, amount: float):
	if target_color == air_color:
		current_units = amount

func __on_max_energy_added(target_color: Air.AirColor, amount: float):
	if target_color == air_color:
		add_max_energy(amount)

func __on_max_energy_set(target_color: Air.AirColor, amount: float):
	if target_color == air_color:
		set_max_energy(amount)

func add_max_energy(amount: float):
	# Conservation of units: keep current units
	var saved_units = current_units
	max_energy += amount
	current_units = saved_units  # Restore units, timer will update

func set_max_energy(new_max: float):
	# Conservation of units: keep current units
	var saved_units = current_units
	max_energy = new_max
	current_units = saved_units  # Restore units, timer will update

func add_max_time(amount: float):
	# Conservation of units: keep current units when changing max time
	var saved_units = current_units
	timer_max += amount
	current_units = saved_units  # Restore units, timer will update

func set_max_time(amount: float):
	# Conservation of units: keep current units when changing max time
	var saved_units = current_units
	timer_max = amount
	current_units = saved_units  # Restore units, timer will update

func pct(numerator: float, denominator: float):
	if denominator <= 0.001:
		return 0.0
	else:
		return 100.0 * numerator / denominator	

func start():
	# Reset to starting amount when explicitly started
	current_units = starting_energy

func _process(delta):
	# Update current units based on timer progress
	if not fill_timer.is_stopped():
		var elapsed = fill_timer.wait_time - fill_timer.time_left
		# Calculate how many units we've gained while filling
		var units_gained = (elapsed / timer_max) * max_energy
		__current_units = min(__base_units + units_gained, max_energy)
	
	# Update visual displays - always update these regardless of timer state
	progress_bar.value = pct(current_time, timer_max)
	label.text = render_label(current_time)
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
	return str(minute) + ":" + "%02X" % second + "." + "%02X" % centisecond

func get_whole_remaining_units():
	return int(floor(current_energy))
