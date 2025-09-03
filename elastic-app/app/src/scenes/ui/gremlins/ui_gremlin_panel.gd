extends PanelContainer
class_name UiGremlinPanel

## Panel that displays all active gremlins
## Shows their HP, shields, and disruption effects

@onready var gremlin_container: VBoxContainer = %GremlinContainer
@onready var title_label: Label = %TitleLabel

var ui_gremlin_scene = preload("res://src/scenes/ui/entities/gremlins/ui_gremlin.tscn")
var active_gremlin_uis: Dictionary = {}  # gremlin_id -> UiGremlin

func _ready() -> void:
	# Connect to gremlin spawn/despawn signals
	GlobalSignals.core_mob_created.connect(__on_gremlin_spawned)
	
	# Apply background if we have one
	__setup_background()
	
	# Gremlins are added via core_mob_created signal when spawned

func __setup_background() -> void:
	# Apply a cropped background texture
	# You can load a specific background image here
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.05, 0.05, 0.9)  # Dark red-tinted background
	style.border_color = Color(0.6, 0.1, 0.1, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	add_theme_stylebox_override("panel", style)

func __on_gremlin_spawned(mob_id: String) -> void:
	# Get the gremlin entity
	if not GlobalGameManager.instance_catalog:
		return
		
	var gremlin = GlobalGameManager.instance_catalog.get_instance(mob_id) as Gremlin
	if gremlin:
		__add_gremlin_ui(gremlin)

func __add_gremlin_ui(gremlin: Gremlin) -> void:
	if gremlin.instance_id in active_gremlin_uis:
		return  # Already displaying this gremlin
	
	# Create UI for this gremlin
	var gremlin_ui = ui_gremlin_scene.instantiate() as UiGremlin
	gremlin_container.add_child(gremlin_ui)
	gremlin_ui.set_entity_data(gremlin)
	
	# Track it
	active_gremlin_uis[gremlin.instance_id] = gremlin_ui
	
	# Connect to defeat signal for cleanup
	gremlin.defeated.connect(__on_gremlin_defeated.bind(gremlin.instance_id))
	
	# Update title
	__update_title()

func __on_gremlin_defeated(gremlin_id: String) -> void:
	if gremlin_id in active_gremlin_uis:
		# The UI will handle its own removal animation
		active_gremlin_uis.erase(gremlin_id)
		
		# Update title after a delay for the animation
		await get_tree().create_timer(0.6).timeout
		__update_title()

func __update_title() -> void:
	if title_label:
		var count = active_gremlin_uis.size()
		if count == 0:
			title_label.text = "No Active Gremlins"
		elif count == 1:
			title_label.text = "1 Active Gremlin"
		else:
			title_label.text = "%d Active Gremlins" % count

## Load gremlin data from mob_data.json and spawn initial gremlins
func spawn_test_gremlins() -> void:
	# Load some test gremlins from mob_data.json
	var mob_data = StaticData.mob_data
	if not mob_data:
		push_warning("No mob data loaded!")
		return
	
	# Spawn a few different gremlin types for testing
	var test_types = ["basic_gnat", "dust_mite", "static_beetle"]
	
	for i in range(min(3, test_types.size())):
		var mob_type = test_types[i]
		if mob_type in mob_data:
			var data = mob_data[mob_type]
			var gremlin = __create_gremlin_from_data(data)
			if gremlin:
				gremlin.slot_index = i
				GlobalGameManager.instance_catalog.register_instance(gremlin)
				GlobalSignals.signal_core_mob_created(gremlin.instance_id)

func __create_gremlin_from_data(data: Dictionary) -> Gremlin:
	var gremlin = Gremlin.new()
	gremlin.gremlin_name = data.get("display_name", "Unknown Gremlin")
	gremlin.max_hp = data.get("max_health", 10)
	gremlin.current_hp = gremlin.max_hp
	gremlin.shields = data.get("max_shields", 0)
	
	# Set disruption based on archetype
	var archetype = data.get("archetype", "")
	match archetype:
		"rusher":
			gremlin.disruption_interval_beats = 30  # 3 ticks
		"tank":
			gremlin.disruption_interval_beats = 50  # 5 ticks
		"disruptor":
			gremlin.disruption_interval_beats = 40  # 4 ticks
		_:
			gremlin.disruption_interval_beats = 50  # Default 5 ticks
	
	gremlin.beats_until_disruption = gremlin.disruption_interval_beats
	
	return gremlin
