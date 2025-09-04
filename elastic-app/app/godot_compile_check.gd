extends SceneTree

# Comprehensive Godot compilation check script
# This script verifies that all GDScript files compile and that
# method calls reference existing methods

var errors_found: Array[String] = []
var warnings_found: Array[String] = []

# Exemption configuration
var exemptions = {
	# Files that are completely exempt from all checks
	"fully_exempt_files": [
		# Add paths like "res://src/legacy/old_code.gd"
	],
	
	# Files exempt from type checking
	"type_check_exempt": [
		# Legacy files that haven't been migrated yet
		# "res://src/scenes/old_system.gd"
	],
	
	# Files exempt from private variable checks
	"private_var_exempt": [
		# Special cases where private access is needed
	],
	
	# Patterns in file paths to exempt (regex patterns)
	"path_patterns_exempt": [
		"test_",  # Test files often break rules intentionally
		"mock_",  # Mock objects might need special access
		"_generated",  # Generated code might not follow conventions
	],
	
	# Special comment markers that exempt the next line
	"line_exemption_markers": [
		"# EXEMPT: TYPE_CHECK",
		"# EXEMPT: PRIVATE_ACCESS",
		"# EXEMPT: ALL",
		"# @compile-check-ignore",
	]
}

func _init() -> void:
	print("[COMPILE CHECK] Starting comprehensive compilation check...")
	
	# Check for command line arguments for specific files
	var args: PackedStringArray = OS.get_cmdline_args()
	var specific_files: Array[String] = []
	
	for arg in args:
		if arg.ends_with(".gd") and FileAccess.file_exists(arg):
			specific_files.append(arg)
	
	if specific_files.size() > 0:
		print("[COMPILE CHECK] Checking specific files: ", specific_files)
		check_specific_files(specific_files)
	else:
		# Check all autoloads can be accessed
		check_autoloads()
		
		# Check all scripts compile
		check_all_scripts()
	
	# Report results
	if errors_found.size() > 0 or warnings_found.size() > 0:
		if errors_found.size() > 0:
			print("[COMPILE CHECK] ❌ ERRORS FOUND:")
			for error in errors_found:
				print("  " + error)
		
		if warnings_found.size() > 0:
			print("[COMPILE CHECK] ⚠️ WARNINGS:")
			for warning in warnings_found:
				print("  " + warning)
		
		print("")
		print("[COMPILE CHECK] Active checks:")
		print("  ✓ Private variable access protection (__prefixed variables)")
		print("  ✓ Type safety (all variables must have type annotations)")
		print("  ✓ Function signatures (parameters and return types required)")
		print("  ✓ Custom type validation")
		
		if errors_found.size() > 0:
			quit(1)
		else:
			print("[COMPILE CHECK] ⚠️ Warnings found but no errors - proceeding")
			quit(0)
	else:
		print("[COMPILE CHECK] ✅ All scripts compile successfully!")
		print("[COMPILE CHECK] ✅ No private variable access violations found!")
		print("[COMPILE CHECK] ✅ All type annotations present!")
		print("")
		print("[COMPILE CHECK] Active checks:")
		print("  ✓ Private variable access protection")
		print("  ✓ Type safety enforcement")
		print("  ✓ Function signature validation")
		quit(0)

func check_specific_files(files: Array[String]) -> void:
	print("[COMPILE CHECK] Checking ", files.size(), " specific file(s)...")
	
	for file_path in files:
		# Convert to res:// path if needed
		var res_path: String = file_path
		if not res_path.begins_with("res://"):
			# Try to convert absolute path to res:// path
			if file_path.contains("/src/"):
				res_path = "res://src/" + file_path.split("/src/")[1]
			elif file_path.contains("/app/"):
				res_path = "res://" + file_path.split("/app/")[1]
			else:
				res_path = "res://" + file_path.get_file()
		
		print("  Checking: ", res_path)
		_check_script(res_path)

