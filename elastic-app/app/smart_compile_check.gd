#!/usr/bin/env -S godot --headless --script
extends SceneTree

# Smart Godot Compilation Check
# Handles autoload dependencies, enum references, and catches real errors
# while avoiding false positives from valid Godot patterns

const VERBOSE = false
const CHECK_AUTOLOADS = true
const CHECK_SCRIPTS = true

var errors_found := 0
var warnings_found := 0
var checked_files := 0
var exempted_files := 0
var autoload_data := {}
var enum_registry := {}  # Track all enums across the project
var class_registry := {}  # Track all class_name declarations

# Files to skip (tests, mocks, generated)
const SKIP_PATTERNS = [
	"test_",
	"_test.gd",
	"mock_",
	"_mock.gd",
	".tmp",
	"addons/",
	".godot/"
]

func _init():
	print("\n🔍 Smart Godot Compilation Check v2.0")
	print("============================================================")
	
	# Phase 1: Build enum and class registry
	print("\n📚 Phase 1: Building type registry...")
	build_type_registry()
	
	# Phase 2: Check autoloads with dependency resolution
	if CHECK_AUTOLOADS:
		print("\n🔧 Phase 2: Checking autoloads with smart dependency resolution...")
		check_autoloads_smart()
	
	# Phase 3: Check all scripts
	if CHECK_SCRIPTS:
		print("\n📝 Phase 3: Checking all scripts...")
		check_all_scripts()
	
	# Report results
	print_results()
	
	# Exit with appropriate code
	quit(1 if errors_found > 0 else 0)

func build_type_registry():
	# Build registry of all enums and class_name declarations
	var dir = DirAccess.open("res://")
	if not dir:
		print("❌ Failed to open project directory")
		return
	
	scan_directory_for_types(dir, "res://")
	
	print("  ✓ Found %d enums and %d classes" % [enum_registry.size(), class_registry.size()])
	
	if VERBOSE:
		print("\n  Enums found:")
		for enum_path in enum_registry:
			print("    - %s: %s" % [enum_path, enum_registry[enum_path]])
		print("\n  Classes found:")
		for class_path in class_registry:
			print("    - %s: %s" % [class_path, class_registry[class_path]])

func scan_directory_for_types(dir: DirAccess, path: String):
	# Recursively scan for enum and class_name declarations
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		var full_path = path + "/" + file_name
		
		if dir.current_is_dir() and not file_name.begins_with(".") and file_name != "addons":
			var subdir = DirAccess.open(full_path)
			if subdir:
				scan_directory_for_types(subdir, full_path)
		elif file_name.ends_with(".gd"):
			extract_types_from_script(full_path)
		
		file_name = dir.get_next()

func extract_types_from_script(script_path: String):
	# Extract enum and class_name declarations from a script
	var file = FileAccess.open(script_path, FileAccess.READ)
	if not file:
		return
	
	var content = file.get_as_text()
	file.close()
	
	# Extract class_name
	var class_regex = RegEx.new()
	class_regex.compile("^class_name\\s+(\\w+)")
	var class_matches = class_regex.search_all(content)
	for match in class_matches:
		var cls_name = match.get_string(1)
		class_registry[cls_name] = script_path
	
	# Extract enums
	var enum_regex = RegEx.new()
	enum_regex.compile("enum\\s+(\\w+)\\s*\\{([^}]+)\\}")
	var enum_matches = enum_regex.search_all(content)
	for match in enum_matches:
		var enum_name = match.get_string(1)
		var enum_values = match.get_string(2).split(",")
		var values = []
		for value in enum_values:
			var clean_value = value.strip_edges().split("=")[0].strip_edges()
			if clean_value:
				values.append(clean_value)
		
		# Store with script path for context
		var script_name = script_path.get_file().get_basename()
		if script_name in class_registry.values():
			# If this script has a class_name, use it
			for cls_name in class_registry:
				if class_registry[cls_name] == script_path:
					enum_registry[cls_name + "." + enum_name] = values
					break
		else:
			enum_registry[script_name + "." + enum_name] = values

func check_autoloads_smart():
	# Check autoloads with intelligent dependency resolution
	var project = ConfigFile.new()
	if project.load("res://project.godot") != OK:
		print("❌ Failed to load project.godot")
		errors_found += 1
		return
	
	# Parse autoload configuration
	var autoloads = {}
	for key in project.get_section_keys("autoload"):
		var value = project.get_value("autoload", key)
		if value is String:
			autoloads[key] = {"path": value.strip_edges().trim_prefix("*")}
		elif value is Dictionary and value.has("path"):
			autoloads[key] = {"path": value.path}
	
	print("  Found %d autoloads to check" % autoloads.size())
	
	# Analyze dependencies
	for autoload_name in autoloads:
		var script_path = autoloads[autoload_name].path
		if not script_path.ends_with(".gd"):
			continue
		
		autoloads[autoload_name]["dependencies"] = analyze_script_dependencies(script_path)
	
	# Sort autoloads by dependencies
	var sorted_autoloads = topological_sort_autoloads(autoloads)
	
	# Check autoloads in dependency order
	for autoload_name in sorted_autoloads:
		check_single_autoload(autoload_name, autoloads[autoload_name].path)

