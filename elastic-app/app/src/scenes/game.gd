extends Control

#Game.gd

@onready var targeting_icon: TargetingIcon = \
	$Background/MainVBoxContainer/BotHBoxContainer/UIVBoxContainer/HBoxContainer/VBoxContainer/TargetingPanelContainer/GenericTargetingIcon

func _ready() -> void:
	
	GlobalSignals.core_card_drawn.connect(__on_card_drawn)
	GlobalSignals.core_card_removed_from_hand.connect(__on_card_removed_from_hand)
	GlobalSignals.core_relic_added.connect(__on_relic_added)
	GlobalSignals.core_relic_removed.connect(__on_relic_removed)
	GlobalSignals.core_targeting_changed.connect(__on_targeting_changed)
	GlobalSignals.core_card_removed_from_hand.connect(__on_card_removed_from_hand)
	
	GlobalSignals.signal_ui_started_game()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func __end_turn() -> void:
	GlobalGameManager.end_turn()
	
func __on_card_drawn(card_instance_id: String) -> void:
	add_card_to_hand_by_instance(card_instance_id)

func __on_card_removed_from_hand(card_instance_id: String) -> void:
	remove_card_from_hand_ui(card_instance_id)
	
func add_card_to_hand_by_instance(card_instance_id: String) -> void:
	var card = GlobalGameManager.instance_catalog.get_instance(card_instance_id) as Card
	if card == null:
		printerr("Card instance id not found in catalog" + card_instance_id)
		return
	add_card_to_hand(card)
	
func add_card_to_hand(card: Card) -> void:
	var card_ui: CardUI = PreloadScenes.NODES["card_ui"].instantiate()
	#card_ui.card_clicked.connect(_on_card_clicked)
	%CardHandContainer.add_card(card_ui, card)

func remove_card_from_hand_ui(card_instance_id: String) -> void:
	var card: CardUI = %CardHandContainer.remove_card(card_instance_id)
	card.queue_free()

func __on_targeting_changed(targeting: Battleground.OrderPriority) -> void:
	if targeting_icon != null:
		targeting_icon.set_targeting(targeting)
		
func __on_relic_added(relic: Relic) -> void:
	var relic_icon: RelicIcon = PreloadScenes.ICONS["relic"].instantiate()
	relic_icon.set_relic(relic)
	
	%RelicGridContainer.add_child(relic_icon)

func __on_relic_removed(relic_instance_id: String) -> void:
	#TODO: slow implementation, if needed make a scene for containing the relics
	var children: Array[Node] = %RelicGridContainer.get_children()
	
	for child in children:
		var icon: RelicIcon = child as RelicIcon
		if icon._relic.instance_id == relic_instance_id:
			%RelicGridContainer.remove_child(child)
			child.queue_free()

	
