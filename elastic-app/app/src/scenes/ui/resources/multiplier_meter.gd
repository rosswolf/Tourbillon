extends Control

class_name MultiplierMeter

var multiplier: float = 2.0
var multiplier_growth_rate: float = 0.1  # Per second
var max_multiplier: float = 3.0
var min_multiplier: float = 1.0 

func _ready():
	# Start the glow animation
	pulse_glow()
	UiController.multiplier_meter = self

func _process(delta):
	if all_meters_below_100():
		# Multiplier grows while you're safe
		multiplier = min(multiplier + (multiplier_growth_rate * delta), max_multiplier)
	else:
		# Instant reset if any meter hits 100%
		multiplier = min_multiplier
	
	# Update visual displays - always update these regardless of timer state
	%ProgressBar.value = pct(multiplier - min_multiplier, max_multiplier - min_multiplier)
	%UnitsDisplay.text = str(floor(multiplier))+"x"

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
