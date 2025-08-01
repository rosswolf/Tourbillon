extends Resource
class_name Library

# Zones for cards
enum Zone {
	UNKNOWN,
	ANY, # Used to specify this can come from any zone.  
	RARE_LIBRARY,
	UNCOMMON_LIBRARY,
	COMMON_LIBRARY,
	DEFAULT_LIBRARY,
	DECK,
	HAND,
	BEING_PLAYED,
	GRAVEYARD, # Where cards go after being played (i.e. prevents the same rare card from showing up again)
	EXILED, # Removed from the game
	SLOTTED
}

# zone collection inner class
class ZoneCollection:
	var __cards: Array[Card] = []
	var __zone_type: int
	
	func _init(type: Zone):
		__zone_type = type
	
	# Add a card to this zone
	func add_card(card: Card):
		__cards.append(card)
	
	# Add an array of cards to this zone
	func add_cards(cards: Array[Card]):
		for card in cards:
			__cards.append(card)
		
	# Remove a card from this zone
	func remove_card(card_instance_id: String) -> Card:
		for i in range(__cards.size()):
			if __cards[i].instance_id == card_instance_id:
				var card = __cards[i]
				__cards.remove_at(i)
				return card
		return null
	
	# Get a card by instance ID
	func get_card(card_instance_id: String) -> Card:
		for card in __cards:
			if card.instance_id == card_instance_id:
				return card
		return null
	
	func get_all_cards() -> Array[Card]:
		return __cards.duplicate()
		
	# Check if this zone contains a card
	func contains_card(card_instance_id: String) -> bool:
		for card in __cards:
			if card.instance_id == card_instance_id:
				return true
		return false
	
	# Get all card IDs in this zone
	func get_all_card_ids() -> Array[String]:
		var ids: Array[String] = []
		for card in __cards:
			ids.append(card.instance_id)
		return ids
	
	# Get count of cards
	func get_count() -> int:
		return __cards.size()
	
	# Shuffle cards in this zone
	func shuffle():
		__cards.shuffle()
	
	# Get the top card without removing it
	func peek_top() -> Card:
		if __cards.size() > 0:
			return __cards[0]
		return null
	
	# Remove and return the top card
	func draw_top() -> Card:
		if __cards.size() > 0:
			var card = __cards[0]
			__cards.remove_at(0)
			return card
		return null
	
	# Get cards by template ID
	func get_cards_by_template(template_id: String) -> Array[Card]:
		var result: Array[Card] = []
		for card in __cards:
			if card.card_template_id == template_id:
				result.append(card)
		return result
		
	func clear():
		__cards = []


# Card zones
var rare_library: ZoneCollection
var uncommon_library: ZoneCollection
var common_library: ZoneCollection
var default_library: ZoneCollection
var deck: ZoneCollection
var hand: ZoneCollection
var being_played: ZoneCollection
var graveyard: ZoneCollection
var exiled: ZoneCollection
var slotted: ZoneCollection

# Card lookup for quick access
var card_zone_map: Dictionary = {}  # Maps card_instance_id to its current Zone

# State
var max_hand_size: int
var card_selection_count: int
var rare_chance: float
var uncommon_chance: float

var initial_rare_chance: float
var initial_uncommon_chance: float

# Signals

func _init():
	# Initialize all zones
	rare_library = ZoneCollection.new(Zone.RARE_LIBRARY)
	uncommon_library = ZoneCollection.new(Zone.UNCOMMON_LIBRARY)
	common_library = ZoneCollection.new(Zone.COMMON_LIBRARY)
	default_library = ZoneCollection.new(Zone.DEFAULT_LIBRARY)
	hand = ZoneCollection.new(Zone.HAND)
	being_played = ZoneCollection.new(Zone.BEING_PLAYED)
	graveyard = ZoneCollection.new(Zone.GRAVEYARD)
	deck = ZoneCollection.new(Zone.DECK)
	exiled = ZoneCollection.new(Zone.EXILED)
	slotted = ZoneCollection.new(Zone.SLOTTED)
	
	max_hand_size = StaticData.get_int("max_hand_size")
	card_selection_count =  StaticData.get_int("starting_card_selection_count")
	rare_chance =  StaticData.get_float("starting_rare_card_chance")
	initial_rare_chance = rare_chance
	uncommon_chance =  StaticData.get_float("starting_uncommon_card_chance")
	initial_uncommon_chance = uncommon_chance

