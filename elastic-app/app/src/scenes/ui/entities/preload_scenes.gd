extends Node

static var MOB_SPRITES = {
	"knight": preload("res://src/scenes/ui/entities/characters/sprites/heroes/knight.tres"),
	"goblin_scout": preload("res://src/scenes/ui/entities/characters/sprites/mobs/goblin_scout.tres"),
	"bar_goblin": preload("res://src/scenes/ui/entities/characters/sprites/mobs/bar_goblin.tres"),
	"noob_goblin": preload("res://src/scenes/ui/entities/characters/sprites/mobs/noob_goblin.tres"),
	"drunken_500_year_old":preload("res://src/scenes/ui/entities/characters/sprites/mobs/drunken_500_year_old.tres"),
	"zombie":preload("res://src/scenes/ui/entities/characters/sprites/mobs/zombie.tres")
}



static var ICONS: Dictionary[String, PackedScene] = {
	"relic" = preload("res://src/scenes/ui/icons/relics/relic_icon.tscn"),
	"slot" = preload("res://src/scenes/ui/icons/slot_icons/slot_icon.tscn"),
	"targeting" = preload("res://src/scenes/ui/icons/targeting/targeting_icon.tscn")
}

static var NODES: Dictionary[String, PackedScene] = {
	"card_ui" = preload("res://src/scenes/ui/hand/card_ui.tscn")
}
