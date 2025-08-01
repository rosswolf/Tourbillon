extends Node


# As a general principle, we should produce and consume from core -> UI, or from UI -> core,
# Signals that are from UI->UI or core->core should be carefully thought out and understood why
# Ui -> UI may happen when the 2nd UI aspect is only visual, not logical.  

signal ui_started_game()
func signal_ui_started_game():
	ui_started_game.emit()

signal ui_started_battle()
func signal_ui_started_battle():
	ui_started_battle.emit()
		
signal ui_quit_to_main()
func signal_ui_quit_to_main():
	ui_quit_to_main.emit()

signal ui_execute_selected_onto_hovered(source_instance_id: String, target_instance_id: String)
func signal_ui_execute_selected_onto_hovered(source_instance_id: String, target_instance_id: String):
	ui_execute_selected_onto_hovered.emit(source_instance_id, target_instance_id)

signal ui_selected_changed(instance_id: String)
func signal_ui_selected_changed(instance_id: String):
	ui_selected_changed.emit(instance_id)

signal ui_slotted_card(slot_name: String, image_path: String)
func signal_ui_slotted_card(slot_name: String, image_path: String):
	ui_slotted_card.emit(slot_name, image_path)

signal ui_changed_cursor_image(image_path: String)
func signal_ui_changed_cursor_image(image_path: String):
	ui_changed_cursor_image.emit(image_path)

signal ui_slot_activated(slot_name: String, trigger_card_id: String)
func signal_ui_slot_activated(slot_name: String, trigger_card_id: String):
	ui_slot_activated.emit(slot_name, trigger_card_id)

signal ui_card_hovered(card_instance_id: String)
func signal_ui_card_hovered(card_instance_id: String):
	ui_card_hovered.emit(card_instance_id)

signal ui_card_unhovered(card_instance_id: String)
func signal_ui_card_unhovered(card_instance_id: String):
	ui_card_unhovered.emit(card_instance_id)

# Core Signal Functions
signal core_time_added(amount: float)
func signal_core_time_added(amount: float):
	core_time_added.emit(amount)

signal core_begin_turn()
func signal_core_begin_turn():
	core_begin_turn.emit()

signal core_end_turn()
func signal_core_end_turn():
	core_end_turn.emit()

signal core_end_battle()
func signal_core_end_battle():
	core_end_battle.emit()
	
signal core_game_over()
func signal_core_game_over():
	core_game_over.emit()
	
signal core_arena_created(size: int)
func signal_core_arena_created(size: int):
	core_arena_created.emit(size)

signal core_arena_destroyed(instance_id: String)
func signal_core_arena_destroyed(instance_id: String):
	core_arena_destroyed.emit(instance_id)
	
	
signal core_activation_with_non_activatable_source(source_id: String)
func signal_core_activation_with_non_activatable_source(source_id: String):
	core_activation_with_non_activatable_source.emit(source_id)

signal core_activation_source_requires_target(source_id: String)
func signal_core_activation_source_requires_target(source_id: String):
	core_activation_source_requires_target.emit(source_id)

signal core_activation_source_wrong_target(source_id: String, target_id: String)
func signal_core_activation_source_wrong_target(source_id: String, target_id: String):
	core_activation_source_wrong_target.emit(source_id, target_id)

signal core_hero_created(hero_instance_id: String)
func signal_core_hero_created(hero_instance_id: String):
	core_hero_created.emit(hero_instance_id)

signal core_hero_moved(hero_instance_id: String, new_location: int)
func signal_core_hero_moved(hero_instance_id: String, new_location: int):
	core_hero_moved.emit(hero_instance_id, new_location)

signal core_mob_created(mob_instance_id: String)
func signal_core_mob_created(mob_instance_id: String):
	core_mob_created.emit(mob_instance_id)

signal core_mob_health_changed(mob_instance_id: String, new_health: int)
func signal_core_mob_health_changed(mob_instance_id: String, new_health: int):
	core_mob_health_changed.emit(mob_instance_id, new_health)

signal core_mob_check_state(mob_instance_id: String, new_health: int)
func signal_core_mob_check_state(mob_instance_id: String, new_health: int):
	core_mob_check_state.emit(mob_instance_id, new_health)

signal core_mob_block_changed(mob_instance_id: String, new_value: int)
func signal_core_mob_block_changed(mob_instance_id: String, new_value: int):
	core_mob_block_changed.emit(mob_instance_id, new_value)

signal core_mob_armor_changed(mob_instance_id: String, new_value: int)
func signal_core_mob_armor_changed(mob_instance_id: String, new_value: int):
	core_mob_armor_changed.emit(mob_instance_id, new_value)

signal core_mob_moved(mob_instance_id: String, new_location: int)
func signal_core_mob_moved(mob_instance_id: String, new_location: int):
	core_mob_moved.emit(mob_instance_id, new_location)

signal core_mob_intent_updated(mob_instance_id: String)
func signal_core_mob_intent_updated(mob_instance_id: String):
	core_mob_intent_updated.emit(mob_instance_id)

signal core_card_selection()
func signal_core_card_selection():
	core_card_selection.emit()
	
signal core_card_drawn(card_instance_id: String)
func signal_core_card_drawn(card_instance_id: String):
	core_card_drawn.emit(card_instance_id)

signal core_card_played_but_cant_satisfy_cost(card_instance_id: String)
func signal_core_card_played_but_cant_satisfy_cost(card_instance_id: String):
	core_card_played_but_cant_satisfy_cost.emit(card_instance_id)

signal core_card_discarded(card_instance_id: String)
func signal_core_card_discarded(card_instance_id: String):
	core_card_discarded.emit(card_instance_id)

signal core_card_removed_from_hand(card_instance_id: String)
func signal_core_card_removed_from_hand(card_instance_id: String):
	core_card_removed_from_hand.emit(card_instance_id)

signal core_hero_resource_changed(type: GameResource.Type, new_amount: int)
func signal_core_hero_resource_changed(type: GameResource.Type, new_amount: int):
	core_hero_resource_changed.emit(type, new_amount)

signal core_mob_resource_changed(mob_instance_id: String, type: GameResource.Type, new_amount: int)
func signal_core_mob_resource_changed(mob_instance_id: String, type: GameResource.Type, new_amount: int):
	core_mob_resource_changed.emit(mob_instance_id, type, new_amount)

signal core_relic_added(relic: Relic)
func signal_core_relic_added(relic: Relic):
	core_relic_added.emit(relic)

signal core_relic_removed(relic_instance_id: String)
func signal_core_relic_removed(relic_instance_id: String):
	core_relic_removed.emit(relic_instance_id)

signal core_max_hand_size_reached()
func signal_core_max_hand_size_reached():
	core_max_hand_size_reached.emit()

signal core_battleground_targeting_preview_changed(space_index: int)
func signal_core_battleground_targeting_preview_changed(space_index: int):
	core_battleground_targeting_preview_changed.emit(space_index)
