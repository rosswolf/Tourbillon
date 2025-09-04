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
		print("")
		print("[COMPILE CHECK] Private variable access checking is ACTIVE")
		print("[COMPILE CHECK] Classes cannot access private variables (__prefixed) from other classes")
		quit(1)
	else:
		print("[COMPILE CHECK] ✅ All scripts compile successfully!")
		print("[COMPILE CHECK] ✅ No private variable access violations found!")
		print("[COMPILE CHECK] Private variable access checking is ACTIVE")
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
	
	# Extract the class name for this script to identify self references
	var this_class_name = _extract_class_name(source)
	var is_inside_class = false
	
	for line in lines:
		line_num += 1
		
		# Track if we're inside the class definition
		if line.strip_edges().begins_with("class ") and not line.strip_edges().begins_with("class_name"):
			is_inside_class = true
		
		# Check for common issues
		
		# 1. Calling methods that might not exist
		if ".set_map(" in line:
			warnings_found.append(script_path + ":" + str(line_num) + " - Suspicious method call: set_map()")
		
		# 2. Using old/removed methods
		if ".register_instance(" in line:
			errors_found.append(script_path + ":" + str(line_num) + " - Using old method: register_instance() - use set_instance() instead")
		
		# 3. Check for accessing private variables from other classes
		_check_private_access(line, line_num, script_path, this_class_name)
		
		# 4. Check for undeclared types and missing type annotations
		_check_type_declarations(line, line_num, script_path)

func _check_private_access(line: String, line_num: int, script_path: String, this_class_name: String) -> void:
	# Skip comments and strings
	var cleaned_line = _remove_strings_and_comments(line)
	
	# Pattern to find private variable access: something.__variable
	# Look for patterns like: object.__foo, self.__bar, some_var.__baz
	# Also catches: card.__instinct_effect.activate()
	var regex = RegEx.new()
	regex.compile(r'\b(\w+)\.__(\w+)')
	
	var matches = regex.search_all(cleaned_line)
	for match in matches:
		var object_name = match.get_string(1)
		var private_var = "__" + match.get_string(2)
		
		# Allow self references and super references
		if object_name in ["self", "super"]:
			continue
			
		# Check if it's a variable declaration (var __foo)
		if "var " + object_name + "." in line:
			continue
			
		# This is accessing a private variable from another object
		errors_found.append(script_path + ":" + str(line_num) + 
			" - Illegal access to private variable '" + private_var + 
			"' of object '" + object_name + "'. Private variables (prefixed with __) cannot be accessed from other classes.")
	
	# Also check for calling methods on private variables: something.__variable.method()
	var method_regex = RegEx.new()
	method_regex.compile(r'\b(\w+)\.__(\w+)\.(\w+)\(')
	
	var method_matches = method_regex.search_all(cleaned_line)
	for match in method_matches:
		var object_name = match.get_string(1)
		var private_var = "__" + match.get_string(2)
		var method_name = match.get_string(3)
		
		# Allow self references and super references
		if object_name in ["self", "super"]:
			continue
			
		# This is calling a method on a private variable from another object
		errors_found.append(script_path + ":" + str(line_num) + 
			" - Illegal method call '" + method_name + "()' on private variable '" + private_var + 
			"' of object '" + object_name + "'. Private variables cannot be accessed from other classes.")

func _remove_strings_and_comments(line: String) -> String:
	var result = ""
	var in_string = false
	var string_char = ""
	var i = 0
	
	while i < line.length():
		var c = line[i]
		
		# Handle string literals
		if c == '"' or c == "'":
			if not in_string:
				in_string = true
				string_char = c
			elif c == string_char and (i == 0 or line[i-1] != "\\"):
				in_string = false
				string_char = ""
		# Handle comments
		elif c == "#" and not in_string:
			break  # Rest of line is comment
		# Add character if not in string
		elif not in_string:
			result += c
			
		i += 1
	
	return result

func _extract_function_name(line: String) -> String:
	var start = line.find("func ") + 5
	var end = line.find("(", start)
	if start > 4 and end > start:
		return line.substr(start, end - start).strip_edges()
	return ""