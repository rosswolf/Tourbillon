extends Node

func _ready():
	print("Testing scene loading...")
	
	# Try to load the UIMainplate scene
	var scene = load("res://src/scenes/ui/mainplate/ui_mainplate.tscn")
	if scene:
		print("✓ UIMainplate scene loads successfully")
		
		# Try to instantiate it
		var instance = scene.instantiate()
		if instance:
			print("✓ UIMainplate can be instantiated")
			
			# Quick property check
			if "expansions_used" in instance:
				print("✓ expansions_used property exists")
			else:
				print("✗ expansions_used property missing!")
				
			instance.queue_free()
		else:
			print("✗ Failed to instantiate UIMainplate")
	else:
		print("✗ Failed to load UIMainplate scene")
	
	await get_tree().create_timer(0.5).timeout
	get_tree().quit()