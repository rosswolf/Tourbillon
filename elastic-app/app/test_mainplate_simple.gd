extends Node

func _ready():
	print("\n=== SIMPLE MAINPLATE TEST ===\n")

	# Give scene time to load
	await get_tree().create_timer(1.0).timeout

	# Initialize game
	print("[DEBUG] 1. Setting hero template...")
	GlobalGameManager.hero_template_id = "champion"

	print("[DEBUG] 2. Emitting game start signal...")
	GlobalSignals.ui_started_game.emit()

	# Wait for initialization
	await get_tree().create_timer(2.0).timeout

	print("\n3. Checking GlobalGameManager properties...")
	for prop in GlobalGameManager.get_property_list():
		if prop.name == "mainplate":
			var value = GlobalGameManager.get(prop.name)
			print("[DEBUG]    Found mainplate property: ", value != null)
			if value != null:
				print("[DEBUG]    - Mainplate exists!")
			break

	print("[DEBUG] \n4. Looking for UI components in scene tree...")
	var count = 0
	for node in get_tree().get_nodes_in_group("*"):
		var node_name = node.name if node.name else "unnamed"
		var script_path = ""
		if node.get_script():
			script_path = node.get_script().resource_path

		if "mainplate" in node_name.to_lower() or "mainplate" in script_path.to_lower():
			print("[DEBUG]    Found mainplate-related node: ", node_name, " [", script_path, "]")

			# Check for gear_slots property
			if node.has("gear_slots"):
				var slots = node.get("gear_slots")
				if slots is Dictionary:
					print("[DEBUG]      - Has gear_slots dictionary with ", slots.size(), " entries")

					# Check slot states
					var active = 0
					var inactive = 0
					for pos in slots:
						var slot = slots[pos]
						if slot.has("is_active_slot"):
							if slot.is_active_slot:
								active += 1
							else:
								inactive += 1
					print("[DEBUG]      - Active slots: ", active, ", Inactive slots: ", inactive)

			count += 1

	if count == 0:
		print("[DEBUG]    No mainplate nodes found in scene")

	print("\n5. Checking GlobalSignals connections...")
	var activation_connected = false
	for sig in GlobalSignals.get_signal_list():
		if sig.name == "ui_execute_selected_onto_hovered":
			var connections = GlobalSignals.get_signal_connection_list("ui_execute_selected_onto_hovered")
			print("[DEBUG]    ui_execute_selected_onto_hovered has ", connections.size(), " connections")
			activation_connected = connections.size() > 0
			break

	if activation_connected:
		print("   ✓ Activation signal has connections")
	else:
		print("   ✗ Activation signal has NO connections")

	print("\n=== TEST COMPLETE ===\n")

	# Stay alive for manual testing
	await get_tree().create_timer(10.0).timeout
	print("Test timeout reached")