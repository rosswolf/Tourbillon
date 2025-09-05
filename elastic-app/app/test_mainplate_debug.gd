extends Node

## Debug test for mainplate card placement issues

var ui_mainplate_node = null

func _ready():
	print("\n=== MAINPLATE DEBUG TEST STARTING ===\n")

	await __initialize_test()
	await __run_all_tests()
	await __finish_test()

func __initialize_test():
	# Give scene time to load
	await get_tree().create_timer(1.0).timeout

	# Initialize game systems
	print("[DEBUG] 1. Initializing GlobalGameManager...")
	GlobalGameManager.hero_template_id = "champion"

	# Trigger game start
	print("2. Starting game...")
	GlobalSignals.ui_started_game.emit()

	# Wait for initialization
	await get_tree().create_timer(0.5).timeout

func __run_all_tests():
	__test_mainplate_entity()
	__test_ui_mainplate()
	__test_signal_connections()
	await __test_hover_registration()

func __finish_test():
	print("\n=== MAINPLATE DEBUG TEST COMPLETE ===\n")

	# Keep running for observation
	await get_tree().create_timer(3.0).timeout
	print("Test finished. You can now interact with the game.")

func __test_mainplate_entity():
	print("\n3. Checking mainplate entity...")
	if not GlobalGameManager.has("mainplate") or not GlobalGameManager.mainplate:
		print("   ✗ Mainplate entity NOT found!")
		return

	print("   ✓ Mainplate entity exists")
	var mp = GlobalGameManager.mainplate
	__print_mainplate_properties(mp)

func __print_mainplate_properties(mp):
	print("[DEBUG]    - Grid size: ", mp.get("grid_size") if mp.has("grid_size") else "N/A")
	print("[DEBUG]    - Max grid size: ", mp.get("max_grid_size") if mp.has("max_grid_size") else "N/A")

func __test_ui_mainplate():
	print("[DEBUG] \n4. Looking for UI mainplate in scene...")
	ui_mainplate_node = __find_ui_mainplate()

	if not ui_mainplate_node:
		print("   ✗ UIMainplate NOT found in scene!")
		return

	print("   ✓ Found UIMainplate node")
	__check_mainplate_references()
	__check_grid_mapper()
	__check_slot_states()

func __find_ui_mainplate():
	# Try group search first
	var nodes = get_tree().get_nodes_in_group("mainplate")
	if not nodes.is_empty():
		return nodes[0]

	# Try by class name
	for node in get_tree().get_nodes_in_group("*"):
		if node.get_class() == "UIMainplate":
			return node

	# Direct recursive search
	var found = __find_nodes_of_type(get_tree().root, "UIMainplate")
	if not found.is_empty():
		return found[0]

	return null

func __check_mainplate_references():
	print("[DEBUG]    - Has mainplate ref: ", ui_mainplate_node.mainplate != null)
	print("[DEBUG]    - Has grid_mapper: ", ui_mainplate_node.grid_mapper != null)

func __check_grid_mapper():
	if not ui_mainplate_node.grid_mapper:
		return

	var mapper = ui_mainplate_node.grid_mapper
	print("[DEBUG]    - GridMapper offset: ", mapper.offset)
	print("[DEBUG]    - GridMapper logical size: ", mapper.logical_size)
	print("[DEBUG]    - GridMapper physical size: ", mapper.physical_size)

	__check_active_positions(mapper)

func __check_active_positions(mapper):
	var active_positions = mapper.get_active_physical_positions()
	print("[DEBUG]    - Active physical positions (should be 16): ", active_positions.size())

	if active_positions.size() > 0:
		print("[DEBUG]    - First active position: ", active_positions[0])
		print("[DEBUG]    - Last active position: ", active_positions[-1])

func __check_slot_states():
	print("\n5. Checking slot states...")

	var slot_counts = __count_slot_states()
	__print_slot_counts(slot_counts)
	__print_sample_active_slots(slot_counts.active_positions)

func __count_slot_states() -> Dictionary:
	var active_slots = 0
	var inactive_slots = 0
	var active_positions = []

	for pos in ui_mainplate_node.gear_slots:
		var slot = ui_mainplate_node.gear_slots[pos]
		if slot.is_active_slot:
			active_slots += 1
			active_positions.append(pos)
		else:
			inactive_slots += 1

	return {
		"active": active_slots,
		"inactive": inactive_slots,
		"active_positions": active_positions
	}

func __print_slot_counts(counts: Dictionary):
	print("[DEBUG]    - Active slots: ", counts.active, " (should be 16)")
	print("[DEBUG]    - Inactive slots: ", counts.inactive, " (should be 48)")

func __print_sample_active_slots(active_positions: Array):
	if active_positions.is_empty():
		return

	print("[DEBUG] \n   Active slot positions:")
	var max_to_show = min(4, active_positions.size())
	for i in range(max_to_show):
		print("[DEBUG]      - Physical position ", active_positions[i], " is ACTIVE")

func __test_signal_connections():
	print("\n6. Checking signal connections...")

	var connected = GlobalSignals.ui_execute_selected_onto_hovered.is_connected(
		GlobalGameManager.__handle_activation
	)

	if connected:
		print("   ✓ Drop signal connected to GlobalGameManager")
	else:
		print("   ✗ Drop signal NOT connected!")

func __test_hover_registration():
	print("\n7. Testing slot hover registration...")
	await get_tree().create_timer(0.5).timeout

	if not ui_mainplate_node:
		print("   ✗ Cannot test hover - no mainplate found")
		return

	var test_slot = __find_active_slot()
	if not test_slot:
		print("   ✗ No active slots to test")
		return

	await __test_single_slot_hover(test_slot.slot, test_slot.pos)

func __find_active_slot() -> Dictionary:
	for pos in ui_mainplate_node.gear_slots:
		var slot = ui_mainplate_node.gear_slots[pos]
		if slot.is_active_slot:
			return {"slot": slot, "pos": pos}
	return {}

func __test_single_slot_hover(slot, pos):
	print("   Testing hover on active slot at ", pos)

	# Simulate hover
	slot._on_mouse_entered()
	await get_tree().create_timer(0.1).timeout

	__verify_hover_registration(slot)

	slot._on_mouse_exited()

func __verify_hover_registration(slot):
	var expected_id = slot.__button_entity.instance_id
	var actual_id = GlobalSelectionManager.get_hovered_instance_id()

	if actual_id == expected_id:
		print("   ✓ Slot hover registered correctly!")
	else:
		print("   ✗ Slot hover did NOT register")
		print("[DEBUG]    - Expected: ", expected_id)
		print("[DEBUG]    - Got: ", actual_id)

func __find_nodes_of_type(node: Node, type_name: String) -> Array:
	var found = []
	if node.get_class() == type_name:
		found.append(node)
	for child in node.get_children():
		found.append_array(__find_nodes_of_type(child, type_name))
	return found