extends Node

var __enum_mappings = {}
var __resolved_enum_cache = {}
var __lookup_cache = {}

var card_data: Dictionary = {}
var card_data_path = "res://src/scenes/data/card_data.json"
var card_data_indices = {}  # Field-based indices for fast lookups

static var icon_data: Dictionary = {}
var icon_data_path = "res://src/scenes/data/icon_data.json"
var icon_data_indices = {}

var mob_data: Dictionary = {}
var mob_data_path = "res://src/scenes/data/mob_data.json"
var mob_data_indices = {}

var goals_data: Dictionary = {}
var goals_data_path = "res://src/scenes/data/goals_data.json"
var goals_data_indices = {}

var relic_data: Dictionary = {}
var relic_data_path = "res://src/scenes/data/relic_data.json"
var relic_data_indices = {}

var hero_data: Dictionary = {}
var hero_data_path = "res://src/scenes/data/hero_data.json"
var hero_data_indices = {}

var wave_data: Dictionary = {}
var wave_data_path = "res://wave_data.json"
var wave_data_indices = {}

static var configuration_data: Dictionary = {}
var configuration_data_path = "res://src/scenes/data/configuration_data.json"

func _init():
	__build_enum_mappings()

func __build_enum_mappings():
	# Auto-generate mappings from enum definitions
	__add_enum_mapping("Card.RarityType", Card.RarityType)
	__add_enum_mapping("GameResource.Type", GameResource.Type)
	
	# Add individual GameResource.Type mappings for force types (from PRD)
	__enum_mappings["GameResource.Type.HEAT"] = GameResource.Type.HEAT
	__enum_mappings["GameResource.Type.PRECISION"] = GameResource.Type.PRECISION
	__enum_mappings["GameResource.Type.MOMENTUM"] = GameResource.Type.MOMENTUM
	__enum_mappings["GameResource.Type.BALANCE"] = GameResource.Type.BALANCE
	__enum_mappings["GameResource.Type.ENTROPY"] = GameResource.Type.ENTROPY
	__enum_mappings["GameResource.Type.INSPIRATION"] = GameResource.Type.INSPIRATION

func __add_enum_mapping(prefix: String, enum_dict: Dictionary):
	for key in enum_dict:
		var full_reference = prefix + "." + key
		__enum_mappings[full_reference] = enum_dict[key]
		print("Mapped: ", full_reference, " -> ", enum_dict[key])

func parse_enum(reference: String):
	# Use cached result if available
	if __resolved_enum_cache.has(reference):
		return __resolved_enum_cache[reference]
	
	var result = __enum_mappings.get(reference, reference)
	__resolved_enum_cache[reference] = result
	return result

func _ready():
	card_data = load_json_file(card_data_path)
	mob_data = load_json_file(mob_data_path)
	print("[StaticData] Loaded %d mobs from %s" % [mob_data.size(), mob_data_path])
	configuration_data = load_json_file(configuration_data_path)
	icon_data = load_json_file(icon_data_path)
	goals_data = load_json_file(goals_data_path)
	relic_data = load_json_file(relic_data_path)
	hero_data = load_json_file(hero_data_path)
	wave_data = load_json_file(wave_data_path)
	print("[StaticData] Loaded %d waves from %s" % [wave_data.size(), wave_data_path])
	
	# Build indices for fast lookups
	card_data_indices = build_field_indices(card_data)
	mob_data_indices = build_field_indices(mob_data)
	goals_data_indices = build_field_indices(goals_data)
	relic_data_indices = build_field_indices(relic_data)
	hero_data_indices = build_field_indices(hero_data)
	wave_data_indices = build_field_indices(wave_data)

func build_field_indices(data_dict: Dictionary) -> Dictionary:
	"""Build reverse indices for all fields to enable O(1) lookups"""
	var indices = {}
	
	for primary_key in data_dict:
		var record = data_dict[primary_key]
		
		for field_name in record:
			var field_value = record[field_name]
			
			# Initialize field index if it doesn't exist
			if not indices.has(field_name):
				indices[field_name] = {}
			
			# Handle different value types for indexing
			var index_keys = []
			if field_value is Array:
				# For arrays, index each element
				for item in field_value:
					add_index_key_variants(index_keys, item)
			else:
				# For single values
				add_index_key_variants(index_keys, field_value)
			
			# Add this record to all relevant index entries
			for index_key in index_keys:
				if not indices[field_name].has(index_key):
					indices[field_name][index_key] = []
				indices[field_name][index_key].append(primary_key)
	
	return indices

