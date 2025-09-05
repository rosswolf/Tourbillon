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

func _ready() -> void:
	super._ready()
	# Load all gremlin images
	_load_gremlin_images()
	# Set a random background image - defer to ensure size is set
	call_deferred("_set_random_background")
	# Set initial fill
	if fill_rect:
		fill_rect.color = Color(1.0, 1.0, 1.0, 0.3)  # Semi-transparent white
		fill_rect.visible = true
		# Ensure fill rect is on top of background but below text
		fill_rect.z_index = 1
		# Start with no fill
		fill_rect.size.x = 0
	

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
	
	# Get the current move description
	var move_text = gremlin.get_disruption_text() if gremlin.has_method("get_disruption_text") else ""
	
	# Add timing info for the current move
	if gremlin.current_move and gremlin.current_move.tick_duration > 0:
		# Convert beats back to ticks for display
		var ticks_left = ceili(gremlin.beats_until_move_complete / 10.0)
		var total_ticks = gremlin.current_move.tick_duration
		if ticks_left > 0:
			move_text += " [%d/%d]" % [total_ticks - ticks_left, total_ticks]
		else:
			move_text += " [NOW!]"
	elif gremlin.current_move and gremlin.current_move.is_background:
		move_text += " [Active]"
	
	return move_text


func _process(_delta: float) -> void:
	if not gremlin or gremlin.current_hp <= 0:
		return
	
	# Update effect display
	if effect_label:
		effect_label.text = _get_disruption_text()
	
	# Update progress bar based on current move
	if fill_rect and gremlin.current_move:
		var fill_progress: float = 0.0
		
		if gremlin.current_move.tick_duration > 0:
			# Calculate smooth progress using beats
			var total_beats = gremlin.current_move.tick_duration * 10
			var beats_elapsed = total_beats - gremlin.beats_until_move_complete
			fill_progress = float(beats_elapsed) / float(total_beats)
		else:
			# Background effect - always show as full
			fill_progress = 1.0
		
		# Update fill width
		var panel_width = self.size.x
		fill_rect.size.x = panel_width * fill_progress

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
