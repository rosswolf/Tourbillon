extends UiEntity
class_name UiGremlinNew

## UI representation of a Gremlin as a progress bar with background image
## Shows time-based fill progress instead of HP

@onready var name_label: Label = %NameLabel
@onready var hp_label: Label = %HpLabel
@onready var fill_rect: ColorRect = %FillRect
@onready var background_image: TextureRect = %BackgroundImage
@onready var clip_container: Control = %ClipContainer
@onready var effect_label: Label = %EffectLabel

var gremlin: Gremlin
var gremlin_images: Array[String] = []
var total_beats: int = 0  # Track beats for fill progress

func _ready() -> void:
	super._ready()
	# Load all gremlin images
	_load_gremlin_images()
	# Set a random background image - defer to ensure size is set
	call_deferred("_set_random_background")
	# Set initial fill
	if fill_rect:
		fill_rect.color = Color(1.0, 1.0, 1.0, 0.3)  # Semi-transparent white
		fill_rect.anchor_right = 0.0
		fill_rect.size.x = 0
	
	# Connect to beat signal for fill updates
	if GlobalSignals.has_signal("core_time_changed"):
		GlobalSignals.core_time_changed.connect(_on_beat_changed)

func _load_gremlin_images() -> void:
	var dir = DirAccess.open("res://ai_assets/gremlins/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".png") or file_name.ends_with(".jpg"):
				if not file_name.ends_with(".import"):
					gremlin_images.append("res://ai_assets/gremlins/" + file_name)
			file_name = dir.get_next()

func _set_random_background() -> void:
	if gremlin_images.is_empty():
		print("[UiGremlinNew] No gremlin images found")
		return
	
	# Pick a random image
	var random_image = gremlin_images[randi() % gremlin_images.size()]
	print("[UiGremlinNew] Loading background: ", random_image)
	
	if background_image:
		var texture = load(random_image) as Texture2D
		if texture:
			background_image.texture = texture
			# Set stretch mode to keep aspect ratio and cover
			background_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			background_image.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			
			# Make sure it's visible
			background_image.visible = true
			background_image.modulate = Color(0.7, 0.7, 0.7, 1.0)  # Slightly darken for text readability

func set_entity_data(entity: Entity) -> void:
	await super.set_entity_data(entity)
	gremlin = __entity as Gremlin
	if not gremlin:
		push_error("Entity is not a Gremlin!")
		return

	# Connect to gremlin's signals
	gremlin.hp_changed.connect(__on_hp_changed)
	gremlin.defeated.connect(__on_defeated)

	# Set initial display
	__update_display()

func __update_display() -> void:
	if not gremlin:
		return

	# Update name
	if name_label:
		name_label.text = gremlin.gremlin_name
	
	# Update HP display
	if hp_label:
		hp_label.text = "%d/%d" % [gremlin.current_hp, gremlin.max_hp]
	
	# Update effect display
	if effect_label:
		effect_label.text = _get_disruption_text()

func _get_disruption_text() -> String:
	if not gremlin:
		return ""
	
	# Get the downside description
	var downside_text = gremlin.get_disruption_text() if gremlin.has_method("get_disruption_text") else ""
	
	# Add timing info if there's a periodic disruption
	if gremlin.has_method("get_disruption_interval_beats") and gremlin.disruption_interval_beats > 0:
		if gremlin.beats_until_disruption > 0:
			var ticks_remaining = gremlin.beats_until_disruption / 10
			var beats_remaining = gremlin.beats_until_disruption % 10
			downside_text += " (in %d.%d)" % [ticks_remaining, beats_remaining]
		else:
			downside_text += " (NOW!)"
	
	return downside_text

func _on_beat_changed(beats: int) -> void:
	if not gremlin or gremlin.current_hp <= 0:
		return
	
	total_beats = beats
	
	# Update fill based on beats (fills over 100 beats = 10 ticks)
	var fill_progress = float(total_beats % 100) / 100.0
	
	# Update fill rect
	if fill_rect:
		fill_rect.anchor_right = fill_progress
		fill_rect.size.x = size.x * fill_progress
	
	# Update effect text
	if effect_label:
		effect_label.text = _get_disruption_text()

func _process(_delta: float) -> void:
	# Update effect display continuously
	if effect_label and gremlin:
		effect_label.text = _get_disruption_text()

func __on_hp_changed(new_hp: int, max_hp: int) -> void:
	# Update HP display
	if hp_label:
		hp_label.text = "%d/%d" % [new_hp, max_hp]
	
	if new_hp <= 0:
		__on_defeated()
	else:
		# Flash when damaged
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color(1.5, 0.8, 0.8), 0.1)
		tween.tween_property(self, "modulate", Color.WHITE, 0.2)

func __on_defeated() -> void:
	# Animate defeat
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.2)
	tween.tween_property(self, "modulate", Color(0.5, 0.5, 0.5, 0.3), 0.5)
	tween.chain().tween_callback(queue_free)
