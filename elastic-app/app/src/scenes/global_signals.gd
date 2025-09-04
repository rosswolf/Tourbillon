extends Node


# As a general principle, we should produce and consume from core -> UI, or from UI -> core,
# Signals that are from UI->UI or core->core should be carefully thought out and understood why
# Ui -> UI may happen when the 2nd UI aspect is only visual, not logical.  

signal ui_started_game()
func signal_ui_started_game() -> void:
	ui_started_game.emit()

signal ui_started_battle()
func signal_ui_started_battle() -> void:
	ui_started_battle.emit()
		
signal ui_quit_to_main()
func signal_ui_quit_to_main() -> void:
	ui_quit_to_main.emit()

signal ui_execute_selected_onto_hovered(source_instance_id: String, target_instance_id: String)
func signal_ui_execute_selected_onto_hovered(source_instance_id: String, target_instance_id: String) -> void:
	ui_execute_selected_onto_hovered.emit(source_instance_id, target_instance_id)

signal ui_selected_changed(instance_id: String)
func signal_ui_selected_changed(instance_id: String) -> void:
	ui_selected_changed.emit(instance_id)

signal ui_slotted_card(slot_name: String, image_path: String)
func signal_ui_slotted_card(slot_name: String, image_path: String) -> void:
	ui_slotted_card.emit(slot_name, image_path)

signal ui_changed_cursor_image(image_path: String)
func signal_ui_changed_cursor_image(image_path: String) -> void:
	ui_changed_cursor_image.emit(image_path)

signal ui_card_hovered(card_instance_id: String)
func signal_ui_card_hovered(card_instance_id: String) -> void:
	ui_card_hovered.emit(card_instance_id)

signal ui_card_unhovered(card_instance_id: String)
func signal_ui_card_unhovered(card_instance_id: String) -> void:
	ui_card_unhovered.emit(card_instance_id)

signal ui_card_clicked(card_instance_id: String)
func signal_ui_card_clicked(card_instance_id: String) -> void:
	ui_card_clicked.emit(card_instance_id)

signal ui_time_bump()
func signal_ui_time_bump() -> void:
	ui_time_bump.emit()

# UI signals for card placement flow
signal ui_card_dropped_on_slot(card_id: String, button_id: String)
func signal_ui_card_dropped_on_slot(card_id: String, button_id: String) -> void:
	ui_card_dropped_on_slot.emit(card_id, button_id)

# Core Signal Functions

# Goal signals removed - use gremlin system instead

# Legacy time/energy signals removed - use force system instead




	
# Core Signal Functions


signal core_begin_turn()
func signal_core_begin_turn() -> void:
	core_begin_turn.emit()

signal core_end_turn()
func signal_core_end_turn() -> void:
	core_end_turn.emit()

signal core_end_battle()
func signal_core_end_battle() -> void:
	core_end_battle.emit()
	
signal core_game_over()
func signal_core_game_over() -> void:
	core_game_over.emit()
	
signal core_game_win()
func signal_core_game_win() -> void:
	core_game_win.emit()
	
signal core_arena_created(size: int)
func signal_core_arena_created(size: int) -> void:
	core_arena_created.emit(size)

	
signal core_activation_with_non_activatable_source(source_id: String)
func signal_core_activation_with_non_activatable_source(source_id: String) -> void:
	core_activation_with_non_activatable_source.emit(source_id)

signal core_activation_source_requires_target(source_id: String)
func signal_core_activation_source_requires_target(source_id: String) -> void:
	core_activation_source_requires_target.emit(source_id)

signal core_activation_source_wrong_target(source_id: String, target_id: String)
func signal_core_activation_source_wrong_target(source_id: String, target_id: String) -> void:
	core_activation_source_wrong_target.emit(source_id, target_id)

signal core_hero_created(hero_instance_id: String)
func signal_core_hero_created(hero_instance_id: String) -> void:
	core_hero_created.emit(hero_instance_id)

signal core_hero_moved(hero_instance_id: String, new_location: int)
func signal_core_hero_moved(hero_instance_id: String, new_location: int) -> void:
	core_hero_moved.emit(hero_instance_id, new_location)

signal core_mob_created(mob_instance_id: String)
func signal_core_mob_created(mob_instance_id: String) -> void:
	core_mob_created.emit(mob_instance_id)

signal core_mob_health_changed(mob_instance_id: String, new_health: int)
func signal_core_mob_health_changed(mob_instance_id: String, new_health: int) -> void:
	core_mob_health_changed.emit(mob_instance_id, new_health)

signal core_mob_check_state(mob_instance_id: String, new_health: int)
func signal_core_mob_check_state(mob_instance_id: String, new_health: int) -> void:
	core_mob_check_state.emit(mob_instance_id, new_health)

signal core_mob_block_changed(mob_instance_id: String, new_value: int)
func signal_core_mob_block_changed(mob_instance_id: String, new_value: int) -> void:
	core_mob_block_changed.emit(mob_instance_id, new_value)

signal core_mob_armor_changed(mob_instance_id: String, new_value: int)
func signal_core_mob_armor_changed(mob_instance_id: String, new_value: int) -> void:
	core_mob_armor_changed.emit(mob_instance_id, new_value)

signal core_mob_moved(mob_instance_id: String, new_location: int)
func signal_core_mob_moved(mob_instance_id: String, new_location: int) -> void:
	core_mob_moved.emit(mob_instance_id, new_location)

