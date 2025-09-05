extends SceneTree

const MAINPLATE = preload("res://src/scenes/ui/mainplate/mainplate.gd")
const GRID_MAPPER = preload("res://src/scenes/ui/mainplate/grid_mapper.gd")

func _init():
	print("\n=== Testing Mainplate Visual Setup ===\n")

	# Test the grid mapper directly
	var mapper = GridMapper.new(Vector2i(4, 4), Vector2i(8, 8))
	print("[DEBUG] Grid Mapper Setup:")
	print("[DEBUG]   Logical size: ", mapper.get_logical_size())
	print("[DEBUG]   Physical size: ", mapper.get_physical_size())
	print("[DEBUG]   Offset: ", mapper.offset)

	# Check which positions should be active
	print("[DEBUG] \nActive physical positions (centered 4x4):")
	var active = mapper.get_active_physical_positions()
	for pos in active:
		print("[DEBUG]   ", pos)

	print("[DEBUG] \nExpected active area:")
	print("[DEBUG]   Top-left: (2,2)")
	print("[DEBUG]   Top-right: (5,2)")
	print("[DEBUG]   Bottom-left: (2,5)")
	print("[DEBUG]   Bottom-right: (5,5)")

	# Test slot states
	print("\nTesting position checks:")
	for y in range(8):
		var row_str = "  Row %d: " % y
		for x in range(8):
			var pos = Vector2i(x, y)
			if mapper.is_active_physical(pos):
				row_str += "[X]"
			else:
				row_str += "[ ]"
		print("[DEBUG] " + str(row_str))

	print("\n=== Visual Test Complete ===\n")
	quit()