extends Node
class_name GremlinSpawnController

## Singleton controller for spawning gremlins from mob_data templates
## Integrates with StaticData, EntityManager, and BeatManager

signal gremlin_spawned(gremlin: Gremlin)
signal wave_spawned(gremlins: Array)
signal all_gremlins_defeated()

static var instance: GremlinSpawnController

var active_gremlins: Array[Gremlin] = []
var spawn_queue: Array[String] = []  # Template IDs to spawn

func _init() -> void:
	if instance == null:
		instance = self

func _ready() -> void:
	# Connect to gremlin defeated signals as they spawn
	pass

## Spawn a gremlin from a template ID in mob_data
func spawn_gremlin(template_id: String, slot_index: int = -1) -> Gremlin:
	# Access mob_data directly from StaticData
	if not StaticData.mob_data:
		push_error("mob_data not loaded in StaticData")
		return null
	
	var gremlin_data = StaticData.get_mob_by_id(template_id)
	
	if gremlin_data.is_empty():
		push_error("Gremlin template not found: " + template_id)
		return null
	
	# Use existing GremlinBuilder pattern
	var builder = Gremlin.GremlinBuilder.new()
	
	# Set basic properties from mob_data
	builder.with_name(gremlin_data.get("display_name", "Unknown Gremlin"))
	builder.with_hp(gremlin_data.get("max_health", 10))
	builder.with_armor(gremlin_data.get("max_armor", 0))
	builder.with_shields(gremlin_data.get("max_shields", 0))
	builder.with_barriers(gremlin_data.get("barrier_count", 0))
	
	# Set slot position
	if slot_index >= 0:
		builder.with_slot(slot_index)
	else:
		# Auto-assign next available slot
		builder.with_slot(active_gremlins.size())
	
	# Parse moves/downsides string
	var moves_string = _build_moves_string(gremlin_data)
	if not moves_string.is_empty():
		builder.with_moves(moves_string)
	
	# Build the gremlin
	var gremlin = builder.build()
	
	# Set additional properties not in builder
	if gremlin_data.has("damage_cap"):
		gremlin.damage_cap = gremlin_data.get("damage_cap", 0)
	if gremlin_data.has("reflect_percent"):
		gremlin.reflect_percent = gremlin_data.get("reflect_percent", 0.0)
	if gremlin_data.has("execute_immunity_threshold"):
		gremlin.execute_immunity_threshold = gremlin_data.get("execute_immunity_threshold", 0)
	if gremlin_data.has("invulnerable"):
		gremlin.invulnerable = gremlin_data.get("invulnerable", false)
	
	# Store template ID as metadata for reference
	gremlin.set_meta("template_id", template_id)
	gremlin.set_meta("archetype", gremlin_data.get("archetype", "basic"))
	gremlin.set_meta("size_category", gremlin_data.get("size_category", "medium"))
	
	# Register with systems
	_register_gremlin(gremlin)
	
	# Track in active list
	active_gremlins.append(gremlin)
	
	# Connect to defeated signal
	gremlin.defeated.connect(_on_gremlin_defeated.bind(gremlin))
	
	# Emit spawn signal
	gremlin_spawned.emit(gremlin)
	
	print("Spawned gremlin: ", gremlin.gremlin_name, " in slot ", gremlin.slot_index)
	
	return gremlin

## Spawn multiple gremlins from a wave composition string
func spawn_wave(wave_composition: String) -> Array[Gremlin]:
	# Parse pipe-separated gremlin list (e.g. "dust_mite|oil_thief|dust_mite")
	var gremlin_ids = wave_composition.split("|")
	var spawned: Array[Gremlin] = []
	
	for i in range(gremlin_ids.size()):
		var template_id = gremlin_ids[i].strip_edges()
		if template_id.is_empty():
			continue
			
		var gremlin = spawn_gremlin(template_id, i)
		if gremlin:
			spawned.append(gremlin)
	
	if spawned.size() > 0:
		wave_spawned.emit(spawned)
		print("Spawned wave with ", spawned.size(), " gremlins")
	
	return spawned

