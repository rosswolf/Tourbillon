extends SceneTree

func _init():
	print("\n=== Testing Gremlin Spawn System ===\n")
	
	# Load StaticData
	print("Loading StaticData...")
	StaticData._ready()
	
	# Check if mob_data loaded
	print("mob_data loaded: ", not StaticData.mob_data.is_empty())
	print("mob_data size: ", StaticData.mob_data.size())
	
	# Check for dust_mite
	var dust_mite = StaticData.get_mob_by_id("dust_mite")
	print("dust_mite found: ", not dust_mite.is_empty())
	if not dust_mite.is_empty():
		print("dust_mite data: ", dust_mite.get("display_name", "NO NAME"))
		print("dust_mite health: ", dust_mite.get("max_health", 0))
	
	# Try to spawn using controller
	print("\nAttempting spawn with controller...")
	var controller = GremlinSpawnController.new()
	var gremlin = controller.spawn_gremlin("dust_mite", 0)
	
	if gremlin:
		print("✅ Spawn successful!")
		print("Gremlin name: ", gremlin.gremlin_name)
		print("Gremlin HP: ", gremlin.current_hp, "/", gremlin.max_hp)
	else:
		print("❌ Spawn failed!")
		
	print("\n=== Test Complete ===")
	quit()