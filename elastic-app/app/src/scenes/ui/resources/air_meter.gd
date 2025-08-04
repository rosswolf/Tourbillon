extends Control

class_name AirMeter

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
		
var time_remaining: float:
	get: 
		return timer.time_left
	set(value):
		var new_value = min(timer_max, value)
		timer.start(new_value)

var __max_energy: float = 1.0
var max_energy: float:
	get:
		return max(1.0, __max_energy)
	set(value):
		__max_energy = max(1.0, value)

# Core relationship: time is primary, units derive from time
var current_energy: float:
	get: 
		return (time_remaining / timer_max) * max_energy


func _ready():
	timer_max = default_timer_max
	max_energy = default_max_energy
	timer.timeout.connect(_on_timer_timeout)
	timer.start(timer_max)
	progress_bar.value = pct(timer.time_left, timer_max)
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
		time_remaining = time_remaining + amount
	
func __on_time_set(target_color: Air.AirColor, amount: float):
	if target_color == air_color:
		time_remaining = amount


func __on_max_time_added(target_color: Air.AirColor, amount: float):
	if target_color == air_color:
		add_max_time(amount)

func __on_max_time_set(target_color: Air.AirColor, amount: float):
	if target_color == air_color:
		set_max_time(amount)

# Add units (converts to time and adds it)
func add_energy_capped(amount: float):
	var time_per_unit: float = timer_max / max_energy
	var time_to_add: float = amount * time_per_unit
	time_remaining = time_remaining + time_to_add
	
# Spend units (converts to time and removes it)
func set_energy_capped(amount: float):
	var time_per_unit: float = timer_max / max_energy
	var new_time: float = amount * time_per_unit
	time_remaining = max(0, new_time)

func add_max_energy(amount: float):
	var current_time_proportion: float = time_remaining / timer_max
	max_energy += amount
	# Keep the same time proportion, energy will adjust automatically
	time_remaining = current_time_proportion * timer_max

func set_max_energy(new_max: float):
	var current_time_proportion: float = time_remaining / timer_max
	max_energy = new_max
	# Keep the same time proportion, energy will adjust automatically  
	time_remaining = current_time_proportion * timer_max

func add_max_time(amount: float):
	var current_time_proportion: float = time_remaining / timer_max
	timer_max = timer_max + amount
	time_remaining = current_time_proportion * timer_max

func set_max_time(amount: float):
	var current_time_proportion: float = time_remaining / timer_max
	timer_max = amount
	time_remaining = current_time_proportion * timer_max

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
	return int(floor(current_energy))

func _on_timer_timeout():
	GlobalGameManager.end_game()
