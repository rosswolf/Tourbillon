extends UiEntity
class_name UiGremlinNew

## UI representation of a Gremlin as a progress bar with background image
## Shows time-based fill progress instead of HP

@onready var name_label: Label = %NameLabel
@onready var fill_rect: ColorRect = %FillRect
@onready var background_image: TextureRect = %BackgroundImage
@onready var clip_container: Control = %ClipContainer

var gremlin: Gremlin
var gremlin_images: Array[String] = []
var fill_progress: float = 0.0
var fill_speed: float = 0.1  # Fill rate per second

func _ready() -> void:
	super._ready()
	# Load all gremlin images
	_load_gremlin_images()
	# Set a random background image
	_set_random_background()
	# Set initial fill
	if fill_rect:
		fill_rect.color = Color(1.0, 1.0, 1.0, 0.3)  # Semi-transparent white
		fill_rect.anchor_right = 0.0
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
		return
	
	# Pick a random image
	var random_image = gremlin_images[randi() % gremlin_images.size()]
	
	if background_image:
		var texture = load(random_image) as Texture2D
		if texture:
			background_image.texture = texture
			# Set stretch mode to keep aspect ratio and cover
			background_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			# Position at 3/4 from top (which means 1/4 from bottom in anchor terms)
			background_image.anchor_top = 0.0
			background_image.anchor_bottom = 1.0
			background_image.anchor_left = 0.0
			background_image.anchor_right = 1.0
			
			# Adjust position to show top 3/4 of image
			var image_height = texture.get_height()
			var container_height = size.y
			if container_height > 0:
				# Calculate offset to show from top 3/4
				var visible_portion = 0.75
				background_image.position.y = -(image_height * (1.0 - visible_portion))

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

func _process(delta: float) -> void:
	if not gremlin or gremlin.current_hp <= 0:
		return
	
	# Increase fill progress over time
	fill_progress += fill_speed * delta
	fill_progress = clamp(fill_progress, 0.0, 1.0)
	
	# Update fill rect
	if fill_rect:
		fill_rect.anchor_right = fill_progress
		fill_rect.size.x = size.x * fill_progress

func __on_hp_changed(new_hp: int, max_hp: int) -> void:
	if new_hp <= 0:
		__on_defeated()
	else:
		# Flash when damaged
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color(1.5, 0.8, 0.8), 0.1)
		tween.tween_property(self, "modulate", Color.WHITE, 0.2)

func __on_defeated() -> void:
	# Stop filling
	fill_speed = 0.0
	
	# Animate defeat
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.2)
	tween.tween_property(self, "modulate", Color(0.5, 0.5, 0.5, 0.3), 0.5)
	tween.chain().tween_callback(queue_free)