extends Node




static var ICONS: Dictionary[String, PackedScene] = {
	"slot" = preload("res://src/scenes/ui/icons/slot_icons/slot_icon.tscn"),
	"targeting" = preload("res://src/scenes/ui/icons/targeting/targeting_icon.tscn")
}

static var NODES: Dictionary[String, PackedScene] = {
	"card_ui" = preload("res://src/scenes/ui/hand/card_ui.tscn")
}


static var SCENES: Dictionary[String, PackedScene] = {
	"projectile" : preload("uid://egqb1rtxh7re")
}