func add_index_key_variants(index_keys: Array, value):
	"""Add both original value and numeric variants to index keys"""
	# Always add the original value first
	index_keys.append(value)
	
	# Add numeric variants for compatibility
	if value is int:
		index_keys.append(float(value))
	elif value is float:
		# Only add int variant if it's a whole number
		if value == floor(value):
			index_keys.append(int(value))

func load_json_file(path):
	if FileAccess.file_exists(path):
		var datafile = FileAccess.open(path, FileAccess.READ)
		var parsed_result = JSON.parse_string(datafile.get_as_text())
		datafile.close()
		
		if parsed_result is Array:
			# Process array of records, resolve enums, and convert to nested dict
			return resolve_json_data(parsed_result)
		elif parsed_result is Dictionary:
			# Process single dictionary and resolve enum references
			return resolve_json_record(parsed_result)
		else:
			printerr("Error: unexpected data type from json parse")
			return {}
	else:
		printerr("no file at path: ", path)
		return {}

func get_data_type_name(data_dict: Dictionary) -> String:
	"""Helper to identify which data dictionary is being used"""
	if data_dict == card_data:
		return "card"
	elif data_dict == mob_data:
		return "mob"
	elif data_dict == goals_data:
		return "goal"
	elif data_dict == relic_data:
		return "relic"
	elif data_dict == hero_data:
		return "hero"
	elif data_dict == icon_data:
		return "icon"
	elif data_dict == configuration_data:
		return "config"
	else:
		# For unknown dictionaries, use a hash of the first few keys as identifier
		var keys = data_dict.keys()
		if keys.size() > 0:
			return "unknown_" + str(keys.slice(0, 3).hash())
		else:
			return "empty"

func get_data_and_indices_for_type(data_type: String) -> Array:
	"""Helper to get the appropriate data dictionary and indices"""
	match data_type:
		"card":
			return [card_data, card_data_indices]
		"mob":
			return [mob_data, mob_data_indices]
		"goal":
			return [goals_data, goals_data_indices]
		"relic":
			return [relic_data, relic_data_indices]
		"icon":
			return [icon_data, icon_data_indices]
		"hero":
			return [hero_data, hero_data_indices]
		_:
			printerr("Unknown data type: ", data_type)
			return [{}, {}]

func lookup_in_data(data_dict: Dictionary, field_to_filter: String, filter_value, field_to_return: String) -> Array:
	"""Optimized lookup using indices when available"""
	
	# Generate cache key for this exact query using dictionary hash
	var data_type = get_data_type_name(data_dict)
	var cache_key = data_type + "|" + field_to_filter + "|" + str(filter_value) + "|" + field_to_return
	if __lookup_cache.has(cache_key):
		return __lookup_cache[cache_key]
	
	var results = []
	var indices = null
	
	# Try to find appropriate indices for this data_dict
	if data_dict == card_data:
		indices = card_data_indices
	elif data_dict == mob_data:
		indices = mob_data_indices
	elif data_dict == goals_data:
		indices = goals_data_indices
	elif data_dict == relic_data:
		indices = relic_data_indices
	elif data_dict == hero_data:
		indices = hero_data_indices
	
	# Use indexed lookup if available
	if indices != null and indices.has(field_to_filter):
		var field_index = indices[field_to_filter]
		var resolved_filter_value = resolve_filter_value(filter_value)
		
		# Try lookup with different value variants
		var matching_keys = []
		var tried_values = {}  # Prevent duplicate lookups
		
		# Try original filter value
		if field_index.has(filter_value) and not tried_values.has(filter_value):
			matching_keys.append_array(field_index[filter_value])
			tried_values[filter_value] = true
		
		# Try resolved enum value if different
		if resolved_filter_value != filter_value and field_index.has(resolved_filter_value) and not tried_values.has(resolved_filter_value):
			matching_keys.append_array(field_index[resolved_filter_value])
			tried_values[resolved_filter_value] = true
		
		# Try numeric variants
		if filter_value is int:
			var float_variant = float(filter_value)
			if field_index.has(float_variant) and not tried_values.has(float_variant):
				matching_keys.append_array(field_index[float_variant])
				tried_values[float_variant] = true
		elif filter_value is float and filter_value == floor(filter_value):
			var int_variant = int(filter_value)
			if field_index.has(int_variant) and not tried_values.has(int_variant):
				matching_keys.append_array(field_index[int_variant])
				tried_values[int_variant] = true
		
		# Get results from matching records (deduplicate keys first)
		var unique_keys = {}
		for key in matching_keys:
			unique_keys[key] = true
		
		for key in unique_keys:
			if data_dict.has(key) and data_dict[key].has(field_to_return):
				results.append(data_dict[key][field_to_return])
	else:
		# Fall back to linear search (for backwards compatibility)
		results = lookup_in_data_linear(data_dict, field_to_filter, filter_value, field_to_return)
	
	# Cache the result
	__lookup_cache[cache_key] = results
	return results

