#!/usr/bin/env -S godot --headless --script

# Standalone test for the compile check hook
# Run with: godot --headless --script test_compile_hook.gd

extends SceneTree

func _init() -> void:
	print("Testing private variable access detection...")
	
	var test_source = """
extends Node
class_name TestClass

var __private_var: int = 42

func valid_self_access() -> void:
	print(self.__private_var)  # OK - self access
	__private_var = 50  # OK - implicit self

func violate_privacy(other: TestClass) -> void:
	print(other.__private_var)  # VIOLATION!
	other.__private_var = 100  # VIOLATION!
"""
	
	var errors = []
	_check_source(test_source, "test.gd", errors)
	
	if errors.size() > 0:
		print("✅ Successfully detected violations:")
		for error in errors:
			print("  " + error)
	else:
		print("❌ Failed to detect violations!")
		
	quit(0)

func _check_source(source: String, filename: String, errors: Array) -> void:
	var lines = source.split("\n")
	var line_num = 0
	
	for line in lines:
		line_num += 1
		_check_private_access(line, line_num, filename, "", errors)

func _check_private_access(line: String, line_num: int, script_path: String, this_class_name: String, errors: Array) -> void:
	var cleaned_line = _remove_strings_and_comments(line)
	
	# Look for pattern: something.__variable
	var regex = RegEx.new()
	regex.compile(r'\b(\w+)\.__(\w+)')
	
	var matches = regex.search_all(cleaned_line)
	for match in matches:
		var object_name = match.get_string(1)
		var private_var = "__" + match.get_string(2)
		
		# Allow self references
		if object_name in ["self", "super"]:
			continue
			
		# This is accessing a private variable from another object
		errors.append(script_path + ":" + str(line_num) + 
			" - Illegal access to private variable '" + private_var + 
			"' of object '" + object_name + "'")

func _remove_strings_and_comments(line: String) -> String:
	var result = ""
	var in_string = false
	var string_char = ""
	var i = 0
	
	while i < line.length():
		var c = line[i]
		
		if c == '"' or c == "'":
			if not in_string:
				in_string = true
				string_char = c
			elif c == string_char and (i == 0 or line[i-1] != "\\"):
				in_string = false
				string_char = ""
		elif c == "#" and not in_string:
			break
		elif not in_string:
			result += c
			
		i += 1
	
	return result