extends Node




static var ICONS: Dictionary[String, PackedScene] = {
	"relic" = preload("res://src/scenes/ui/icons/relics/relic_icon.tscn"),
	"slot" = preload("res://src/scenes/ui/icons/slot_icons/slot_icon.tscn"),
	"targeting" = preload("res://src/scenes/ui/icons/targeting/targeting_icon.tscn")
}

static var NODES: Dictionary[String, PackedScene] = {
	"card_ui" = preload("res://src/scenes/ui/hand/card_ui.tscn")
}

static var CARD_BACKGROUND_UIDS: Dictionary[String, CompressedTexture2D] = {
	"blue_card" : preload("uid://cw88cktjnkuf6"),
	"green_card" :  preload("uid://cpp30g3tr3mri"),
	"purple_card" :  preload("uid://c0ef1wfij10wi")
}
