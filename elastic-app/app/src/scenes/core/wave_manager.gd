extends Node
class_name WaveManager

var current_wave: Dictionary = {}
var current_act: int = 1

func spawn_wave(wave_id: String = "") -> void:
	var wave_data: Dictionary = {}
	
	if wave_id.is_empty():
		wave_data = StaticData.get_random_wave_for_act(current_act)
		if wave_data.is_empty():
			push_error("No waves found for act %d" % current_act)
			return
	else:
		wave_data = StaticData.get_wave_by_id(wave_id)
		if wave_data.is_empty():
			push_error("Wave not found: %s" % wave_id)
			return
	
	current_wave = wave_data
	print("[WaveManager] Spawning wave: %s (%s)" % [wave_data.get("display_name", "Unknown"), wave_data.get("wave_id", "")])
	print("[WaveManager] Difficulty: %s (%d)" % [wave_data.get("difficulty_tier", "Unknown"), wave_data.get("difficulty", 0)])
	
	# Handle gremlins as either String (pipe-separated) or Array
	var gremlins_data = wave_data.get("gremlins", "")
	var gremlin_ids: Array[String] = []
	
	if gremlins_data is String:
		var gremlins_string: String = gremlins_data
		if gremlins_string.is_empty():
			push_error("Wave has no gremlins defined: %s" % wave_id)
			return
		for gremlin_id in gremlins_string.split("|"):
			gremlin_ids.append(gremlin_id.strip_edges())
	elif gremlins_data is Array:
		if gremlins_data.is_empty():
			push_error("Wave has no gremlins defined: %s" % wave_id)
			return
		for gremlin_id in gremlins_data:
			gremlin_ids.append(str(gremlin_id).strip_edges())
	else:
		push_error("Invalid gremlins format in wave: %s" % wave_id)
		return
	
	for gremlin_id in gremlin_ids:
		_spawn_gremlin(gremlin_id)

func _spawn_gremlin(gremlin_type: String) -> void:
	print("[WaveManager] Attempting to spawn gremlin type: %s" % gremlin_type)
	
	var global_game_manager = get_node_or_null("/root/GlobalGameManager")
	if not global_game_manager:
		push_error("GlobalGameManager not found!")
		return
	
	var instance_catalog = global_game_manager.instance_catalog
	if not instance_catalog:
		push_error("Instance catalog not initialized!")
		return
	
	var mob_data = StaticData.mob_data
	if not mob_data:
		push_error("No mob data loaded!")
		return
	
	print("[WaveManager] Mob data has %d entries" % mob_data.size())
	
	if gremlin_type not in mob_data:
		push_error("Unknown gremlin type: %s" % gremlin_type)
		print("[WaveManager] Available mob types: %s" % str(mob_data.keys()))
		return
	
	var data = mob_data[gremlin_type]
	var gremlin = Gremlin.new()
	gremlin.gremlin_name = data.get("display_name", "Unknown Gremlin")
	gremlin.max_hp = data.get("max_health", 10)
	gremlin.current_hp = gremlin.max_hp
	gremlin.shields = data.get("max_shields", 0)
	gremlin.moves_string = data.get("moves", "")
	
	instance_catalog.register_instance(gremlin)
	global_game_manager.add_child(gremlin)
	GlobalSignals.signal_core_mob_created(gremlin.instance_id)
	
	print("[WaveManager] Spawned gremlin: %s with %d HP" % [gremlin.gremlin_name, gremlin.current_hp])

func set_act(act: int) -> void:
	current_act = act
	print("[WaveManager] Act set to %d" % act)

func get_current_wave_info() -> Dictionary:
	return current_wave
