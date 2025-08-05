extends Node

class_name Air

enum AirColor {
	UNKNOWN,
	PURPLE,
	GREEN,
	BLUE,
	NONE
}

static func getColor(airColor: AirColor):
	if airColor == AirColor.UNKNOWN:
		return Color.BLACK
	elif airColor == AirColor.PURPLE:
		return Color("7400B8")
	elif airColor == AirColor.BLUE:
		return Color("4EA8DE")
	elif airColor == AirColor.GREEN:
		return Color("72EFDD")
