extends Control

class_name MultiplierMeter


var multiplier: float = 1.0
var multiplier_growth_rate: float = 0.5  # Per second
var max_multiplier: float = 4.0
var min_multiplier: float = 1.0 

func _ready():
	# Start the glow animation
	pulse_glow()

func _process(delta):
	if all_meters_below_100():
		# Multiplier grows while you're safe
		multiplier = min(multiplier + (multiplier_growth_rate * delta), max_multiplier)
	else:
		# Instant reset if any meter hits 100%
		multiplier = min_multiplier
		
	if floor(multiplier) == floor(max_multiplier):		
		# %UnitsDisplay.text = " +++ "  briefly
		GlobalSignals.signal_ui_time_bump()
		multiplier = min_multiplier
		show_bonus_text()
	
	# Update visual displays - always update these regardless of timer state
	%ProgressBar.value = pct(multiplier - min_multiplier, max_multiplier - min_multiplier)
	
# Alternative simpler version without effects
func show_bonus_text():
	var original_text = %UnitsDisplay.text
	%UnitsDisplay.text = " +++ "
	
	# Use a timer to restore after delay
	await get_tree().create_timer(0.5).timeout
	
	%UnitsDisplay.text = original_text

func pct(numerator: float, denominator: float):
	if denominator <= 0.001:
		return 0.0
	else:
		return 100.0 * numerator / denominator	

func all_meters_below_100():
	for key in UiController.meters.keys():
		if UiController.meters[key].time_until_full <= 0.005:
			return false
	return true



func pulse_glow():
	var tween = create_tween()  # Now this works!
	tween.set_loops()
	tween.tween_property(%ProgressBar, "modulate", Color(1.5, 1.5, 1.5, 1.0), 0.5)
	tween.tween_property(%ProgressBar, "modulate", Color.WHITE, 0.5)