## Clear all active gremlins (for cleanup or reset)
func clear_all_gremlins() -> void:
	for gremlin in active_gremlins:
		if is_instance_valid(gremlin):
			_unregister_gremlin(gremlin)
			gremlin.queue_free()
	
	active_gremlins.clear()
	print("Cleared all active gremlins")

## Get all active gremlins
func get_active_gremlins() -> Array[Gremlin]:
	# Clean up any invalid references first
	active_gremlins = active_gremlins.filter(func(g): return is_instance_valid(g))
	return active_gremlins

## Check if all gremlins are defeated
func are_all_defeated() -> bool:
	for gremlin in active_gremlins:
		if is_instance_valid(gremlin) and gremlin.current_hp > 0:
			return false
	return true

## Build moves string from gremlin data
func _build_moves_string(gremlin_data: Dictionary) -> String:
	# Check for explicit moves_string first
	if gremlin_data.has("moves_string") and not gremlin_data["moves_string"].is_empty():
		return gremlin_data["moves_string"]
	
	# Otherwise build from move_cycle if present
	if gremlin_data.has("move_cycle"):
		# Convert move_cycle to moves_string format
		# This would need to be implemented based on the move format
		return _convert_move_cycle_to_string(gremlin_data["move_cycle"])
	
	# Check for simple move pattern
	if gremlin_data.has("move_pattern"):
		return gremlin_data["move_pattern"]
	
	return ""

## Convert move cycle array to moves string format
func _convert_move_cycle_to_string(move_cycle: Array) -> String:
	# TODO: Implement based on move cycle format
	# For now, return empty string
	return ""

## Register gremlin with game systems
func _register_gremlin(gremlin: Gremlin) -> void:
	# TODO: Implement EntityManager singleton for entity tracking
	# if EntityManager.instance:
	#     EntityManager.register_entity(gremlin)
	
	# Register with TimelineManager via GlobalGameManager
	if GlobalGameManager.timeline_manager:
		GlobalGameManager.timeline_manager.register_beat_listener(gremlin)
	
	# Could also register with UI systems here
	# if BattleUI.instance:
	#     BattleUI.add_gremlin_display(gremlin)

## Unregister gremlin from game systems
func _unregister_gremlin(gremlin: Gremlin) -> void:
	# TODO: Implement EntityManager singleton for entity tracking
	# if EntityManager.instance:
	#     EntityManager.unregister_entity(gremlin.instance_id)
	
	# Unregister from TimelineManager via GlobalGameManager
	if GlobalGameManager.timeline_manager:
		GlobalGameManager.timeline_manager.unregister_beat_listener(gremlin)

## Handle gremlin defeated
func _on_gremlin_defeated(gremlin: Gremlin) -> void:
	print("Gremlin defeated: ", gremlin.gremlin_name)
	
	# Remove from active list
	active_gremlins.erase(gremlin)
	
	# Unregister from systems
	_unregister_gremlin(gremlin)
	
	# Check if all defeated
	if active_gremlins.is_empty():
		all_gremlins_defeated.emit()
		print("All gremlins defeated!")

## Spawn specific gremlin for testing
func spawn_test_gremlin() -> Gremlin:
	# Spawn a basic test gremlin
	return spawn_gremlin("dust_mite", 0)

## Get gremlin in specific slot
func get_gremlin_in_slot(slot: int) -> Gremlin:
	for gremlin in active_gremlins:
		if is_instance_valid(gremlin) and gremlin.slot_index == slot:
			return gremlin
	return null

## Get gremlins by archetype
func get_gremlins_by_archetype(archetype: String) -> Array[Gremlin]:
	var matching: Array[Gremlin] = []
	for gremlin in active_gremlins:
		if is_instance_valid(gremlin) and gremlin.get_meta("archetype", "") == archetype:
			matching.append(gremlin)
	return matching