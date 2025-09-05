extends Node

func _ready():
	print("\n=== Simple Spawn Test ===")
	
	# Check StaticData
	print("Checking StaticData...")
	print("  mob_data type: ", typeof(StaticData.mob_data))
	print("  mob_data size: ", StaticData.mob_data.size())
	
	# Try to get dust_mite
	var dust_mite = StaticData.get_mob_by_id("dust_mite")
	print("  dust_mite found: ", not dust_mite.is_empty())
	
	# Create spawn controller
	var controller = GremlinSpawnController.new()
	add_child(controller)
	
	# Try to spawn
	print("\nSpawning dust_mite...")
	var gremlin = controller.spawn_gremlin("dust_mite", 0)
	
	if gremlin:
		print("  SUCCESS! Spawned: ", gremlin.gremlin_name)
	else:
		print("  FAILED to spawn gremlin")
		
		# Debug - check what's in mob_data
		print("\n  Debug - First few mob IDs in StaticData:")
		var count = 0
		for key in StaticData.mob_data:
			print("    - ", key)
			count += 1
			if count >= 5:
				break
	
	get_tree().quit()