extends Node

## Test to verify mainplate is now working

func _ready():
	print("\n=== MAINPLATE INTEGRATION TEST ===\n")

	# Start in-game
	await get_tree().process_frame
	print("Starting game...")

	# Find and click start button or trigger game start
	GlobalGameManager.hero_template_id = "champion"
	GlobalSignals.ui_started_game.emit()

	# Wait for initialization
	await get_tree().create_timer(2.0).timeout

	print("\nChecking mainplate integration...")

	# Check if GlobalGameManager has mainplate
	var has_mainplate = false
	for prop in GlobalGameManager.get_property_list():
		if prop.name == "mainplate":
			var value = GlobalGameManager.get(prop.name)
			if value != null:
				has_mainplate = true
				print("✓ GlobalGameManager has mainplate entity")
			break

	if not has_mainplate:
		print("✗ GlobalGameManager missing mainplate entity")
		return

	# Find UIMainplate in scene
	var ui_mainplate_found = false
	for node in get_tree().get_nodes_in_group("mainplate"):
		print("✓ Found UIMainplate node in 'mainplate' group")
		ui_mainplate_found = true

		# Check if it has the expected properties
		if node.has("gear_slots"):
			var slots = node.get("gear_slots")
			if slots is Dictionary:
				print("[DEBUG]   - Has ", slots.size(), " gear slots")

				# Count active slots
				var active = 0
				for pos in slots:
					var slot = slots[pos]
					if slot and slot.has("is_active_slot") and slot.is_active_slot:
						active += 1
				print("[DEBUG]   - Active slots: ", active, " (should be 16 for 4x4 grid)")

				if active == 16:
					print("\n✓✓✓ MAINPLATE IS CORRECTLY CONFIGURED! ✓✓✓")
				elif active == 0:
					print("\n✗ WARNING: No slots are active! Check slot activation.")
				else:
					print("[DEBUG] \n⚠ WARNING: Active slot count mismatch (expected 16, got ", active, ")")

		if node.has("grid_mapper"):
			var mapper = node.get("grid_mapper")
			if mapper:
				print("[DEBUG]   - Has grid_mapper configured")
		break

	if not ui_mainplate_found:
		print("✗ UIMainplate not found in scene")

	print("\n=== TEST COMPLETE ===\n")

	# Keep running for a bit to see the output
	await get_tree().create_timer(3.0).timeout