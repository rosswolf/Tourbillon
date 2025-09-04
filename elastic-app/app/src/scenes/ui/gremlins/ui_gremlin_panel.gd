extends PanelContainer
class_name UiGremlinPanel

## Panel that displays all active gremlins
## Shows their HP, shields, and disruption effects

@onready var gremlin_container: VBoxContainer = %GremlinContainer

var ui_gremlin_scene: PackedScene = preload("res://src/scenes/ui/entities/gremlins/ui_gremlin.tscn")
var active_gremlin_uis: Dictionary[String, Variant] = {}  # gremlin_id -> UiGremlin

func _ready() -> void:
	# Connect to gremlin spawn/despawn signals
	GlobalSignals.core_mob_created.connect(__on_gremlin_spawned)
	
	# Apply background if we have one
	__setup_background()
	
	# Gremlins are added via core_mob_created signal when spawned

func __setup_background() -> void:
	# No background styling - keep it transparent/default
	pass

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

func __on_gremlin_defeated(gremlin_id: String) -> void:
	if gremlin_id in active_gremlin_uis:
		# The UI will handle its own removal animation
		active_gremlin_uis.erase(gremlin_id)
		


## Load gremlin data from mob_data.json and spawn initial gremlins
func spawn_test_gremlins() -> void:
	# Load some test gremlins from mob_data.json
	var mob_data = StaticData.mob_data
	if not mob_data:
		push_warning("No mob data loaded!")
		return
	
	# Spawn a few different gremlin types for testing
	var test_types: Array[String] = ["basic_gnat", "dust_mite", "static_beetle"]
	
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
	var gremlin: Gremlin = Gremlin.GremlinBuilder.new() \
		.with_name(data.get("display_name", "Unknown Gremlin")) \
		.with_hp(data.get("max_health", 10)) \
		.with_shields(data.get("max_shields", 0)) \
		.build()
	
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