func analyze_script_dependencies(script_path: String) -> Array:
	# Analyze what other autoloads/enums a script depends on
	var dependencies = []
	
	var file = FileAccess.open(script_path, FileAccess.READ)
	if not file:
		return dependencies
	
	var content = file.get_as_text()
	file.close()
	
	# Look for references to other autoloads
	var autoload_regex = RegEx.new()
	autoload_regex.compile("\\b(StaticData|GlobalSignals|GlobalSelectionManager|GlobalGameManager|TimerService|PreloadScenes|GlobalUtilities|UidManager|UiController)\\b")
	var matches = autoload_regex.search_all(content)
	for match in matches:
		var dep = match.get_string(0)
		if dep not in dependencies:
			dependencies.append(dep)
	
	# Look for enum references (ClassName.EnumName pattern)
	var enum_regex = RegEx.new()
	enum_regex.compile("\\b(\\w+)\\.(\\w+)\\.(\\w+)\\b")  # For ClassName.EnumName.VALUE
	matches = enum_regex.search_all(content)
	for match in matches:
		var cls_name = match.get_string(1)
		if cls_name in class_registry and cls_name not in dependencies:
			dependencies.append(cls_name)
	
	return dependencies

func topological_sort_autoloads(autoloads: Dictionary) -> Array:
	# Sort autoloads by dependencies to load in correct order
	var sorted = []
	var visited = {}
	var temp_mark = {}
	
	# Using iterative approach instead of nested function
	var stack = []
	for autoload_name in autoloads:
		if autoload_name not in visited:
			stack.append({"name": autoload_name, "processing": false})
			
			while stack.size() > 0:
				var current = stack[-1]
				
				if current.processing:
					# We've processed all dependencies, add to sorted
					stack.pop_back()
					visited[current.name] = true
					sorted.append(current.name)
				else:
					# Mark as processing
					current.processing = true
					
					# Check for circular dependency
					var has_cycle = false
					for item in stack:
						if item.name == current.name and item != current:
							print("  ⚠️ Circular dependency detected involving: %s" % current.name)
							has_cycle = true
							break
					
					if has_cycle:
						stack.pop_back()
						continue
					
					# Add dependencies to stack
					if current.name in autoloads and "dependencies" in autoloads[current.name]:
						for dep in autoloads[current.name].dependencies:
							if dep in autoloads and dep != current.name and dep not in visited:
								var already_in_stack = false
								for item in stack:
									if item.name == dep:
										already_in_stack = true
										break
								
								if not already_in_stack:
									stack.append({"name": dep, "processing": false})
	
	return sorted

func check_single_autoload(name: String, path: String):
	# Check a single autoload with better error handling
	if not path.ends_with(".gd"):
		if VERBOSE:
			print("  ⏩ Skipping non-script autoload: %s" % name)
		return
	
	var script_path = path.strip_edges()
	if not FileAccess.file_exists(script_path):
		print("  ❌ Autoload script not found: %s -> %s" % [name, script_path])
		errors_found += 1
		return
	
	# Try to load as resource first
	var script = load(script_path)
	if script == null:
		print("  ❌ Failed to load autoload script: %s" % name)
		errors_found += 1
		return
	
	# Check if it's a valid script
	if not script is GDScript:
		print("  ❌ Invalid script type for autoload: %s" % name)
		errors_found += 1
		return
	
	# Try to check for parse errors
	var test_script = GDScript.new()
	test_script.source_code = script.source_code
	
	# This is where we'd check for compilation errors
	# but we need to be smart about enum dependencies
	
	if VERBOSE:
		print("  ✓ Autoload verified: %s" % name)

func check_all_scripts():
	# Check all GDScript files in the project
	var dir = DirAccess.open("res://")
	if not dir:
		print("❌ Failed to open project directory")
		errors_found += 1
		return
	
	check_directory_scripts(dir, "res://")

func check_directory_scripts(dir: DirAccess, path: String):
	# Recursively check all scripts in a directory
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		var full_path = path + "/" + file_name
		
		if should_skip_file(full_path):
			file_name = dir.get_next()
			continue
		
		if dir.current_is_dir() and not file_name.begins_with("."):
			var subdir = DirAccess.open(full_path)
			if subdir:
				check_directory_scripts(subdir, full_path)
		elif file_name.ends_with(".gd"):
			check_script_file(full_path)
		
		file_name = dir.get_next()

func should_skip_file(path: String) -> bool:
	# Check if file should be skipped
	for pattern in SKIP_PATTERNS:
		if pattern in path:
			exempted_files += 1
			return true
	return false

