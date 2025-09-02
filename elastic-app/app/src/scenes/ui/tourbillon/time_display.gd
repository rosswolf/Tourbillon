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
	GlobalSignals.ui_tick_advanced.connect(_on_tick_advanced)
	
	# Initialize display
	__update_display()

func _process(_delta: float) -> void:
	# Update beat progress from TourbillonGameManager
	if GlobalGameManager.has("tourbillon_manager"):
		var manager = GlobalGameManager.get("tourbillon_manager")
		var beat = manager.get_current_beat()
		if beat != current_beat:
			current_beat = beat
			__update_display()
			__animate_beat_change()

func _on_tick_advanced(tick: int) -> void:
	current_tick = tick
	__update_display()
	__animate_tick_change()

func __update_display() -> void:
	if tick_label:
		tick_label.text = "Tick: %d" % current_tick
	
	if beat_label:
		var beat_in_tick = current_beat % beats_per_tick
		beat_label.text = "Beat: %d/%d" % [beat_in_tick, beats_per_tick]
	
	if beat_progress:
		var progress = float(current_beat % beats_per_tick) / float(beats_per_tick)
		beat_progress.value = progress * 100.0

func __animate_tick_change() -> void:
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

func __animate_beat_change() -> void:
	# Subtle animation for beat changes
	if beat_progress:
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_LINEAR)
		
		# Smooth progress bar update
		var progress = float(current_beat % beats_per_tick) / float(beats_per_tick)
		tween.tween_property(beat_progress, "value", progress * 100.0, 0.1)