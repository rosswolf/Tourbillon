extends Node
class_name TourbillonInitializer

## Initializes and wires up all Tourbillon systems
## This should be added to the main game scene or called during startup

@export var enable_tourbillon_mode: bool = true
@export var starting_deck_size: int = 15
@export var starting_hand_size: int = 5

var tourbillon_manager: TourbillonGameManager

func _ready() -> void:
	if not enable_tourbillon_mode:
		return
	
	print("Initializing Tourbillon systems...")
	
	# Initialize the Tourbillon game manager
	_setup_tourbillon_manager()
	
	# Load card data
	_load_tourbillon_cards()
	
	# Setup starting deck
	_setup_starting_deck()
	
	# Initialize UI connections
	_setup_ui_connections()
	
	print("Tourbillon systems initialized")

func _setup_tourbillon_manager() -> void:
	tourbillon_manager = TourbillonGameManager.new()
	add_child(tourbillon_manager)
	
	# Register in GlobalGameManager for access
	GlobalGameManager.set("tourbillon_manager", tourbillon_manager)

func _load_tourbillon_cards() -> void:
	# Load the Tourbillon card data
	var card_file = "res://data/tourbillon_cards.json"
	
	if not FileAccess.file_exists(card_file):
		push_warning("Tourbillon card data not found at: " + card_file)
		return
	
	var file = FileAccess.open(card_file, FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	
	if parse_result != OK:
		push_error("Failed to parse Tourbillon card data")
		return
	
	# Add to StaticData for Card.load_card to use
	var card_data = json.data
	for card_entry in card_data:
		var card_id = card_entry.get("card_template_id", "")
		if card_id:
			StaticData.card_data[card_id] = card_entry
	
	print("Loaded ", card_data.size(), " Tourbillon cards")

func _setup_starting_deck() -> void:
	if not GlobalGameManager.has("library"):
		push_warning("Library not found in GlobalGameManager")
		return
	
	var library = GlobalGameManager.get("library")
	
	# Create starting deck
	var starting_cards = [
		"basic_chronometer",
		"basic_chronometer",
		"simple_mainspring_heat",
		"simple_mainspring_heat",
		"simple_mainspring_precision",
		"simple_mainspring_precision",
		"force_converter"
	]
	
	# Add some random common cards to reach deck size
	var common_cards = [
		"micro_forge",
		"beast_cage",
		"precision_lathe",
		"micro_calibrator",
		"dust_accumulator"
	]
	
	while starting_cards.size() < starting_deck_size:
		var random_card = common_cards[randi() % common_cards.size()]
		starting_cards.append(random_card)
	
	# Load cards into library
	for card_id in starting_cards:
		var card = Card.load_card("tourbillon_base", card_id)
		if card:
			library.add_card_to_deck(card)
	
	# Shuffle deck
	library.shuffle_deck()
	
	# Draw starting hand
	for i in range(starting_hand_size):
		library.draw_card()
	
	print("Starting deck created with ", starting_cards.size(), " cards")

func _setup_ui_connections() -> void:
	# Connect UI elements to display time/tick information
	
	# Connect card play buttons to advance time
	GlobalSignals.ui_card_selected.connect(_on_card_selected)
	
	# Connect slot clicks to place cards
	GlobalSignals.ui_slot_clicked.connect(_on_slot_clicked)

func _on_card_selected(card_id: String) -> void:
	# This would be triggered when a card is selected from hand
	# The actual playing happens through existing systems
	print("Card selected: ", card_id)

func _on_slot_clicked(slot_id: String) -> void:
	# This would be triggered when a slot is clicked
	# The actual placement happens through existing systems
	print("Slot clicked: ", slot_id)

## Start a new game
func start_new_game() -> void:
	if tourbillon_manager:
		tourbillon_manager.reset_game()
	
	_setup_starting_deck()
	
	# Start the game unpaused
	if tourbillon_manager:
		tourbillon_manager.set_paused(false)
	
	print("New Tourbillon game started")

## Get the current tick
func get_current_tick() -> int:
	if tourbillon_manager:
		return tourbillon_manager.get_current_tick()
	return 0

## Get the current beat
func get_current_beat() -> int:
	if tourbillon_manager:
		return tourbillon_manager.get_current_beat()
	return 0