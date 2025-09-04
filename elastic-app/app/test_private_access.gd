extends Node

class_name TestPrivateAccess

# Private variables - should only be accessed within this class
var __private_data: int = 42
var __secret_value: String = "hidden"

# Public variable
var public_data: int = 100

func valid_internal_access() -> void:
	# This is OK - accessing own private variables
	print(self.__private_data)
	self.__secret_value = "modified"
	__private_data = 50  # Also OK without self

func get_private_data() -> int:
	# Proper way to expose private data
	return __private_data

class TestViolation:
	func violate_privacy(obj: TestPrivateAccess) -> void:
		# VIOLATION: Accessing private variable from another object
		print(obj.__private_data)  # This should be caught!
		obj.__secret_value = "hacked"  # This should also be caught!
		
		# This is OK - using public interface
		print(obj.public_data)
		print(obj.get_private_data())