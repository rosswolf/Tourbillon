extends Control

class_name Game

#Game.gd

var MUSIC_MP3: String = "res://pixabay assets/reportage-industriel-song-1-261972.mp3"

@onready var targeting_icon: TargetingIcon = \
	$Background/MainVBoxContainer/BotVBoxContainer/HBoxContainer/VBoxContainer/TargetingPanelContainer/GenericTargetingIcon

# Legacy meters removed - use force system instead

func _ready() -> void:
	
	GlobalSignals.core_card_drawn.connect(__on_card_drawn)
	GlobalSignals.core_card_removed_from_hand.connect(__on_card_removed_from_hand)
	GlobalSignals.core_relic_added.connect(__on_relic_added)
	GlobalSignals.core_relic_removed.connect(__on_relic_removed)
	GlobalSignals.core_card_removed_from_hand.connect(__on_card_removed_from_hand)
	GlobalSignals.core_game_win.connect(__on_core_game_win)
	
	# Connect to new time UI signals
	GlobalSignals.ui_time_updated.connect(__on_time_updated)
	GlobalSignals.ui_card_ticks_resolved.connect(__on_card_ticks_resolved)
	
	
	var audio_stream = load(MUSIC_MP3)
	%AudioStreamPlayer.stream = audio_stream
	%AudioStreamPlayer.play()
	%AudioStreamPlayer.finished.connect(__on_audio_finished)
	
	# Legacy meter setup removed - use force system instead
	
	GlobalSignals.signal_ui_started_game()
	%GlobalTimer.start()


func __on_audio_finished():
	%AudioStreamPlayer.play()  # Restart when finished


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Time display now handled by signal
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

		
func __on_relic_added(relic: Relic) -> void:
	var relic_icon: RelicIcon = PreloadScenes.ICONS["relic"].instantiate()
	relic_icon.set_relic(relic)
	
	%RelicGridContainer.add_child(relic_icon)
	
# Legacy get_time_remaining removed - use force system instead
		
func __on_time_updated(tick_display: String) -> void:
	# Update the time label with the formatted tick display
	assert(%GlobalTimeLabel != null, "GlobalTimeLabel must exist for time updates")
	%GlobalTimeLabel.text = tick_display

func __on_card_ticks_resolved() -> void:
	# Re-enable hand interaction after card processing is done
	assert(%CardHandContainer != null, "CardHandContainer must exist for card interaction")
	%CardHandContainer.mouse_filter = Control.MOUSE_FILTER_PASS

func format_elapsed_time(timer: Timer) -> String:
	var elapsed = timer.wait_time - timer.time_left
	return format_time_string(elapsed)

func format_time_string(time_seconds: float) -> String:
	var hours = int(time_seconds) / 3600
	var minutes = (int(time_seconds) % 3600) / 60
	var seconds = int(time_seconds) % 60
	var milliseconds = int((time_seconds - int(time_seconds)) * 1000)

	return "%02d:%02d:%02d:%03d" % [hours, minutes, seconds, milliseconds]

func format_elapsed_time_hex(timer: Timer) -> String:
	var elapsed = timer.wait_time - timer.time_left
	return format_time_string_hex(elapsed)

func format_time_string_hex(time_seconds: float) -> String:
	var hours = int(time_seconds) / 3600
	var minutes = (int(time_seconds) % 3600) / 60
	var seconds = int(time_seconds) % 60
	var milliseconds = int((time_seconds - int(time_seconds)) * 1000)
	
	return "%02X:%02X:%02X:%03X" % [hours, minutes, seconds, milliseconds]
	
func __on_relic_removed(relic_instance_id: String) -> void:
	#TODO: slow implementation, if needed make a scene for containing the relics
	var children: Array[Node] = %RelicGridContainer.get_children()
	
	for child in children:
		var icon: RelicIcon = child as RelicIcon
		if icon._relic.instance_id == relic_instance_id:
			%RelicGridContainer.remove_child(child)
			child.queue_free()

func __on_core_game_win():
	FadeToBlack.go_to_scene("res://src/scenes/win.tscn")
