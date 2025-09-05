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

func __take_screenshot():
	screenshot_count += 1

	if screenshot_count == 1:
		__handle_first_screenshot()
	elif screenshot_count == 2:
		__handle_final_screenshot()

func __handle_first_screenshot():
	__capture_and_save("mainplate_initial.png")

	var mainplate = __find_mainplate_node()
	if mainplate:
		__inspect_mainplate(mainplate)
	else:
		print("[DEBUG] Could not find mainplate node")

func __handle_final_screenshot():
	__capture_and_save("mainplate_final.png")
	timer.stop()
	print("Test complete, exiting...")
	get_tree().quit()

func __capture_and_save(filename: String):
	print("[DEBUG] Taking screenshot...")
	var image = window.get_texture().get_image()
	image.save_png(filename)
	print("[DEBUG] Saved: ", filename)

func __find_mainplate_node():
	var mainplate = get_tree().get_first_node_in_group("mainplate")
	if not mainplate:
		mainplate = get_node_or_null("/root/Main/GameUI/Mainplate")
	return mainplate

func __inspect_mainplate(mainplate):
	print("[DEBUG] Found mainplate node")

	__check_occupied_slots(mainplate)
	__check_grid_mapper(mainplate)
	__check_gear_slots(mainplate)

func __check_occupied_slots(mainplate):
	if mainplate.has_method("get_occupied_slots"):
		var slots = mainplate.get_occupied_slots()
		print("[DEBUG] Occupied slots: ", slots.size())

func __check_grid_mapper(mainplate):
	if "grid_mapper" in mainplate:
		print("[DEBUG] Grid mapper logical size: ", mainplate.grid_mapper.get_logical_size())
		print("[DEBUG] Grid mapper offset: ", mainplate.grid_mapper.offset)

func __check_gear_slots(mainplate):
	if "gear_slots" not in mainplate:
		return

	print("[DEBUG] Total gear slots: ", mainplate.gear_slots.size())

	var checked = 0
	for pos in mainplate.gear_slots:
		if checked >= 3:
			break
		__inspect_single_slot(pos, mainplate.gear_slots[pos])
		checked += 1

func __inspect_single_slot(pos, slot):
	var is_active = slot.get_meta("is_active", null)
	print("[DEBUG] Slot at ", pos, " active: ", is_active)

	__check_slot_stylebox(slot)

func __check_slot_stylebox(slot):
	var stylebox = slot.get_theme_stylebox("normal")
	if stylebox and stylebox is StyleBoxFlat:
		print("[DEBUG]   Border color: ", stylebox.border_color)
		print("[DEBUG]   Border width: ", stylebox.get_border_width(SIDE_TOP))

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			get_tree().quit()