extends Node

class_name Air

enum AirColor {
	UNKNOWN,
	RED,
	ORANGE,
	BLUE,
	NONE
}

static func getColor(airColor: AirColor):
	if airColor == AirColor.UNKNOWN:
		return Color.BLACK
	elif airColor == AirColor.RED:
		return Color.RED
	elif airColor == AirColor.BLUE:
		return Color.BLUE
	elif airColor == AirColor.ORANGE:
		return Color.ORANGE_RED
