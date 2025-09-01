extends Node

class_name Air

enum AirColor {
	UNKNOWN,
	HEAT,        # Red (was PURPLE) - volatile, high output
	PRECISION,   # Blue (was BLUE) - stable, predictable
	MOMENTUM,    # Green (was GREEN) - builds over time
	BALANCE,     # White (NEW) - neutralizes extremes
	ENTROPY,     # Purple (NEW) - unpredictable, corrupting
	INSPIRATION, # Gold/Yellow (NEW) - creative energy for cards
	NONE
}

# Legacy aliases for backward compatibility
enum {
	PURPLE = AirColor.HEAT,
	BLUE = AirColor.PRECISION,
	GREEN = AirColor.MOMENTUM
}

static func getColor(airColor: AirColor):
	if airColor == AirColor.UNKNOWN:
		return Color.BLACK
	elif airColor == AirColor.HEAT:
		return Color("FF4444")  # Red
	elif airColor == AirColor.PRECISION:
		return Color("4EA8DE")  # Blue (keeping original)
	elif airColor == AirColor.MOMENTUM:
		return Color("72EFDD")  # Green (keeping original)
	elif airColor == AirColor.BALANCE:
		return Color("FFFFFF")  # White
	elif airColor == AirColor.ENTROPY:
		return Color("7400B8")  # Purple (using original purple)
	elif airColor == AirColor.INSPIRATION:
		return Color("FFD700")  # Gold
