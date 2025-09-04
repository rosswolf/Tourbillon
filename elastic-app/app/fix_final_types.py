#!/usr/bin/env python3
"""
Final comprehensive type safety fixer
"""

import sys
import re
from pathlib import Path

def fix_all_remaining():
    """Fix all remaining type safety issues."""
    
    fixes = [
        # static_data.gd fixes
        ('src/scenes/data/static_data.gd', [
            ('func parse_enum(reference: String):', 'func parse_enum(reference: String) -> Variant:'),
            ('func lookup_in_data(data_dict: Dictionary, field_to_filter: String, filter_value, field_to_return: String) -> Array:', 
             'func lookup_in_data(data_dict: Dictionary, field_to_filter: String, filter_value: Variant, field_to_return: String) -> Array:'),
            ('func lookup_in_data_linear(data_dict: Dictionary, field_to_filter: String, filter_value, field_to_return: String) -> Array:',
             'func lookup_in_data_linear(data_dict: Dictionary, field_to_filter: String, filter_value: Variant, field_to_return: String) -> Array:'),
            ('var resolved_data: Array = []', 'var resolved_data: Array[Dictionary] = []'),
            ('var resolved_array: Array = []', 'var resolved_array: Array[Variant] = []'),
            ('var resolved_dict: Dictionary = {}', 'var resolved_dict: Dictionary[Variant, Variant] = {}'),
            ('var result_dict: Dictionary = {}', 'var result_dict: Dictionary[Variant, Dictionary] = {}'),
            ('var act_waves: Array = []', 'var act_waves: Array[Dictionary] = []'),
        ]),
        
        # utilities fixes
        ('src/scenes/utilities/global_utilities.gd', [
            ('func get_enum_string(enum_dict, enum_value) -> String:', 'func get_enum_string(enum_dict: Dictionary, enum_value: int) -> String:'),
        ]),
        
        ('src/scenes/utilities/sprite_control.gd', [
            ('func set_sprite(sprite_key: String, target_node: TextureRect):', 'func set_sprite(sprite_key: String, target_node: TextureRect) -> void:'),
            ('func __update_min_size(target_node: TextureRect):', 'func __update_min_size(target_node: TextureRect) -> void:'),
        ]),
        
        # UI entity fixes
        ('src/scenes/ui/entities/ui_entity.gd', [
            ('func set_entity_data(entity: Entity):', 'func set_entity_data(entity: Entity) -> void:'),
        ]),
        
        ('src/scenes/ui/entities/goals/ui_goal.gd', [
            ('func set_entity_data(entity: Entity):', 'func set_entity_data(entity: Entity) -> void:'),
            ('func pct():', 'func pct() -> float:'),
            ('func _process(delta: float):', 'func _process(delta: float) -> void:'),
        ]),
        
        ('src/scenes/ui/entities/engine/ui_texture_button.gd', [
            ('func create_button_entity(button: Button):', 'func create_button_entity(button: Button) -> void:'),
        ]),
        
        ('src/scenes/ui/entities/engine/ui_engine_slot.gd', [
            ('func create_card_ui(card: Card):', 'func create_card_ui(card: Card) -> void:'),
            ('func destroy_card_ui():', 'func destroy_card_ui() -> void:'),
            ('func pct():', 'func pct() -> float:'),
        ]),
        
        # UI hand fixes
        ('src/scenes/ui/hand/card_ui.gd', [
            ('func refresh():', 'func refresh() -> void:'),
        ]),
        
        ('src/scenes/ui/hand/hand_container.gd', [
            ('var cards_in_hand: Dictionary = {}', 'var cards_in_hand: Dictionary[String, CardUI] = {}'),
        ]),
        
        # Click and drag fixes
        ('src/scenes/ui/click_and_drag/image_cursor.gd', [
            ('func set_cursor_position(position: Vector2):', 'func set_cursor_position(position: Vector2) -> void:'),
        ]),
        
        ('src/scenes/ui/click_and_drag/global_selection_manager.gd', [
            ('func set_hovered(hovered_selectable: SelectionManager):', 'func set_hovered(hovered_selectable: SelectionManager) -> void:'),
            ('func clear_hovered_known(selectible_clearing: SelectionManager):', 'func clear_hovered_known(selectible_clearing: SelectionManager) -> void:'),
            ('func clear_hovered_force():', 'func clear_hovered_force() -> void:'),
            ('func set_selected_known(selectable_to_select: SelectionManager):', 'func set_selected_known(selectable_to_select: SelectionManager) -> void:'),
            ('func set_selected_force(selectable_to_select: SelectionManager):', 'func set_selected_force(selectable_to_select: SelectionManager) -> void:'),
            ('func activate_selected_onto_hovered(last_pos):', 'func activate_selected_onto_hovered(last_pos: Vector2) -> void:'),
            ('func _init():', 'func _init() -> void:'),
        ]),
        
        ('src/scenes/ui/click_and_drag/cursor.gd', [
            ('func is_valid_target(entity: Entity) -> bool:', 'func is_valid_target(entity: Entity) -> bool:'),
        ]),
        
        ('src/scenes/ui/click_and_drag/click_and_drag.gd', [
            ('func add_dragging_visual(parent: Node):', 'func add_dragging_visual(parent: Node) -> void:'),
            ('func remove_dragging_visual():', 'func remove_dragging_visual() -> void:'),
            ('func get_relevant_visual():', 'func get_relevant_visual() -> Node:'),
        ]),
        
        # Other UI fixes
        ('src/scenes/ui/transitions/fade_to_black.gd', [
            ('func go_to_scene(scene: String, color: Color = Color.BLACK):', 'func go_to_scene(scene: String, color: Color = Color.BLACK) -> void:'),
        ]),
        
        ('src/scenes/ui/gremlins/ui_gremlin_panel.gd', [
            ('var _gremlin_containers: Dictionary = {}', 'var _gremlin_containers: Dictionary[String, Node] = {}'),
        ]),
        
        ('src/scenes/ui/mainplate/ui_mainplate.gd', [
            ('var neighbors = []', 'var neighbors: Array[Vector2i] = []'),
        ]),
        
        ('src/scenes/ui/hud/game_over_modal.gd', [
            ('func resume():', 'func resume() -> void:'),
        ]),
        
        ('src/scenes/ui/hud/pause_modal.gd', [
            ('func resume():', 'func resume() -> void:'),
            ('func pause():', 'func pause() -> void:'),
        ]),
        
        # Core fixes
        ('src/scenes/core/wave_manager.gd', [
            ('var wave_configs: Dictionary = {}', 'var wave_configs: Dictionary[String, Dictionary] = {}'),
            ('var current_wave_config: Dictionary = {}', 'var current_wave_config: Dictionary[String, Variant] = {}'),
        ]),
        
        ('src/scenes/core/global_game_manager.gd', [
            ('func allow_activations():', 'func allow_activations() -> void:'),
            ('func disallow_activations():', 'func disallow_activations() -> void:'),
            ('func reset_game_state():', 'func reset_game_state() -> void:'),
            ('func activate(source_instance_id: String, target_instance_id: String):', 'func activate(source_instance_id: String, target_instance_id: String) -> void:'),
            ('func end_turn():', 'func end_turn() -> void:'),
            ('func end_game(win: bool = false):', 'func end_game(win: bool = false) -> void:'),
        ]),
        
        ('src/scenes/core/library.gd', [
            ('func _init():', 'func _init() -> void:'),
            ('func add_card(card: Card):', 'func add_card(card: Card) -> void:'),
            ('func add_cards(cards: Array[Card]):', 'func add_cards(cards: Array[Card]) -> void:'),
            ('func shuffle():', 'func shuffle() -> void:'),
            ('func clear():', 'func clear() -> void:'),
            ('func print_hand_size():', 'func print_hand_size() -> void:'),
            ('func add_card_to_zone(card_instance_id: String, zone: Zone):', 'func add_card_to_zone(card_instance_id: String, zone: Zone) -> void:'),
            ('func discard_hand():', 'func discard_hand() -> void:'),
            ('func draw_card():', 'func draw_card() -> bool:'),
            ('func draw_new_hand():', 'func draw_new_hand() -> void:'),
            ('func shuffle_libraries():', 'func shuffle_libraries() -> void:'),
            ('func clear_all_zones():', 'func clear_all_zones() -> void:'),
        ]),
        
        # Entity fixes
        ('src/scenes/core/entities/battle_entity.gd', [
            ('func has_status_effect(effect: String):', 'func has_status_effect(effect: String) -> bool:'),
            ('func decrement_status_effect(effect: String, amount: int = 1):', 'func decrement_status_effect(effect: String, amount: int = 1) -> void:'),
            ('func decrement_all_status_effects():', 'func decrement_all_status_effects() -> void:'),
        ]),
        
        ('src/scenes/core/entities/mainplate.gd', [
            ('func _init():', 'func _init() -> void:'),
            ('var __slot_button_map: Dictionary = {}', 'var __slot_button_map: Dictionary[String, Button] = {}'),
            ('var __button_slot_map: Dictionary = {}', 'var __button_slot_map: Dictionary[String, String] = {}'),
            ('var __slot_type_map: Dictionary = {}', 'var __slot_type_map: Dictionary[String, Card.SlotType] = {}'),
            ('var new_slots = {}', 'var new_slots: Dictionary[String, Button] = {}'),
        ]),
        
        ('src/scenes/core/entities/card.gd', [
            ('var text_parts = []', 'var text_parts: Array[String] = []'),
            ('return [],', 'return [] as Array[Variant],'),
        ]),
        
        ('src/scenes/core/entities/hero.gd', [
            ('func reset_start_of_battle():', 'func reset_start_of_battle() -> void:'),
        ]),
        
        ('src/scenes/core/entities/button.gd', [
            ('func get_card_instance_id():', 'func get_card_instance_id() -> String:'),
            ('func activate_slot_effect():', 'func activate_slot_effect() -> void:'),
        ]),
        
        # Resource fixes
        ('src/scenes/core/resources/capped_resource.gd', [
            ('func _init(max_amount: int):', 'func _init(max_amount: int) -> void:'),
            ('func increment():', 'func increment() -> void:'),
            ('func decrement():', 'func decrement() -> void:'),
            ('func send_signal():', 'func send_signal() -> void:'),
        ]),
        
        ('src/scenes/core/resources/relic_manager.gd', [
            ('func has_relic(relic_data_id: String):', 'func has_relic(relic_data_id: String) -> bool:'),
        ]),
        
        ('src/scenes/core/resources/cost.gd', [
            ('func _init():', 'func _init() -> void:'),
            ('func add(resource_type: GameResource.Type, amount):', 'func add(resource_type: GameResource.Type, amount: int) -> void:'),
        ]),
        
        ('src/scenes/core/resources/game_resource.gd', [
            ('func _init():', 'func _init() -> void:'),
        ]),
        
        # Effect fixes
        ('src/scenes/core/effects/move_descriptor_effect.gd', [
            ('func _init():', 'func _init() -> void:'),
            ('func activate(activation: ActivationLogic, processor):', 'func activate(activation: ActivationLogic, processor) -> void:'),
        ]),
        
        ('src/scenes/core/effects/one_time_effect.gd', [
            ('func _init():', 'func _init() -> void:'),
            ('func activate(processor, targets_dict):', 'func activate(processor, targets_dict) -> void:'),
        ]),
        
        # Beat orchestrator fix  
        ('src/scenes/ui/time/ui_beat_orchestrator.gd', [
            ('var active_tweens = []', 'var active_tweens: Array[Tween] = []'),
        ]),
    ]
    
    for filepath_str, replacements in fixes:
        filepath = Path(filepath_str)
        if not filepath.exists():
            print(f"Skipping non-existent file: {filepath}")
            continue
            
        with open(filepath, 'r') as f:
            content = f.read()
        
        modified = False
        for old, new in replacements:
            if old in content:
                content = content.replace(old, new)
                print(f"Fixed in {filepath.name}: {old[:40]}...")
                modified = True
        
        if modified:
            with open(filepath, 'w') as f:
                f.write(content)
            print(f"✅ Updated {filepath}")

def main():
    print("Applying final type safety fixes...")
    fix_all_remaining()
    print("\n✅ Finished final type safety fixes")

if __name__ == '__main__':
    main()