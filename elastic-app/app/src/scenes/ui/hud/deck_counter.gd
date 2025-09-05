extends Control
class_name DeckCounter

@onready var deck_box: Panel = $HBoxContainer/DeckBox
@onready var deck_label: Label = $HBoxContainer/DeckBox/DeckLabel
@onready var graveyard_box: Panel = $HBoxContainer/GraveyardBox
@onready var graveyard_label: Label = $HBoxContainer/GraveyardBox/GraveyardLabel

var __deck_count: int = 0
var __graveyard_count: int = 0
var __is_exhausted: bool = false

func _ready() -> void:
	# Position in bottom left
	set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	position = Vector2(20, -100)
	
	# Connect to signals for updates
	GlobalSignals.core_card_drawn.connect(__on_card_drawn)
	GlobalSignals.core_card_played.connect(__on_card_played)
	GlobalSignals.core_card_discarded.connect(__on_card_discarded)
	GlobalSignals.core_deck_exhausted.connect(__on_deck_exhausted)
	
	# Initial update
	__update_counts()

func __on_card_drawn(_card_id: String) -> void:
	__update_counts()

func __on_card_played(_card_id: String) -> void:
	__update_counts()

func __on_card_discarded(_card_id: String) -> void:
	__update_counts()

func __on_deck_exhausted() -> void:
	__is_exhausted = true
	__update_visual_state()

func __update_counts() -> void:
	if GlobalGameManager.library:
		__deck_count = GlobalGameManager.library.deck.get_count()
		__graveyard_count = GlobalGameManager.library.graveyard.get_count()
	else:
		__deck_count = 0
		__graveyard_count = 0
	
	deck_label.text = str(__deck_count)
	graveyard_label.text = str(__graveyard_count)
	__update_visual_state()

func __update_visual_state() -> void:
	# Check if deck will be exhausted on next draw
	var will_exhaust: bool = __deck_count == 0 and __graveyard_count == 0
	
	if will_exhaust or __is_exhausted:
		# Turn red when empty
		deck_box.modulate = Color.RED
		if __graveyard_count == 0:
			graveyard_box.modulate = Color.RED
		else:
			graveyard_box.modulate = Color.WHITE
	else:
		# Normal colors
		deck_box.modulate = Color.WHITE
		graveyard_box.modulate = Color.WHITE