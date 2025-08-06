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

# Timer that handles automatic filling
@onready var fill_timer: Timer = Timer.new()
# Timer that fires when we're full
@onready var expire_timer: Timer = Timer.new()

var meter_has_expired: bool = false

var __timer_max: float = 1.0
var timer_max: float:
	get:
		return max(1.0, __timer_max)
	set(value):
		__timer_max = max(1.0, value)
		__recalculate_timers()

var __max_energy: float = 1.0
var max_energy: float:
	get:
		return max(1.0, __max_energy)
	set(value):
		__max_energy = max(1.0, value)
		__recalculate_timers()

# PRIMARY STATE: Current units is the source of truth
var __current_units: float = 0.0
var current_units: float:
	get:
		return __current_units
	set(value):
		__current_units = clamp(value, 0.0, max_energy)
		__recalculate_timers()

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
		# Simply calculate from current position
		return timer_max - current_time

func _ready():
	timer_max = default_timer_max
	max_energy = default_max_energy
	
	# Setup fill timer - this ticks regularly to add units
	add_child(fill_timer)
	fill_timer.wait_time = 0.1  # Update every 100ms
	fill_timer.timeout.connect(__on_fill_tick)
	
	# Setup expire timer - this fires once when we're full
	add_child(expire_timer)
	expire_timer.one_shot = true
	expire_timer.timeout.connect(__on_expire)
	
	# Start with specified starting amount
	current_units = starting_energy
	
	# Start the fill timer
	fill_timer.start()
	
	progress_bar.value = pct(current_time, timer_max)
	
	# Connect signals
	GlobalSignals.core_time_filled.connect(__on_time_filled)
	GlobalSignals.core_time_set.connect(__on_time_set)
	GlobalSignals.core_time_removed.connect(__on_time_removed)
		
	GlobalSignals.core_max_time_set.connect(__on_max_time_set)
	GlobalSignals.core_max_time_added.connect(__on_max_time_added)	
	GlobalSignals.core_max_time_removed.connect(__on_max_time_removed)	
		
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

func __on_fill_tick():
	# Add units based on fill rate
	if __current_units < max_energy:
		var units_per_tick = (fill_timer.wait_time / timer_max) * max_energy
		__current_units = min(__current_units + units_per_tick, max_energy)
		# Don't call setter to avoid recursion, just update timers
		__recalculate_timers()

func __on_expire():
	if not meter_has_expired:
		meter_has_expired = true
		__current_units = max_energy
		GlobalSignals.signal_ui_meter_expired(air_color)

func __recalculate_timers():
	# Check if we're full
	if __current_units >= max_energy - 0.001:
		__current_units = max_energy
		expire_timer.stop()
		if not meter_has_expired:
			meter_has_expired = true
			GlobalSignals.signal_ui_meter_expired(air_color)
	else:
		# Calculate time until full and set expire timer
		meter_has_expired = false
		var remaining = time_until_full
		expire_timer.stop()
		if remaining > 0:
			expire_timer.wait_time = remaining
			expire_timer.start()

# Time-based operations (convert to units)
func __on_time_filled(target_color: Air.AirColor, amount: float):
	if target_color == air_color:
		var units_to_add = (amount / timer_max) * max_energy
		current_units += units_to_add

func __on_time_removed(target_color: Air.AirColor, amount: float):
	if target_color == air_color:
		var units_to_remove = (amount / timer_max) * max_energy
		current_units -= units_to_remove
	
func __on_time_set(target_color: Air.AirColor, amount: float):
	if target_color == air_color:
		var units_to_set = (amount / timer_max) * max_energy
		current_units = units_to_set

func __on_max_time_added(target_color: Air.AirColor, amount: float):
	if target_color == air_color:
		add_max_time(amount)

func __on_max_time_removed(target_color: Air.AirColor, amount: float):
	if target_color == air_color:
		remove_max_time(amount)

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
		GlobalSignals.signal_stats_energy_spent(floor(amount))

func __on_energy_set(target_color: Air.AirColor, amount: float):
	if target_color == air_color:
		if current_units > amount:
			GlobalSignals.signal_stats_energy_spent(floor(current_units - amount))
		current_units = amount

func __on_max_energy_added(target_color: Air.AirColor, amount: float):
	if target_color == air_color:
		add_max_energy(amount)

func __on_max_energy_set(target_color: Air.AirColor, amount: float):
	if target_color == air_color:
		set_max_energy(amount)

func add_max_energy(amount: float):
	var saved_units = current_units
	max_energy += amount
	current_units = saved_units

func set_max_energy(new_max: float):
	var saved_units = current_units
	max_energy = new_max
	current_units = saved_units

func add_max_time(amount: float):
	var saved_units = current_units
	timer_max += amount
	current_units = saved_units

func remove_max_time(amount: float):
	var time_remaining = time_until_full
	timer_max -= amount
	
	if time_remaining > timer_max:
		current_units = 0
	else:
		var new_time_position = timer_max - time_remaining
		current_units = (new_time_position / timer_max) * max_energy
	
	flash_bar()

func flash_bar():
	var tween = create_tween()
	var original_color = progress_bar.modulate
	tween.tween_property(progress_bar, "modulate", Color.WHITE, 0.1)
	tween.tween_property(progress_bar, "modulate", original_color, 0.2)

func set_max_time(new_max: float):
	var time_remaining = time_until_full
	timer_max = new_max
	
	if time_remaining > timer_max:
		current_units = 0
	else:
		var new_time_position = timer_max - time_remaining
		current_units = (new_time_position / timer_max) * max_energy

func pct(numerator: float, denominator: float):
	if denominator <= 0.001:
		return 0.0
	else:
		return 100.0 * numerator / denominator	

func start():
	current_units = starting_energy
	fill_timer.start()

func _process(delta):
	# ONLY handle visual updates - no state changes!
	progress_bar.value = pct(current_time, timer_max)
	label.text = render_label(time_until_full)
	max_label.text = render_label(timer_max)
	units_display.text = str(render_units_display_string(get_whole_remaining_units()))

func render_units_display_string(units: int):
	if units == 0:
		return ""
	elif units > 0 and units <= 10:	
		return str(units)
	else:
		return ">10"

func render_label_dec(minute: int, second: int, centisecond):
	return str(minute) + ":" + "%02d" % second + "." + "%02d" % centisecond

func render_label_hex(minute: int, second: int, centisecond):
	return str(minute) + ":" + "%02X" % second + "." + "%02X" % centisecond

func render_label(time_left: float):
	var minute: int = time_left / 60	
	var second: int = fmod(time_left, 60)
	var centisecond: int = int(fmod(time_left, 1.0) * 100)
	return render_label_hex(minute, second, centisecond)

func get_whole_remaining_units():
	return int(floor(current_energy))
