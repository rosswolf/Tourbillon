extends Node

## Debug test for mainplate card placement issues

func _ready():
	print("\n=== MAINPLATE DEBUG TEST STARTING ===\n")
	
	# Give scene time to load
	await get_tree().create_timer(1.0).timeout
	
	# Initialize game systems
	print("1. Initializing GlobalGameManager...")
	GlobalGameManager.hero_template_id = "champion"
	
	# Trigger game start
	print("2. Starting game...")
	GlobalSignals.ui_started_game.emit()
	
	# Wait for initialization
	await get_tree().create_timer(0.5).timeout
	
	# Check if mainplate was created
	print("\n3. Checking mainplate entity...")
	if GlobalGameManager.has("mainplate") and GlobalGameManager.mainplate:
		print("   ✓ Mainplate entity exists")
		var mp = GlobalGameManager.mainplate
		print("   - Grid size: ", mp.get("grid_size") if mp.has("grid_size") else "N/A")
		print("   - Max grid size: ", mp.get("max_grid_size") if mp.has("max_grid_size") else "N/A")
	else:
		print("   ✗ Mainplate entity NOT found!")
		
	# Find UI mainplate
	print("\n4. Looking for UI mainplate in scene...")
	var ui_mainplate = get_tree().get_nodes_in_group("mainplate")
	if ui_mainplate.is_empty():
		# Try to find it by class name
		for node in get_tree().get_nodes_in_group("*"):
			if node.get_class() == "UIMainplate":
				ui_mainplate.append(node)
				break
	
	if ui_mainplate.is_empty():
		# Direct search
		var root = get_tree().root
		ui_mainplate = __find_nodes_of_type(root, "UIMainplate")
	
	if not ui_mainplate.is_empty():
		var mainplate_ui = ui_mainplate[0]
		print("   ✓ Found UIMainplate node")
		print("   - Has mainplate ref: ", mainplate_ui.mainplate != null)
		print("   - Has grid_mapper: ", mainplate_ui.grid_mapper != null)
		
		if mainplate_ui.grid_mapper:
			print("   - GridMapper offset: ", mainplate_ui.grid_mapper.offset)
			print("   - GridMapper logical size: ", mainplate_ui.grid_mapper.logical_size)
			print("   - GridMapper physical size: ", mainplate_ui.grid_mapper.physical_size)
			
			# Check active positions
			var active_positions = mainplate_ui.grid_mapper.get_active_physical_positions()
			print("   - Active physical positions (should be 16): ", active_positions.size())
			if active_positions.size() > 0:
				print("   - First active position: ", active_positions[0])
				print("   - Last active position: ", active_positions[-1])
		
		# Check slot states
		print("\n5. Checking slot states...")
		var active_slots = 0
		var inactive_slots = 0
		for pos in mainplate_ui.gear_slots:
			var slot = mainplate_ui.gear_slots[pos]
			if slot.is_active_slot:
				active_slots += 1
			else:
				inactive_slots += 1
		
		print("   - Active slots: ", active_slots, " (should be 16)")
		print("   - Inactive slots: ", inactive_slots, " (should be 48)")
		
		# List some active slot positions
		if active_slots > 0:
			print("\n   Active slot positions:")
			var count = 0
			for pos in mainplate_ui.gear_slots:
				var slot = mainplate_ui.gear_slots[pos]
				if slot.is_active_slot:
					print("     - Physical position ", pos, " is ACTIVE")
					count += 1
					if count >= 4:
						break
	else:
		print("   ✗ UIMainplate NOT found in scene!")
	
	print("\n6. Checking signal connections...")
	if GlobalSignals.ui_execute_selected_onto_hovered.is_connected(GlobalGameManager.__handle_activation):
		print("   ✓ Drop signal connected to GlobalGameManager")
	else:
		print("   ✗ Drop signal NOT connected!")
	
	# Test hover registration
	print("\n7. Testing slot hover registration...")
	await get_tree().create_timer(0.5).timeout
	
	if not ui_mainplate.is_empty():
		var mainplate_ui = ui_mainplate[0]
		# Try to find an active slot
		for pos in mainplate_ui.gear_slots:
			var slot = mainplate_ui.gear_slots[pos]
			if slot.is_active_slot:
				print("   Testing hover on active slot at ", pos)
				# Simulate hover
				slot._on_mouse_entered()
				await get_tree().create_timer(0.1).timeout
				
				# Check if it registered
				if GlobalSelectionManager.get_hovered_instance_id() == slot.__button_entity.instance_id:
					print("   ✓ Slot hover registered correctly!")
				else:
					print("   ✗ Slot hover did NOT register")
					print("   - Expected: ", slot.__button_entity.instance_id)
					print("   - Got: ", GlobalSelectionManager.get_hovered_instance_id())
				
				slot._on_mouse_exited()
				break
	
	print("\n=== MAINPLATE DEBUG TEST COMPLETE ===\n")
	
	# Keep running for observation
	await get_tree().create_timer(3.0).timeout
	print("Test finished. You can now interact with the game.")

func __find_nodes_of_type(node: Node, type_name: String) -> Array:
	var found = []
	if node.get_class() == type_name:
		found.append(node)
	for child in node.get_children():
		found.append_array(__find_nodes_of_type(child, type_name))
	return found