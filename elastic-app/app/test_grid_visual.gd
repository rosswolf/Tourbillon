extends SceneTree

const Mainplate = preload("res://src/scenes/ui/mainplate/mainplate.gd")
const GridMapper = preload("res://src/scenes/ui/mainplate/grid_mapper.gd")

func _init():
	print("\n=== Testing Mainplate Visual Setup ===\n")
	
	# Test the grid mapper directly
	var mapper = GridMapper.new(Vector2i(4, 4), Vector2i(8, 8))
	print("Grid Mapper Setup:")
	print("  Logical size: ", mapper.get_logical_size())
	print("  Physical size: ", mapper.get_physical_size())
	print("  Offset: ", mapper.offset)
	
	# Check which positions should be active
	print("\nActive physical positions (centered 4x4):")
	var active = mapper.get_active_physical_positions()
	for pos in active:
		print("  ", pos)
	
	print("\nExpected active area:")
	print("  Top-left: (2,2)")
	print("  Top-right: (5,2)")
	print("  Bottom-left: (2,5)")
	print("  Bottom-right: (5,5)")
	
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
		print(row_str)
	
	print("\n=== Visual Test Complete ===\n")
	quit()