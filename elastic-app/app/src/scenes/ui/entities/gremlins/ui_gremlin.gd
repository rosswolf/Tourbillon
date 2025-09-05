extends UiEntity
class_name UiGremlin

## UI representation of a Gremlin enemy
## Displays HP, shields, and disruption information

@onready var hp_label: Label = %HpLabel
@onready var name_label: Label = %NameLabel
@onready var disruption_label: Label = %DisruptionLabel
@onready var hp_bar: ProgressBar = %HpBar
@onready var shield_label: Label = %ShieldLabel
@onready var background_panel: TextureRect = %BackgroundPanel
@onready var move_progress_bar: ProgressBar = $MoveProgressBar  # Optional - may not exist in scene

var gremlin: Gremlin

func _ready() -> void:
	super._ready()
	# Connect to gremlin damage and defeat signals
	GlobalSignals.core_mob_health_changed.connect(__on_mob_health_changed)
	# Additional visual setup
	if background_panel:
		# We'll apply a cropped background texture here
		pass

func set_entity_data(entity: Entity) -> void:
	await super.set_entity_data(entity)
	gremlin = __entity as Gremlin
	if not gremlin:
		push_error("Entity is not a Gremlin!")
		return

	# Connect to gremlin's signals
	gremlin.hp_changed.connect(__on_hp_changed)
	gremlin.defeated.connect(__on_defeated)
	gremlin.disruption_triggered.connect(__on_disruption_triggered)

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

	if hp_bar:
		hp_bar.max_value = gremlin.max_hp
		hp_bar.value = gremlin.current_hp

		# Color code based on HP percentage
		var hp_percent = float(gremlin.current_hp) / float(gremlin.max_hp)
		if hp_percent > 0.5:
			hp_bar.modulate = Color.GREEN
		elif hp_percent > 0.25:
			hp_bar.modulate = Color.YELLOW
		else:
			hp_bar.modulate = Color.RED

	# Update shields
	if shield_label:
		if gremlin.shields > 0:
			shield_label.text = "🛡 %d" % gremlin.shields
			shield_label.visible = true
		else:
			shield_label.visible = false

	# Update disruption info
	if disruption_label:
		# Show the gremlin's disruption effect
		disruption_label.text = __get_disruption_text()

func __get_disruption_text() -> String:
	# Get the current move description from the gremlin
	var move_text = gremlin.get_disruption_text()
	
	# Add timing info for the current move
	if gremlin.current_move and gremlin.current_move.tick_duration > 0:
		if gremlin.ticks_until_move_complete > 0:
			move_text += " [%d/%d]" % [gremlin.current_move.tick_duration - gremlin.ticks_until_move_complete, 
										gremlin.current_move.tick_duration]
		else:
			move_text += " [NOW!]"
	elif gremlin.current_move and gremlin.current_move.is_background:
		move_text += " [Active]"
	
	return move_text

func __on_hp_changed(new_hp: int, max_hp: int) -> void:
	__update_display()

	# Flash red when damaged
	if new_hp < gremlin.current_hp:
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color(1.5, 0.8, 0.8), 0.1)
		tween.tween_property(self, "modulate", Color.WHITE, 0.2)

func __on_defeated() -> void:
	# Animate defeat
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.2)
	tween.tween_property(self, "modulate", Color(1.0, 0.0, 0.0, 0.0), 0.5)
	tween.chain().tween_callback(queue_free)

func __on_disruption_triggered(gremlin: Gremlin) -> void:
	if gremlin == self.gremlin:
		# Flash purple for disruption
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color(1.5, 0.8, 1.5), 0.2)
		tween.tween_property(self, "modulate", Color.WHITE, 0.3)

		# Update display to show disruption effect
		__update_display()

func __on_mob_health_changed(mob_id: String, new_health: int) -> void:
	if gremlin and gremlin.instance_id == mob_id:
		gremlin.current_hp = new_health
		__update_display()

func _process(_delta: float) -> void:
	# Update disruption countdown continuously
	if disruption_label and gremlin:
		disruption_label.text = __get_disruption_text()
	
	# Update move progress bar if it exists
	if move_progress_bar and gremlin and gremlin.current_move:
		if gremlin.current_move.tick_duration > 0:
			move_progress_bar.visible = true
			move_progress_bar.max_value = gremlin.current_move.tick_duration
			move_progress_bar.value = gremlin.current_move.tick_duration - gremlin.ticks_until_move_complete
			
			# Color based on move type
			if gremlin.current_move.effect_type == "attack":
				move_progress_bar.modulate = Color.RED
			elif "drain" in gremlin.current_move.effect_type:
				move_progress_bar.modulate = Color.PURPLE
			elif "cap" in gremlin.current_move.effect_type:
				move_progress_bar.modulate = Color.ORANGE
			else:
				move_progress_bar.modulate = Color.WHITE
		else:
			# Background effect, no progress bar
			move_progress_bar.visible = false
