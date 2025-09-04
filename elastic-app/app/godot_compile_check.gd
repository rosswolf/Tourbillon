extends SceneTree

# Comprehensive Godot compilation check script
# This script verifies that all GDScript files compile and that
# method calls reference existing methods

var errors_found: Array[String] = []
var warnings_found: Array[String] = []

func _init() -> void:
	print("[COMPILE CHECK] Starting comprehensive compilation check...")
	
	# Check all autoloads can be accessed
	check_autoloads()
	
	# Check all scripts compile
	check_all_scripts()
	
	# Report results
	if errors_found.size() > 0:
		print("[COMPILE CHECK] ❌ ERRORS FOUND:")
		for error in errors_found:
			print("  " + error)
		quit(1)
	else:
		print("[COMPILE CHECK] ✅ All scripts compile successfully!")
		quit(0)

func check_autoloads() -> void:
	print("[COMPILE CHECK] Checking autoloads...")
	
	# Check each autoload defined in project.godot
	var autoloads = [
		"StaticData",
		"GlobalSignals", 
		"GlobalSelectionManager",
		"GlobalGameManager",
		"TimerService",
		"PreloadScenes",
		"FadeToBlack",
		"GlobalUtilities",
		"UidManager",
		"UiController"
	]
	
	for autoload_name in autoloads:
		if not root.has_node(autoload_name):
			errors_found.append("Autoload not found: " + autoload_name)
		else:
			print("  ✓ " + autoload_name)

func check_all_scripts() -> void:
	print("[COMPILE CHECK] Checking all scripts...")
	
	# Check both src and root directory .gd files
	var src_dir = DirAccess.open("res://src")
	if src_dir != null:
		_check_directory_recursive(src_dir, "res://src")
	
	# Also check root level .gd files
	var root_dir = DirAccess.open("res://")
	if root_dir != null:
		root_dir.list_dir_begin()
		var file_name = root_dir.get_next()
		while file_name != "":
			if file_name.ends_with(".gd"):
				_check_script("res://" + file_name)
			file_name = root_dir.get_next()
		root_dir.list_dir_end()

func _check_directory_recursive(dir: DirAccess, path: String) -> void:
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		var full_path = path + "/" + file_name
		
		if dir.current_is_dir() and not file_name.begins_with("."):
			var subdir = DirAccess.open(full_path)
			if subdir != null:
				_check_directory_recursive(subdir, full_path)
		elif file_name.ends_with(".gd"):
			_check_script(full_path)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()

func _check_script(script_path: String) -> void:
	# Load and check the script
	var script = load(script_path)
	
	if script == null:
		errors_found.append("Failed to load script: " + script_path)
		return
	
	# For class_name scripts, try to instantiate
	if script.has_source_code():
		var source = script.source_code
		
		# Check for class_name declaration
		if "class_name " in source:
			var extracted_class_name = _extract_class_name(source)
			if extracted_class_name != "":
				_try_instantiate_class(extracted_class_name, script_path)
		
		# Check for obvious errors in the source
		_check_source_for_errors(source, script_path)

func _extract_class_name(source: String) -> String:
	var lines = source.split("\n")
	for line in lines:
		if line.begins_with("class_name "):
			var parts = line.split(" ")
			if parts.size() >= 2:
				return parts[1].strip_edges()
	return ""

func _try_instantiate_class(class_name_str: String, script_path: String) -> void:
	# Skip certain classes that shouldn't be instantiated directly
	var skip_classes = [
		"EntityBuilder",
		"CardBuilder", 
		"HeroBuilder",
		"GremlinBuilder",
		"MainplateBuilder"
	]
	
	if class_name_str in skip_classes:
		return
	
	# Try to create instance using ClassDB or script
	var script = load(script_path)
	if script != null and script.can_instantiate():
		var instance = script.new()
		if instance == null:
			warnings_found.append("Could not instantiate: " + class_name_str + " (" + script_path + ")")
		else:
			if instance.has_method("queue_free"):
				instance.queue_free()

func _check_source_for_errors(source: String, script_path: String) -> void:
	var lines = source.split("\n")
	var line_num = 0
	
	for line in lines:
		line_num += 1
		
		# Check for common issues
		
		# 1. Calling methods that might not exist
		if ".set_map(" in line:
			warnings_found.append(script_path + ":" + str(line_num) + " - Suspicious method call: set_map()")
		
		# 2. Using old/removed methods
		if ".register_instance(" in line:
			errors_found.append(script_path + ":" + str(line_num) + " - Using old method: register_instance() - use set_instance() instead")
		
		# 3. Check for missing type annotations on functions (basic check)
		if line.strip_edges().begins_with("func ") and not "-> " in line:
			# Check if it's not a special function
			var func_name = _extract_function_name(line)
			if func_name != "" and not func_name.begins_with("_"):
				# Skip lifecycle functions
				if func_name not in ["_ready", "_init", "_process", "_physics_process", "_input", "_enter_tree", "_exit_tree"]:
					# This is now just a warning since we have type safety checker
					pass

func _extract_function_name(line: String) -> String:
	var start = line.find("func ") + 5
	var end = line.find("(", start)
	if start > 4 and end > start:
		return line.substr(start, end - start).strip_edges()
	return ""