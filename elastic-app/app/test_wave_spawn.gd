extends SceneTree

func _init():
	print("Testing wave spawn system...")
	
	# Load static data
	var static_data = preload("res://src/scenes/data/static_data.gd").new()
	static_data._ready()
	
	# Test wave loading
	print("\n--- Testing Wave Loading ---")
	var wave_1a = static_data.get_wave_by_id("wave_1a")
	if wave_1a:
		print("✓ Loaded wave_1a: ", wave_1a.get("display_name", "Unknown"))
		print("  Difficulty: ", wave_1a.get("difficulty_tier", "Unknown"), " (", wave_1a.get("difficulty", 0), ")")
		print("  Gremlins: ", wave_1a.get("gremlins", ""))
	else:
		print("✗ Failed to load wave_1a")
	
	# Test random wave for act 1
	print("\n--- Testing Random Wave Selection ---")
	var random_wave = static_data.get_random_wave_for_act(1)
	if random_wave:
		print("✓ Random Act 1 wave: ", random_wave.get("display_name", "Unknown"))
	else:
		print("✗ Failed to get random wave for act 1")
	
	# Test act 1 waves
	print("\n--- Act 1 Waves ---")
	var act1_waves = static_data.get_all_waves_for_act(1)
	print("Found ", act1_waves.size(), " waves for Act 1:")
	for wave in act1_waves:
		print("  - ", wave.get("display_name", "Unknown"), " (", wave.get("difficulty_tier", "Unknown"), ")")
	
	print("\n✓ Wave system test complete!")
	quit()