# Initialize with a set of cards
func initialize_cards(rare_cards: Array[Card], uncommon_cards: Array[Card], 
		common_cards: Array[Card], default_cards: Array[Card], starting_cards: Array[Card]):
	clear_all_zones()
		
	for card in rare_cards:
		add_card_to_zone(card, Zone.RARE_LIBRARY)	
	for card in uncommon_cards:
		add_card_to_zone(card, Zone.UNCOMMON_LIBRARY)		
	for card in common_cards:
		add_card_to_zone(card, Zone.COMMON_LIBRARY)
	for card in default_cards:
		add_card_to_zone(card, Zone.DEFAULT_LIBRARY)
	
	add_cards_to_deck(starting_cards)
		
	shuffle_libraries()
	
func print_hand_size():
	print(hand.get_count())
	
	
	
# Add a new card to a specific zone
func add_card_to_zone(card: Card, zone: Zone):
	var zone_obj = _get_zone_object(zone)
	zone_obj.add_card(card)
	card_zone_map[card.instance_id] = zone
	

# Move a card from specified zone to its current zone.  
func move_card_to_zone(card_instance_id: String, new_zone: Zone, from_zone: Zone, override_limit: bool = false) -> bool:
	if not card_zone_map.has(card_instance_id):
		printerr(card_instance_id + " not in card_zone_map")
		return false
		
	# Get current zone
	var current_zone: Zone = card_zone_map[card_instance_id]
	var current_zone_obj = _get_zone_object(current_zone)
	
	if from_zone != Library.Zone.ANY and current_zone != from_zone:
		return false
	
	# Remove from current zone
	var card = current_zone_obj.remove_card(card_instance_id)
	if not card:
		printerr("failed to remove card " + card_instance_id)
		return false
	
	# Add to new zone
	var new_zone_obj = _get_zone_object(new_zone)
	if new_zone_obj.__zone_type == Zone.HAND and hand.get_count() >= max_hand_size and not override_limit:
		print("hit max hand size")
		return false
		
	new_zone_obj.add_card(card)
	
	# Update zone map
	card_zone_map[card_instance_id] = new_zone
	
	return true

func add_card_to_deck(card: Card) -> void:
	# Check if we're at max hand size
	#if hand.get_count() >= max_hand_size:
		#print("Attempted to draw card but at max hand size: %s" % [str(max_hand_size)])
		#GlobalSignals.core_max_hand_size_reached()
		#return null
	
	# Add to deck
	add_card_to_zone(card, Zone.DECK)
	#deck.add_card(card)
	#card_zone_map[card.instance_id] = Zone.DECK
	
# Add multiple cards
func add_cards_to_deck(cards: Array[Card]) -> void:
	for card in cards:
		add_card_to_deck(card)

func discard_hand():
	for card in hand.get_all_cards():
		move_card_to_zone(card.instance_id, Zone.GRAVEYARD, Zone.HAND)
		GlobalSignals.signal_core_card_removed_from_hand(card_instance_id)
		# for each card in hand, discard it.  
		
func draw_card(how_many: int):
	for i in range(how_many):
		if deck.get_count() == 0:
			for c in graveyard.get_all_cards():
				move_card_to_zone(c.instance_id, Zone.DECK, Zone.GRAVEYARD)
			deck.shuffle()
		
		var next_card: Card = deck.draw_top()
		if next_card:
			add_card_to_zone(next_card, Zone.HAND)
			
			GlobalSignals.signal_core_card_drawn(card_instance_id)
	
