extends Node

func _ready():
	print("Checking if UIMainplate compiles correctly...")

	# Try to instantiate UIMainplate to verify it compiles
	var test_mainplate = UIMainplate.new()

	# Check that all expected properties exist
	var has_errors = false

	# Check exported properties
	if not "max_display_size" in test_mainplate:
		print("ERROR: max_display_size property missing")
		has_errors = true

	if not "initial_grid_size" in test_mainplate:
		print("ERROR: initial_grid_size property missing")
		has_errors = true

	if not "max_expansions" in test_mainplate:
		print("ERROR: max_expansions property missing")
		has_errors = true

	# Check regular properties
	if not "expansions_used" in test_mainplate:
		print("ERROR: expansions_used property missing")
		has_errors = true

	if not "gear_slots" in test_mainplate:
		print("ERROR: gear_slots property missing")
		has_errors = true

	if not has_errors:
		print("✓ UIMainplate compiles successfully with all required properties!")
	else:
		print("✗ UIMainplate has missing properties")

	# Clean up
	test_mainplate.queue_free()

	# Exit
	get_tree().quit(0 if not has_errors else 1)