extends Control
class_name TimeDisplay

## Displays the current tick and beat count
## Provides visual feedback for time advancement

@onready var tick_label: Label = $VBoxContainer/TickLabel
@onready var beat_label: Label = $VBoxContainer/BeatLabel
@onready var beat_progress: ProgressBar = $VBoxContainer/BeatProgress

var current_tick: int = 0
var current_beat: int = 0
var beats_per_tick: int = 10

func _ready() -> void:
	# Connect to time signals
	GlobalSignals.ui_time_updated.connect(_on_time_updated)
	
	# Initialize display
	_update_display()

func _on_time_updated(tick_display: String) -> void:
	print("TimeDisplay received update: ", tick_display)
	# Parse the tick.beat format from GlobalGameManager
	var parts: Array[String] = tick_display.split(".")
	if parts.size() == 2:
		var new_tick: int = int(parts[0])
		var beat_in_tick: int = int(parts[1])
		var new_beat: int = new_tick * 10 + beat_in_tick
		
		print("  Parsed: Tick=", new_tick, " Beat in tick=", beat_in_tick, " Total beats=", new_beat)
		
		# Check if tick changed
		if new_tick != current_tick:
			current_tick = new_tick
			_animate_tick_change()
		
		# Check if beat changed  
		if new_beat != current_beat:
			current_beat = new_beat
			_animate_beat_change()
		
		_update_display()


func _update_display() -> void:
	if tick_label:
		tick_label.text = "Tick: %d" % current_tick
	
	if beat_label:
		var beat_in_tick: int = current_beat % beats_per_tick
		beat_label.text = "Beat: %d/%d" % [beat_in_tick, beats_per_tick]
	
	if beat_progress:
		var progress: float = float(current_beat % beats_per_tick) / float(beats_per_tick)
		beat_progress.value = progress * 100.0

func _animate_tick_change() -> void:
	# Visual feedback for tick change
	if tick_label:
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_ELASTIC)
		tween.set_ease(Tween.EASE_OUT)
		
		# Scale up and back
		tween.tween_property(tick_label, "scale", Vector2(1.2, 1.2), 0.1)
		tween.tween_property(tick_label, "scale", Vector2(1.0, 1.0), 0.2)
		
		# Flash color
		tween.parallel().tween_property(tick_label, "modulate", Color.YELLOW, 0.1)
		tween.tween_property(tick_label, "modulate", Color.WHITE, 0.2)

func _animate_beat_change() -> void:
	# Subtle animation for beat changes
	if beat_progress:
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_LINEAR)
		
		# Smooth progress bar update
		var progress = float(current_beat % beats_per_tick) / float(beats_per_tick)
		tween.tween_property(beat_progress, "value", progress * 100.0, 0.1)