func draw_new_hand(desired_hand_size: int):
	discard_hand()
	
	if desired_hand_size > deck.get_count() + graveyard.get_count():
		desired_hand_size = deck.get_count() + graveyard.get_count()
		#assert(false, "not enough cards to draw the desired hand size " + str(hand_size))	
	
	draw_card(desired_hand_size)
	
func get_cards_for_selection() -> Array[Card]:	
	var selectable_cards: Array[Card] = []
	
	while selectable_cards.size() < card_selection_count:
		var roll = randf() # Random float between 0.0 and 1.0
		print("rare chance is: " + str(rare_chance))
		print("uncommon chance is: " + str(uncommon_chance))
		
		if roll < rare_chance and rare_library.get_count() > 0:
			var selected: Card = __get_card_for_selection(selectable_cards, rare_library)
			if selected != null: selectable_cards.append(selected)
			rare_chance = initial_rare_chance
			continue
			
		if roll < uncommon_chance and uncommon_library.get_count() > 0:
			var selected: Card = __get_card_for_selection(selectable_cards, uncommon_library)
			if selected != null: selectable_cards.append(selected)
			uncommon_chance = initial_uncommon_chance
			continue
			
		if common_library.get_count() == 0:
			# TODO: how to handle this edge case?
			printerr("Common library is empty when selecting a card (this should not happen)")
			
		selectable_cards.append(__get_card_for_selection(selectable_cards, common_library))
		rare_chance += 0.01
		uncommon_chance += 0.01
	
	return selectable_cards

func __get_card_for_selection(selectable_cards: Array[Card], card_library: ZoneCollection) -> Card:	
	var rejected_cards: Array[Card] = []
	var selected_card: Card = null
	
	while card_library.get_count() > 0:
		var candidate_card: Card = card_library.draw_top()

		if card_template_already_selected(candidate_card.template_id, selectable_cards): 
			rejected_cards.append(candidate_card)
		else:
			selected_card = candidate_card
			break
	
	if selected_card == null:
		print("Failed to select a unique card from library (this should not happen once we have a lot of cards): " + str(card_library._zone_type))
		# TODO: figure out how we should handle this later
		
	# Add the rejected cards back in to the bottom of the library
	card_library.add_cards(rejected_cards)
	return selected_card

func card_template_already_selected(candidate_template_id: String, selectable_cards: Array[Card]) -> bool:
	for card in selectable_cards:
		if card.template_id == candidate_template_id:
			return true
	return false
				
func shuffle_libraries():
	rare_library.shuffle()
	uncommon_library.shuffle()
	common_library.shuffle()
	
# Get a card by its instance ID
func get_card(card_instance_id: String) -> Card:
	var zone = card_zone_map.get(card_instance_id)
	if zone == null:
		return null
		
	var zone_obj = _get_zone_object(zone)
	return zone_obj.get_card(card_instance_id)

# Get current zone of a card
func get_card_zone(card_instance_id: String) -> Zone:
	return card_zone_map.get(card_instance_id)
	
# Get all cards in a zone
func get_card_ids_in_zone(zone: Zone) -> Array[String]:
	var zone_obj: ZoneCollection = _get_zone_object(zone)
	return zone_obj.get_all_card_ids()

# Helper to get object reference for a zone
func _get_zone_object(zone: Zone):
	match zone:
		Zone.RARE_LIBRARY:
			return rare_library
		Zone.UNCOMMON_LIBRARY:
			return uncommon_library
		Zone.COMMON_LIBRARY:
			return common_library
		Zone.DEFAULT_LIBRARY:
			return default_library
		Zone.HAND:
			return hand
		Zone.BEING_PLAYED:
			return being_played
		Zone.GRAVEYARD:
			return graveyard
		Zone.DECK:
			return deck
		Zone.EXILED:
			return exiled
		Zone.SLOTTED:
			return slotted
		_:
			assert(false, "Unknown zone")
			return null


# Clear all zones (for game reset)
func clear_all_zones():
	hand.clear()
	graveyard.clear()
	rare_library.clear()
	uncommon_library.clear()
	common_library.clear()
	card_zone_map.clear()
	deck.clear()

	