func check_autoloads() -> void:
	print("[COMPILE CHECK] Checking autoloads...")
	
	# Check each autoload defined in project.godot
	var autoloads: Array[String] = [
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
	var src_dir: DirAccess = DirAccess.open("res://src")
	if src_dir != null:
		_check_directory_recursive(src_dir, "res://src")
	
	# Also check root level .gd files
	var root_dir: DirAccess = DirAccess.open("res://")
	if root_dir != null:
		root_dir.list_dir_begin()
		var file_name: String = root_dir.get_next()
		while file_name != "":
			if file_name.ends_with(".gd"):
				_check_script("res://" + file_name)
			file_name = root_dir.get_next()
		root_dir.list_dir_end()

func _check_directory_recursive(dir: DirAccess, path: String) -> void:
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	
	while file_name != "":
		var full_path: String = path + "/" + file_name
		
		if dir.current_is_dir() and not file_name.begins_with("."):
			var subdir: DirAccess = DirAccess.open(full_path)
			if subdir != null:
				_check_directory_recursive(subdir, full_path)
		elif file_name.ends_with(".gd"):
			_check_script(full_path)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()

func _check_script(script_path: String) -> void:
	# Check if file is fully exempt
	if _is_file_exempt(script_path, "fully_exempt_files"):
		print("  [EXEMPT] Skipping all checks for: " + script_path)
		return
	
	# Load and check the script
	var script: Script = load(script_path)
	
	if script == null:
		errors_found.append("Failed to load script: " + script_path)
		return
	
	# For class_name scripts, try to instantiate
	if script.has_source_code():
		var source: String = script.source_code
		
		# Check for class_name declaration
		if "class_name " in source:
			var extracted_class_name: String = _extract_class_name(source)
			if extracted_class_name != "":
				_try_instantiate_class(extracted_class_name, script_path)
		
		# Check for obvious errors in the source
		_check_source_for_errors(source, script_path)

func _extract_class_name(source: String) -> String:
	var lines: PackedStringArray = source.split("\n")
	for line in lines:
		if line.begins_with("class_name "):
			var parts: PackedStringArray = line.split(" ")
			if parts.size() >= 2:
				return parts[1].strip_edges()
	return ""

func _try_instantiate_class(class_name_str: String, script_path: String) -> void:
	# Skip certain classes that shouldn't be instantiated directly
	var skip_classes: Array[String] = [
		"EntityBuilder",
		"CardBuilder", 
		"HeroBuilder",
		"GremlinBuilder",
		"MainplateBuilder"
	]
	
	if class_name_str in skip_classes:
		return
	
	# Try to create instance using ClassDB or script
	var script: Script = load(script_path)
	if script != null and script.can_instantiate():
		var instance: Object = script.new()
		if instance == null:
			warnings_found.append("Could not instantiate: " + class_name_str + " (" + script_path + ")")
		else:
			if instance.has_method("queue_free"):
				instance.queue_free()

func _check_source_for_errors(source: String, script_path: String) -> void:
	var lines: PackedStringArray = source.split("\n")
	var line_num: int = 0
	var previous_line: String = ""
	
	# Extract the class name for this script to identify self references
	var this_class_name: String = _extract_class_name(source)
	var is_inside_class: bool = false
	
	for line in lines:
		line_num += 1
		
		# Check if previous line has an exemption marker
		var is_line_exempt: bool = _is_line_exempt(previous_line)
		
		# Track if we're inside the class definition
		if line.strip_edges().begins_with("class ") and not line.strip_edges().begins_with("class_name"):
			is_inside_class = true
		
		# Check for common issues
		
		# 1. Calling methods that might not exist
		if ".set_map(" in line and not is_line_exempt:
			warnings_found.append(script_path + ":" + str(line_num) + " - Suspicious method call: set_map()")
		
		# 2. Using old/removed methods
		if ".register_instance(" in line and not is_line_exempt:
			errors_found.append(script_path + ":" + str(line_num) + " - Using old method: register_instance() - use set_instance() instead")
		
		# 3. Check for accessing private variables from other classes
		if not _is_file_exempt(script_path, "private_var_exempt") and not is_line_exempt:
			_check_private_access(line, line_num, script_path, this_class_name)
		
		# 4. Check for undeclared types and missing type annotations
		if not _is_file_exempt(script_path, "type_check_exempt") and not is_line_exempt:
			_check_type_declarations(line, line_num, script_path)
		
		previous_line = line

func _check_private_access(line: String, line_num: int, script_path: String, this_class_name: String) -> void:
	# Skip comments and strings
	var cleaned_line: String = _remove_strings_and_comments(line)
	
	# Pattern to find private variable access: something.__variable
	# Look for patterns like: object.__foo, self.__bar, some_var.__baz
	# Also catches: card.__instinct_effect.activate()
	var regex: RegEx = RegEx.new()
	regex.compile(r'\b(\w+)\.__(\w+)')
	
	var matches: Array[RegExMatch] = regex.search_all(cleaned_line)
	for match_item in matches:
		var object_name: String = match_item.get_string(1)
		var private_var: String = "__" + match_item.get_string(2)
		
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
	var method_regex: RegEx = RegEx.new()
	method_regex.compile(r'\b(\w+)\.__(\w+)\.(\w+)\(')
	
	var method_matches: Array[RegExMatch] = method_regex.search_all(cleaned_line)
	for match_item in method_matches:
		var object_name: String = match_item.get_string(1)
		var private_var: String = "__" + match_item.get_string(2)
		var method_name: String = match_item.get_string(3)
		
		# Allow self references and super references
		if object_name in ["self", "super"]:
			continue
			
		# This is calling a method on a private variable from another object
		errors_found.append(script_path + ":" + str(line_num) + 
			" - Illegal method call '" + method_name + "()' on private variable '" + private_var + 
			"' of object '" + object_name + "'. Private variables cannot be accessed from other classes.")

func _remove_strings_and_comments(line: String) -> String:
	var result: String = ""
	var in_string: bool = false
	var string_char: String = ""
	var i: int = 0
	
	while i < line.length():
		var c: String = line[i]
		
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

func _check_type_declarations(line: String, line_num: int, script_path: String) -> void:
	var cleaned_line: String = _remove_strings_and_comments(line).strip_edges()
	
	# Skip empty lines and comments
	if cleaned_line.is_empty():
		return
	
	# 1. Check variable declarations for missing types
	if cleaned_line.begins_with("var ") or cleaned_line.begins_with("const "):
		_check_variable_type(cleaned_line, line_num, script_path)
	
	# 2. Check function signatures for missing types
	if cleaned_line.begins_with("func "):
		_check_function_types(cleaned_line, line_num, script_path)
	
	# 3. Check for usage of undeclared custom types
	_check_custom_type_usage(cleaned_line, line_num, script_path)

func _check_variable_type(line: String, line_num: int, script_path: String) -> void:
	# Pattern: var name = value (missing type)
	# Should be: var name: Type = value
	
	# Skip @export variables as they can infer type
	if line.contains("@export"):
		return
	
	# Skip @onready as they often infer from node paths
	if line.contains("@onready"):
		return
		
	var var_regex: RegEx = RegEx.new()
	# Look for var/const without type annotation
	var_regex.compile(r'^(var|const)\s+(\w+)\s*=')
	
	var match_result: RegExMatch = var_regex.search(line)
	if match_result:
		var var_name: String = match_result.get_string(2)
		# Check if there's a type annotation
		if not line.contains(var_name + ":"):
			errors_found.append(script_path + ":" + str(line_num) + 
				" - Variable '" + var_name + "' is missing type annotation. Should be: var " + 
				var_name + ": Type = value")
	
	# Also check for just declaration without initialization but missing type
	var_regex.compile(r'^(var|const)\s+(\w+)\s*$')
	var match_result2: RegExMatch = var_regex.search(line)
	if match_result2:
		var var_name: String = match_result2.get_string(2)
		errors_found.append(script_path + ":" + str(line_num) + 
			" - Variable '" + var_name + "' declared without type. Should be: var " + 
			var_name + ": Type")

func _check_function_types(line: String, line_num: int, script_path: String) -> void:
	var func_name: String = _extract_function_name(line)
	
	# Skip special Godot functions
	var godot_functions: Array[String] = [
		"_ready", "_init", "_process", "_physics_process", 
		"_input", "_unhandled_input", "_enter_tree", "_exit_tree",
		"_draw", "_gui_input", "_notification", "_to_string"
	]
	
	if func_name in godot_functions:
		return
	
	# Check for missing return type
	if not "-> " in line:
		errors_found.append(script_path + ":" + str(line_num) + 
			" - Function '" + func_name + "' is missing return type annotation. Add '-> Type' or '-> void'")
	
	# Extract and check parameters
	var param_start: int = line.find("(")
	var param_end: int = line.find(")")
	if param_start != -1 and param_end != -1:
		var params_str: String = line.substr(param_start + 1, param_end - param_start - 1)
		if not params_str.is_empty():
			_check_parameter_types(params_str, func_name, line_num, script_path)

func _check_parameter_types(params_str: String, func_name: String, line_num: int, script_path: String) -> void:
	var params: PackedStringArray = params_str.split(",")
	
	for param in params:
		param = param.strip_edges()
		if param.is_empty():
			continue
		
		# Skip variadic arguments
		if param == "...":
			continue
			
		# Check if parameter has type annotation
		if not ":" in param:
			var param_name: String = param.split("=")[0].strip_edges()  # Handle default values
			if not param_name.is_empty():
				errors_found.append(script_path + ":" + str(line_num) + 
					" - Parameter '" + param_name + "' in function '" + func_name + 
					"' is missing type annotation")

func _check_custom_type_usage(line: String, line_num: int, script_path: String) -> void:
	# List of known valid types (builtin + common custom types)
	var valid_types: Array[String] = [
		# Builtin types
		"int", "float", "bool", "String", "Vector2", "Vector3", "Vector2i", "Vector3i",
		"Color", "Rect2", "Transform2D", "Transform3D", "Basis", "Quaternion",
		"AABB", "Plane", "RID", "NodePath", "StringName", "Callable", "Signal",
		"Dictionary", "Array", "PackedByteArray", "PackedInt32Array", "PackedInt64Array",
		"PackedFloat32Array", "PackedFloat64Array", "PackedStringArray", "PackedVector2Array",
		"PackedVector3Array", "PackedColorArray", "Variant", "void", "null",
		
		# Node types
		"Node", "Node2D", "Node3D", "Control", "CanvasItem", "Viewport", "Window",
		"Label", "Button", "TextureRect", "Panel", "Container", "Timer", "Camera2D", "Camera3D",
		"Area2D", "Area3D", "CharacterBody2D", "CharacterBody3D", "RigidBody2D", "RigidBody3D",
		"Sprite2D", "Sprite3D", "AnimationPlayer", "AudioStreamPlayer", "AudioStreamPlayer2D",
		
		# Resource types  
		"Resource", "Texture2D", "Mesh", "Material", "Shader", "Script", "PackedScene",
		"AudioStream", "Font", "Theme", "Environment", "World2D", "World3D",
		
		# Allow some flexibility for custom classes - we'll detect if they're truly undefined
		# when the script fails to load
	]
	
	# Check for type declarations using undeclared types
	var type_regex: RegEx = RegEx.new()
	type_regex.compile(r':\s*([A-Z]\w+)')
	
	var matches: Array[RegExMatch] = type_regex.search_all(line)
	for match_item in matches:
		var type_name: String = match_item.get_string(1)
		
		# Skip if it's a known type
		if type_name in valid_types:
			continue
		
		# Skip if it's an inner class (ClassName.InnerClass)
		if "." in line and line.contains(type_name):
			continue
			
		# Check if it's a typed array or dictionary
		if line.contains("Array[" + type_name) or line.contains("Dictionary["):
			continue
		
		# This might be a custom class - issue a warning rather than error
		# since we can't know all custom classes without parsing all files
		warnings_found.append(script_path + ":" + str(line_num) + 
			" - Using type '" + type_name + "' - ensure this class is defined with class_name")

func _extract_function_name(line: String) -> String:
	var start: int = line.find("func ") + 5
	var end: int = line.find("(", start)
	if start > 4 and end > start:
		return line.substr(start, end - start).strip_edges()
	return ""

# Exemption helper functions
func _is_file_exempt(file_path: String, exemption_type: String) -> bool:
	# Check if file is in the specific exemption list
	if exemption_type in exemptions:
		var exempt_list: Array = exemptions[exemption_type]
		if file_path in exempt_list:
			return true
	
	# Check if file matches any exempt patterns
	for pattern in exemptions["path_patterns_exempt"]:
		if pattern in file_path:
			return true
	
	return false

func _is_line_exempt(line: String) -> bool:
	# Check if the line contains any exemption markers
	var upper_line: String = line.to_upper()
	for marker in exemptions["line_exemption_markers"]:
		if marker.to_upper() in upper_line:
			return true
	
	# Also check for inline exemption comments
	if "# EXEMPT" in upper_line or "# @compile-check-ignore" in line:
		return true
	
	return false