extends Node

var window: Window
var timer: Timer
var screenshot_count: int = 0

func _ready():
	print("Starting mainplate visual test...")
	
	# Get the main window
	window = get_window()
	window.size = Vector2(1280, 720)
	
	# Start the game
	GlobalSignals.ui_started_game.emit()
	
	# Create a timer for delayed screenshots
	timer = Timer.new()
	add_child(timer)
	timer.wait_time = 0.5
	timer.timeout.connect(_take_screenshot)
	timer.one_shot = false
	timer.start()

func _take_screenshot():
	screenshot_count += 1
	
	if screenshot_count == 1:
		print("Taking initial screenshot...")
		var image = window.get_texture().get_image()
		image.save_png("mainplate_initial.png")
		print("Saved: mainplate_initial.png")
		
		# Try to find and inspect the mainplate
		var mainplate = get_tree().get_first_node_in_group("mainplate")
		if not mainplate:
			# Try alternative search
			mainplate = get_node_or_null("/root/Main/GameUI/Mainplate")
		
		if mainplate:
			print("Found mainplate node")
			if mainplate.has_method("get_occupied_slots"):
				var slots = mainplate.get_occupied_slots()
				print("Occupied slots: ", slots.size())
			
			# Check grid mapper
			if "grid_mapper" in mainplate:
				print("Grid mapper logical size: ", mainplate.grid_mapper.get_logical_size())
				print("Grid mapper offset: ", mainplate.grid_mapper.offset)
				
			# Check gear slots
			if "gear_slots" in mainplate:
				print("Total gear slots: ", mainplate.gear_slots.size())
				
				# Check a few slots
				var checked = 0
				for pos in mainplate.gear_slots:
					if checked >= 3:
						break
					var slot = mainplate.gear_slots[pos]
					var is_active = slot.get_meta("is_active", null)
					print("Slot at ", pos, " active: ", is_active)
					
					# Check if slot has styleboxes
					var stylebox = slot.get_theme_stylebox("normal")
					if stylebox and stylebox is StyleBoxFlat:
						print("  Border color: ", stylebox.border_color)
						print("  Border width: ", stylebox.get_border_width(SIDE_TOP))
					checked += 1
		else:
			print("Could not find mainplate node")
			
	elif screenshot_count == 2:
		print("Taking final screenshot...")
		var image = window.get_texture().get_image()
		image.save_png("mainplate_final.png")
		print("Saved: mainplate_final.png")
		timer.stop()
		
		# Exit after screenshots
		print("Test complete, exiting...")
		get_tree().quit()

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			get_tree().quit()