func resolve_filter_value(filter_value):
	"""Pre-resolve filter value with caching"""
	if filter_value is String and __is_enum_reference(filter_value):
		return parse_enum(filter_value)
	return filter_value

func lookup_in_data_linear(data_dict: Dictionary, field_to_filter: String, filter_value, field_to_return: String) -> Array:
	"""Original linear search method as fallback"""
	var results = []
	
	# Try to resolve enum if it's a string that looks like an enum reference
	var resolved_filter_value = resolve_filter_value(filter_value)
	
	for key in data_dict:
		var record = data_dict[key]
		
		if record.has(field_to_filter):
			var field_value = record[field_to_filter]
			
			var matches = false
			if field_value is String:
				matches = (field_value == filter_value) or (field_value == resolved_filter_value)
			elif field_value is int or field_value is float:
				# Handle numeric comparisons (int/float compatibility)
				matches = compare_numeric_values(field_value, filter_value, resolved_filter_value)
			elif field_value is Array:
				matches = (filter_value in field_value) or (resolved_filter_value in field_value)
			
			if matches and record.has(field_to_return):
				results.append(record[field_to_return])
	
	return results

func compare_numeric_values(field_value, filter_value, resolved_filter_value) -> bool:
	"""Optimized numeric comparison with pre-converted values"""
	var field_as_float = float(field_value)
	
	# Try resolved enum value first
	if resolved_filter_value != filter_value and (resolved_filter_value is int or resolved_filter_value is float):
		return abs(field_as_float - float(resolved_filter_value)) < 0.0001
	
	# Handle original filter value
	if filter_value is int or filter_value is float:
		return abs(field_as_float - float(filter_value)) < 0.0001
	elif filter_value is String and filter_value.is_valid_float():
		return abs(field_as_float - float(filter_value)) < 0.0001
	
	return false

func __is_enum_reference(value: String) -> bool:
	"""Check if a string looks like an enum reference (with caching)"""
	var cache_key = "enum_ref:" + value
	if __resolved_enum_cache.has(cache_key):
		return __resolved_enum_cache[cache_key]
	
	var result = value.count(".") >= 2 and __enum_mappings.has(value)
	__resolved_enum_cache[cache_key] = result
	return result

func resolve_json_data(data: Array) -> Dictionary:
	"""Process an array of records, resolving enum references in each, then convert to nested dict"""
	var resolved_data = []
	for record in data:
		resolved_data.append(resolve_json_record(record))
	return convert_array_to_nested_dict(resolved_data)

func resolve_json_record(record: Dictionary) -> Dictionary:
	"""Process a single record, resolving enum references in all values"""
	var resolved_record = {}
	for key in record:
		resolved_record[key] = resolve_value(record[key])
	return resolved_record

func resolve_value(value):
	"""Recursively resolve enum references and configuration references in any value type"""
	if value is String:
		# Check for configuration reference first
		if value.begins_with("__CONFIG_REF__"):
			return resolve_configuration_reference(value)
		else:
			return parse_enum(value)
	elif value is float:
		# Convert floats that are actually integers back to int
		return normalize_numeric_value(value)
	elif value is Array:
		var resolved_array = []
		for item in value:
			resolved_array.append(resolve_value(item))
		return resolved_array
	elif value is Dictionary:
		var resolved_dict = {}
		for key in value:
			# Resolve both keys and values for enum references
			var resolved_key = resolve_value(key)
			var resolved_value = resolve_value(value[key])
			resolved_dict[resolved_key] = resolved_value
		return resolved_dict
	else:
		return value

func normalize_numeric_value(value):
	"""Convert floats that are actually integers back to int"""
	if value is float:
		# Check if this float is actually a whole number
		if value == floor(value):
			return int(value)
	return value

