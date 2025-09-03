extends Node

func _ready():
	print("TEST_START")
	
	# Start game
	await get_tree().process_frame
	GlobalGameManager.hero_template_id = "champion"
	GlobalSignals.ui_started_game.emit()
	await get_tree().create_timer(1.0).timeout
	
	# Check mainplate
	var mainplate_ok = false
	for node in get_tree().get_nodes_in_group("mainplate"):
		if node.has("gear_slots"):
			var slots = node.get("gear_slots")
			if slots is Dictionary:
				var active = 0
				for pos in slots:
					var slot = slots[pos]
					if slot and slot.has("is_active_slot") and slot.is_active_slot:
						active += 1
				print("ACTIVE_SLOTS:", active)
				if active == 16:
					mainplate_ok = true
		break
	
	if mainplate_ok:
		print("SUCCESS:Mainplate_configured_correctly")
	else:
		print("FAILURE:Mainplate_not_working")
	
	# Exit quickly
	get_tree().quit()