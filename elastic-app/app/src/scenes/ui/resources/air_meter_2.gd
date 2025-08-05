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

# Increment timer - fires periodically to increase current time
@onready var increment_timer: Timer = Timer.new()
const INCREMENT_INTERVAL: float = 0.05  # Update every 50ms for smooth filling

var __timer_max: float = 1.0
var timer_max: float:
	get:
		return max(1.0, __timer_max)
	set(value):
		var old_max = __timer_max
		__timer_max = max(1.0, value)
		# When max time changes, reset the increment timer
		_reset_increment_timer()
		
var __current_time: float = 0.0
var current_time: float:
	get: 
		return __current_time
	set(value):
		__current_time = clamp(value, 0.0, timer_max)
		_reset_increment_timer()

var __max_energy: float = 1.0
var max_energy: float:
	get:
		return max(1.0, __max_energy)
	set(value):
		__max_energy = max(1.0, value)
		# When max energy changes, we keep current units (via current time)
		_reset_increment_timer()

# Core relationship: units derive from time
var current_energy: float:
	get: 
		return (current_time / timer_max) * max_energy


func _ready():
	timer_max = default_timer_max
	max_energy = default_max_energy
	
	# Start with specified starting amount (converts units to time)
	var time_per_unit: float = timer_max / max_energy
	current_time = starting_energy * time_per_unit
	
	# Setup increment timer
	add_child(increment_timer)
	increment_timer.wait_time = INCREMENT_INTERVAL
	increment_timer.timeout.connect(_on_increment_timer_timeout)
	increment_timer.start()
	
	progress_bar.value = pct(current_time, timer_max)
	
	# Connect signals with renamed "fill" instead of "replenished"
	GlobalSignals.core_time_replenished.connect(__on_time_filled)
	GlobalSignals.core_time_set.connect(__on_time_set)
	GlobalSignals.core_time_removed.connect(__on_time_removed)
		
	GlobalSignals.core_max_time_set.connect(__on_max_time_set)
	GlobalSignals.core_max_time_added.connect(__on_max_time_added)	
		
	GlobalSignals.core_energy_set.connect(__on_energy_set)
	GlobalSignals.core_energy_replenished.connect(__on_energy_filled)
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

func _on_increment_timer_timeout():
	# Increment the current time
	current_time += INCREMENT_INTERVAL
	
	# Check if we've reached max
	if current_time >= timer_max:
		current_time = timer_max
		increment_timer.stop()
		GlobalGameManager.end_game()

func _reset_increment_timer():
	# Reset the increment timer whenever any value changes
	if current_time < timer_max:
		if not increment_timer.is_stopped():
			increment_timer.stop()
		increment_timer.start()
	else:
		increment_timer.stop()

# Time-based operations
func __on_time_filled(target_color: Air.AirColor, amount: float):
	if target_color == air_color:
		current_time += amount  # Add time (meter goes up)

func __on_time_removed(target_color: Air.AirColor, amount: float):
	if target_color == air_color:
		current_time -= amount  # Remove time (meter goes down)
	
func __on_time_set(target_color: Air.AirColor, amount: float):
	if target_color == air_color:
		current_time = amount

func __on_max_time_added(target_color: Air.AirColor, amount: float):
	if target_color == air_color:
		add_max_time(amount)

func __on_max_time_set(target_color: Air.AirColor, amount: float):
	if target_color == air_color:
		set_max_time(amount)

# Energy/Unit-based operations
func __on_energy_filled(target_color: Air.AirColor, amount: float):
	if target_color == air_color:
		add_energy(amount)  # Add units (meter goes up)

func __on_energy_removed(target_color: Air.AirColor, amount: float):
	if target_color == air_color:
		remove_energy(amount)  # Remove units (meter goes down)

func __on_energy_set(target_color: Air.AirColor, amount: float):
	if target_color == air_color:
		set_energy(amount)

func __on_max_energy_added(target_color: Air.AirColor, amount: float):
	if target_color == air_color:
		add_max_energy(amount)

func __on_max_energy_set(target_color: Air.AirColor, amount: float):
	if target_color == air_color:
		set_max_energy(amount)

# Add units (converts to time and adds it) - meter goes up
func add_energy(amount: float):
	var time_per_unit: float = timer_max / max_energy
	var time_to_add: float = amount * time_per_unit
	current_time += time_to_add

# Remove units (converts to time and removes it) - meter goes down
func remove_energy(amount: float):
	var time_per_unit: float = timer_max / max_energy
	var time_to_remove: float = amount * time_per_unit
	current_time -= time_to_remove

# Set units directly (converts to time and sets it)
func set_energy(amount: float):
	var time_per_unit: float = timer_max / max_energy
	var new_time: float = amount * time_per_unit
	current_time = new_time

func add_max_energy(amount: float):
	# Conservation of units: keep current units, not proportion
	var current_units = current_energy
	max_energy += amount
	# Set the time to maintain the same unit count
	set_energy(current_units)

func set_max_energy(new_max: float):
	# Conservation of units: keep current units, not proportion
	var current_units = current_energy
	max_energy = new_max
	# Set the time to maintain the same unit count
	set_energy(current_units)

func add_max_time(amount: float):
	# Conservation of units: keep current units when changing max time
	var current_units = current_energy
	timer_max = timer_max + amount
	# Restore the same unit count with new time scale
	set_energy(current_units)

func set_max_time(amount: float):
	# Conservation of units: keep current units when changing max time
	var current_units = current_energy
	timer_max = amount
	# Restore the same unit count with new time scale
	set_energy(current_units)

func pct(numerator: float, denominator: float):
	if denominator <= 0.001:
		return 0.0
	else:
		return 100.0 * numerator / denominator	

func start():
	# Reset to starting amount when explicitly started
	var time_per_unit: float = timer_max / max_energy
	current_time = starting_energy * time_per_unit
	increment_timer.start()

func _process(delta):
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