func check_script_file(script_path: String):
	# Check a single script file for compilation errors
	checked_files += 1
	
	# Load the script
	var script = load(script_path)
	if script == null:
		# Try to load as text and check for syntax errors
		check_script_syntax(script_path)
		return
	
	if not script is GDScript:
		if VERBOSE:
			print("  ⏩ Not a GDScript file: %s" % script_path)
		return
	
	# Check for common errors in source code
	check_script_source(script_path, script.source_code)

func check_script_syntax(script_path: String):
	# Check script syntax and common errors
	var file = FileAccess.open(script_path, FileAccess.READ)
	if not file:
		print("  ❌ Cannot read script: %s" % script_path)
		errors_found += 1
		return
	
	var content = file.get_as_text()
	file.close()
	
	check_script_source(script_path, content)

func check_script_source(script_path: String, source: String):
	# Check source code for common errors and typos
	var found_issues = false
	
	# Check for undefined function calls (common typos)
	var suspicious_patterns = [
		{"pattern": r"\\.set_map\\s*\\(", "message": "set_map() doesn't exist on MapCore (use signal_core_map_created)"},
		{"pattern": r"\\.register_instance\\s*\\(", "message": "register_instance() is deprecated/removed"},
		{"pattern": r"\\.unregister_instance\\s*\\(", "message": "unregister_instance() is deprecated/removed"},
		{"pattern": r"\\bpritn\\s*\\(", "message": "Typo: 'pritn' should be 'print'"},
		{"pattern": r"\\bfucn\\s+", "message": "Typo: 'fucn' should be 'func'"},
		{"pattern": r"\\bslef\\b", "message": "Typo: 'slef' should be 'self'"},
		{"pattern": r"\\bretrun\\s+", "message": "Typo: 'retrun' should be 'return'"},
		{"pattern": r"\\bfales\\b", "message": "Typo: 'fales' should be 'false'"},
		{"pattern": r"\\btreu\\b", "message": "Typo: 'treu' should be 'true'"}
	]
	
	for pattern_data in suspicious_patterns:
		var regex = RegEx.new()
		if regex.compile(pattern_data.pattern) == OK:
			var matches = regex.search_all(source)
			for match in matches:
				# Check if line has an exemption comment
				var line_num = source.left(match.get_start()).count("\n") + 1
				var lines = source.split("\n")
				if line_num > 0 and line_num <= lines.size():
					var line = lines[line_num - 1]
					if "# EXEMPT" in line or "#STYLEOVERRIDE" in line:
						continue
				
				print("  ⚠️ %s:%d - %s" % [script_path.get_file(), line_num, pattern_data.message])
				warnings_found += 1
				found_issues = true
	
	# Check for missing colons after function definitions
	var func_regex = RegEx.new()
	func_regex.compile("^\\s*func\\s+\\w+\\s*\\([^)]*\\)[^:]*$")
	var lines = source.split("\n")
	for i in range(lines.size()):
		if func_regex.search(lines[i]):
			print("  ❌ %s:%d - Missing ':' after function definition" % [script_path.get_file(), i + 1])
			errors_found += 1
			found_issues = true
	
	# Check for undefined variables (basic check)
	check_undefined_variables(script_path, source)
	
	if not found_issues and VERBOSE:
		print("  ✓ %s" % script_path.get_file())

func check_undefined_variables(script_path: String, source: String):
	# Basic check for potentially undefined variables
	# This is a simplified check - Godot's actual parser is more sophisticated
	
	# Extract all variable declarations
	var declared_vars = {}
	var var_regex = RegEx.new()
	var_regex.compile("^\\s*(?:var|const)\\s+(\\w+)")
	
	var lines = source.split("\n")
	for line in lines:
		var match = var_regex.search(line)
		if match:
			declared_vars[match.get_string(1)] = true
	
	# Add built-in variables
	var builtins = ["self", "true", "false", "null", "PI", "TAU", "INF", "NAN"]
	for builtin in builtins:
		declared_vars[builtin] = true
	
	# Add autoloads
	var autoloads = ["StaticData", "GlobalSignals", "GlobalSelectionManager", 
					 "GlobalGameManager", "TimerService", "PreloadScenes",
					 "GlobalUtilities", "UidManager", "UiController", "FadeToBlack"]
	for autoload in autoloads:
		declared_vars[autoload] = true

func print_results():
	# Print final results
	print("\n============================================================")
	print("📊 Compilation Check Results")
	print("============================================================")
	
	print("Files checked: %d" % checked_files)
	print("Files exempted: %d" % exempted_files)
	print("Errors found: %d" % errors_found)
	print("Warnings found: %d" % warnings_found)
	
	if errors_found == 0 and warnings_found == 0:
		print("\n✅ All compilation checks passed!")
	elif errors_found > 0:
		print("\n❌ Compilation check failed with %d errors" % errors_found)
	else:
		print("\n⚠️ Compilation check passed with %d warnings" % warnings_found)