signal core_mob_intent_updated(mob_instance_id: String)
func signal_core_mob_intent_updated(mob_instance_id: String) -> void:
	core_mob_intent_updated.emit(mob_instance_id)

signal core_card_slotted(card_id: String, position: Vector2i)
func signal_core_card_slotted(card_id: String, position: Vector2i) -> void:
	core_card_slotted.emit(card_id, position)
	
signal core_card_unslotted(slot_instance_id: String)
func signal_core_card_unslotted(slot_instance_id: String) -> void:
	core_card_unslotted.emit(slot_instance_id)

signal core_card_replaced(old_card_id: String, new_card_id: String, position: Vector2i)
func signal_core_card_replaced(old_card_id: String, new_card_id: String, position: Vector2i) -> void:
	core_card_replaced.emit(old_card_id, new_card_id, position)

signal core_gear_process_beat(card_instance_id: String, context: BeatContext)
func signal_core_gear_process_beat(card_instance_id: String, context: BeatContext) -> void:
	core_gear_process_beat.emit(card_instance_id, context)

signal core_slot_add_cooldown(instance_id: String, duration: float)
func signal_core_slot_add_cooldown(instance_id: String, duration: float) -> void:
	core_slot_add_cooldown.emit(instance_id, duration)

signal core_slot_activated(trigger_card_id: String)
func signal_core_slot_activated(trigger_card_id: String) -> void:
	core_slot_activated.emit(trigger_card_id)


signal core_card_selection(selection_id, landing_zone: Library.Zone)
func signal_core_card_selection(selection_id: String, landing_zone: Library.Zone) -> void:
	core_card_selection.emit(selection_id, landing_zone)
	
signal core_card_drawn(card_instance_id: String)
func signal_core_card_drawn(card_instance_id: String) -> void:
	core_card_drawn.emit(card_instance_id)

signal core_card_played(card_instance_id: String)
func signal_core_card_played(card_instance_id: String) -> void:
	core_card_played.emit(card_instance_id)

signal core_card_played_but_cant_satisfy_cost(card_instance_id: String)
func signal_core_card_played_but_cant_satisfy_cost(card_instance_id: String) -> void:
	core_card_played_but_cant_satisfy_cost.emit(card_instance_id)
	
signal core_missing_resource(type: GameResource.Type)
func signal_core_missing_resource(type: GameResource.Type) -> void:
	core_missing_resource.emit(type)

signal core_card_discarded(card_instance_id: String)
func signal_core_card_discarded(card_instance_id: String) -> void:
	core_card_discarded.emit(card_instance_id)
	
signal core_card_destroyed(card_instance_id: String)
func signal_core_card_destroyed(card_instance_id: String) -> void:
	core_card_destroyed.emit(card_instance_id)
	
signal core_card_removed_from_hand(card_instance_id: String)
func signal_core_card_removed_from_hand(card_instance_id: String) -> void:
	core_card_removed_from_hand.emit(card_instance_id)

signal core_hero_resource_changed(type: GameResource.Type, new_amount: int)
func signal_core_hero_resource_changed(type: GameResource.Type, new_amount: int) -> void:
	core_hero_resource_changed.emit(type, new_amount)

signal core_mob_resource_changed(mob_instance_id: String, type: GameResource.Type, new_amount: int)
func signal_core_mob_resource_changed(mob_instance_id: String, type: GameResource.Type, new_amount: int) -> void:
	core_mob_resource_changed.emit(mob_instance_id, type, new_amount)

signal core_relic_added(relic: Relic)
func signal_core_relic_added(relic: Relic) -> void:
	core_relic_added.emit(relic)

signal core_relic_removed(relic_instance_id: String)
func signal_core_relic_removed(relic_instance_id: String) -> void:
	core_relic_removed.emit(relic_instance_id)

signal core_max_hand_size_reached()
func signal_core_max_hand_size_reached() -> void:
	core_max_hand_size_reached.emit()

signal core_battleground_targeting_preview_changed(space_index: int)
func signal_core_battleground_targeting_preview_changed(space_index: int) -> void:
	core_battleground_targeting_preview_changed.emit(space_index)

signal stats_cards_drawn(amount: int)
func signal_stats_cards_drawn(amount: int) -> void:
	stats_cards_drawn.emit(amount)		
	
signal stats_cards_popped(amount: int)
func signal_stats_cards_popped(amount: int) -> void:
	stats_cards_popped.emit(amount)

signal stats_cards_played(amount: int)
func signal_stats_cards_played(amount: int) -> void:
	stats_cards_played.emit(amount)	
	
signal stats_cards_slotted(amount: int)
func signal_stats_cards_slotted(amount: int) -> void:
	stats_cards_slotted.emit(amount)

signal stats_slots_activated(amount: int)
func signal_stats_slots_activated(amount: int) -> void:
	stats_slots_activated.emit(amount)
	
signal stats_energy_spent(amount: int)
func signal_stats_energy_spent(amount: int) -> void:
	stats_energy_spent.emit(amount)

signal stats_gold_spent(amount: int)
func signal_stats_gold_spent(amount: int) -> void:
	stats_gold_spent.emit(amount)

# Tourbillon Time UI Signals
signal ui_time_updated(tick_display: String)
func signal_ui_time_updated(tick_display: String) -> void:
	ui_time_updated.emit(tick_display)

signal ui_card_ticks_resolved()
func signal_ui_card_ticks_resolved() -> void:
	ui_card_ticks_resolved.emit()