func resolve_configuration_reference(config_ref: String):
	"""
	Resolve configuration reference in format __CONFIG_REF__key_name.
	
	Args:
		config_ref (String): Configuration reference string
		
	Returns:
		The value from configuration_data, or the original string if not found
	"""
	if not config_ref.begins_with("__CONFIG_REF__"):
		return config_ref
	
	# Extract the configuration key
	var config_key = config_ref.substr(14)  # Remove "__CONFIG_REF__" prefix
	
	# Look up the value in configuration_data
	if configuration_data.has(config_key):
		var config_record = configuration_data[config_key]
		if config_record.has("configuration_value"):
			var config_value = config_record["configuration_value"]
			print("Resolved config reference '", config_key, "' to: ", config_value)
			return config_value
		else:
			printerr("Configuration record '", config_key, "' has no 'configuration_value' field")
			return config_ref
	else:
		printerr("Configuration key '", config_key, "' not found in configuration_data")
		return config_ref

func convert_array_to_nested_dict(data_array: Array) -> Dictionary:
	"""Convert array of records to nested dictionary using first field as key"""
	var result_dict = {}
	
	for record in data_array:
		if record.size() > 0:
			# Get the first key in the record
			var first_key = record.keys()[0]
			var key_value = record[first_key]
			
			# Use the value of the first field as the dictionary key
			result_dict[key_value] = record
		else:
			printerr("Empty record found in data array")
			return {}
	
	return result_dict

# Convenience method for getting an integer configuration_data value
static func get_int(config_name: String) -> int:
	return int(configuration_data[config_name].get("configuration_value"))

# Convenience method for getting a float configuration_data value
static func get_float(config_name: String) -> float:
	return float(configuration_data[config_name].get("configuration_value"))

# New convenience methods for direct key-based lookups
func get_card_by_id(card_id: String) -> Dictionary:
	"""Direct O(1) lookup for card by ID"""
	return card_data.get(card_id, {})

func get_mob_by_id(mob_id: String) -> Dictionary:
	"""Direct O(1) lookup for mob by ID"""
	return mob_data.get(mob_id, {})

func get_goals_by_id(wave_id: String) -> Dictionary:
	"""Direct O(1) lookup for wave by ID"""
	return goals_data.get(wave_id, {})

func get_relic_by_id(relic_id: String) -> Dictionary:
	"""Direct O(1) lookup for relic by ID"""
	return relic_data.get(relic_id, {})

func get_hero_by_id(hero_id: String) -> Dictionary:
	"""Direct O(1) lookup for hero by ID"""
	return hero_data.get(hero_id, {})

func get_wave_by_id(wave_id: String) -> Dictionary:
	"""Direct O(1) lookup for wave by ID"""
	return wave_data.get(wave_id, {})

func get_random_wave_for_act(act: int) -> Dictionary:
	"""Get a random non-boss wave for the specified act"""
	print("[StaticData] Looking for waves for act %d in %d total waves" % [act, wave_data.size()])
	var act_waves: Array = []
	for wave_id in wave_data:
		var wave = wave_data[wave_id]
		var wave_act = wave.get("act", 0)
		var is_boss = wave.get("is_boss", false)
		print("[StaticData] Wave %s: act=%d, is_boss=%s" % [wave_id, wave_act, is_boss])
		if wave_act == act and not is_boss:
			act_waves.append(wave)
	
	print("[StaticData] Found %d waves for act %d" % [act_waves.size(), act])
	if act_waves.size() > 0:
		var selected = act_waves.pick_random()
		print("[StaticData] Selected wave: %s" % selected.get("wave_id", "unknown"))
		return selected
	print("[StaticData] No waves found for act %d!" % act)
	return {}

func get_all_waves_for_act(act: int) -> Array:
	"""Get all waves for the specified act"""
	var act_waves: Array = []
	for wave_id in wave_data:
		var wave = wave_data[wave_id]
		if wave.get("act", 0) == act:
			act_waves.append(wave)
	return act_waves

# Cache management methods
func clear_lookup_cache():
	"""Clear the lookup cache if needed (e.g., after data updates)"""
	__lookup_cache.clear()

func clear_enum_cache():
	"""Clear the enum resolution cache if needed"""
	__resolved_enum_cache.clear()

func get_cache_stats() -> Dictionary:
	"""Get statistics about cache usage for debugging"""
	return {
		"lookup_cache_size": __lookup_cache.size(),
		"enum_cache_size": __resolved_enum_cache.size()
	}
