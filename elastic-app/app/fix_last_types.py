#!/usr/bin/env python3
"""
Fix the last remaining type safety issues
"""

import re
from pathlib import Path

# Manual fixes for complex issues that need specific attention
manual_fixes = {
    'src/scenes/utilities/global_utilities.gd': [
        (r'func get_enum_string\(enum_dict, enum_value\) -> String:',
         'func get_enum_string(enum_dict: Dictionary, enum_value: int) -> String:'),
    ],
    'src/scenes/utilities/sprite_control.gd': [
        (r'func set_sprite\(sprite_key: String, target_node: TextureRect\):',
         'func set_sprite(sprite_key: String, target_node: TextureRect) -> void:'),
    ],
    'src/scenes/ui/time/ui_beat_orchestrator.gd': [
        (r'var active_tweens = \[\]',
         'var active_tweens: Array[Tween] = []'),
    ],
    'src/scenes/ui/entities/ui_entity.gd': [
        (r'func set_entity_data\(entity: Entity\):',
         'func set_entity_data(entity: Entity) -> void:'),
    ],
    'src/scenes/ui/entities/goals/ui_goal.gd': [
        (r'func pct\(\):',
         'func pct() -> float:'),
    ],
    'src/scenes/ui/entities/engine/ui_texture_button.gd': [
        (r'func create_button_entity\(button: Button\):',
         'func create_button_entity(button: Button) -> void:'),
    ],
    'src/scenes/ui/entities/engine/ui_engine_slot.gd': [
        (r'func create_card_ui\(card: Card\):',
         'func create_card_ui(card: Card) -> void:'),
        (r'func pct\(\):',
         'func pct() -> float:'),
    ],
    'src/scenes/ui/hand/hand_container.gd': [
        (r'var cards_in_hand: Dictionary = \{\}',
         'var cards_in_hand: Dictionary[String, CardUI] = {}'),
    ],
    'src/scenes/ui/click_and_drag/image_cursor.gd': [
        (r'func set_cursor_position\(position: Vector2\):',
         'func set_cursor_position(position: Vector2) -> void:'),
    ],
    'src/scenes/ui/click_and_drag/global_selection_manager.gd': [
        (r'func set_hovered\(hovered_selectable: SelectionManager\):',
         'func set_hovered(hovered_selectable: SelectionManager) -> void:'),
        (r'func clear_hovered_known\(selectible_clearing: SelectionManager\):',
         'func clear_hovered_known(selectible_clearing: SelectionManager) -> void:'),
        (r'func set_selected_known\(selectable_to_select: SelectionManager\):',
         'func set_selected_known(selectable_to_select: SelectionManager) -> void:'),
        (r'func set_selected_force\(selectable_to_select: SelectionManager\):',
         'func set_selected_force(selectable_to_select: SelectionManager) -> void:'),
        (r'func _init\(\):',
         'func _init() -> void:'),
    ],
    'src/scenes/ui/click_and_drag/cursor.gd': [
        (r'func is_valid_target\(entity: Entity\):',
         'func is_valid_target(entity: Entity) -> bool:'),
    ],
    'src/scenes/ui/click_and_drag/click_and_drag.gd': [
        (r'func add_dragging_visual\(parent: Node\):',
         'func add_dragging_visual(parent: Node) -> void:'),
    ],
    'src/scenes/ui/transitions/fade_to_black.gd': [
        (r'func go_to_scene\(scene: String, color: Color = Color.BLACK\):',
         'func go_to_scene(scene: String, color: Color = Color.BLACK) -> void:'),
    ],
    'src/scenes/ui/gremlins/ui_gremlin_panel.gd': [
        (r'var _gremlin_containers: Dictionary = \{\}',
         'var _gremlin_containers: Dictionary[String, Node] = {}'),
    ],
    'src/scenes/ui/mainplate/ui_mainplate.gd': [
        (r'(\s+)var neighbors = \[\]',
         r'\1var neighbors: Array[Vector2i] = []'),
    ],
    'src/scenes/core/wave_manager.gd': [
        (r'var wave_configs: Dictionary = \{\}',
         'var wave_configs: Dictionary[String, Dictionary] = {}'),
        (r'var current_wave_config: Dictionary = \{\}',
         'var current_wave_config: Dictionary[String, Variant] = {}'),
    ],
    'src/scenes/core/global_game_manager.gd': [
        (r'func activate\(source_instance_id: String, target_instance_id: String\):',
         'func activate(source_instance_id: String, target_instance_id: String) -> void:'),
        (r'func end_game\(win: bool = false\):',
         'func end_game(win: bool = false) -> void:'),
    ],
    'src/scenes/core/library.gd': [
        (r'(\s+)func _init\(\):',
         r'\1func _init() -> void:'),
        (r'func add_card_to_zone\(card_instance_id: String, zone: Zone\):',
         'func add_card_to_zone(card_instance_id: String, zone: Zone) -> void:'),
        (r'func draw_card\(\):',
         'func draw_card() -> bool:'),
        (r'func draw_new_hand\(draw_amount: int = hand_size\):',
         'func draw_new_hand(draw_amount: int = hand_size) -> void:'),
    ],
    'src/scenes/core/entities/battle_entity.gd': [
        (r'func has_status_effect\(effect: String\):',
         'func has_status_effect(effect: String) -> bool:'),
        (r'func decrement_status_effect\(effect: String, amount: int = 1\):',
         'func decrement_status_effect(effect: String, amount: int = 1) -> void:'),
    ],
    'src/scenes/core/entities/mainplate.gd': [
        (r'(\s+)func _init\(\):',
         r'\1func _init() -> void:'),
        (r'var __slot_button_map: Dictionary = \{\}',
         'var __slot_button_map: Dictionary[String, Button] = {}'),
        (r'var __button_slot_map: Dictionary = \{\}',
         'var __button_slot_map: Dictionary[String, String] = {}'),
        (r'var __slot_type_map: Dictionary = \{\}',
         'var __slot_type_map: Dictionary[String, Card.SlotType] = {}'),
        (r'(\s+)var new_slots = \{\}',
         r'\1var new_slots: Dictionary[String, Button] = {}'),
    ],
    'src/scenes/core/entities/card.gd': [
        (r'(\s+)var text_parts = \[\]',
         r'\1var text_parts: Array[String] = []'),
        (r'return \[\],',
         'return [] as Array[Variant],'),
    ],
    'src/scenes/core/entities/button.gd': [
        (r'func activate_slot_effect\(\):',
         'func activate_slot_effect() -> void:'),
    ],
    'src/scenes/core/resources/capped_resource.gd': [
        (r'(\s+)func _init\(max_amount: int\):',
         r'\1func _init(max_amount: int) -> void:'),
        (r'func increment\(\):',
         'func increment() -> void:'),
        (r'func decrement\(\):',
         'func decrement() -> void:'),
    ],
    'src/scenes/core/resources/relic_manager.gd': [
        (r'func has_relic\(relic_data_id: String\):',
         'func has_relic(relic_data_id: String) -> bool:'),
    ],
    'src/scenes/core/resources/cost.gd': [
        (r'(\s+)func _init\(\):',
         r'\1func _init() -> void:'),
        (r'func add\(resource_type: GameResource.Type, amount\):',
         'func add(resource_type: GameResource.Type, amount: int) -> void:'),
    ],
    'src/scenes/core/resources/game_resource.gd': [
        (r'(\s+)func _init\(\):',
         r'\1func _init() -> void:'),
    ],
    'src/scenes/core/effects/move_descriptor_effect.gd': [
        (r'(\s+)func _init\(\):',
         r'\1func _init() -> void:'),
        (r'func activate\(activation: ActivationLogic, processor\):',
         'func activate(activation: ActivationLogic, processor: TourbillonEffectProcessor) -> void:'),
    ],
    'src/scenes/core/effects/one_time_effect.gd': [
        (r'(\s+)func _init\(\):',
         r'\1func _init() -> void:'),
        (r'func activate\(processor, targets_dict\):',
         'func activate(processor: TourbillonEffectProcessor, targets_dict: Dictionary) -> void:'),
    ],
}

def apply_fixes():
    """Apply all manual fixes."""
    for filepath_str, patterns in manual_fixes.items():
        filepath = Path(filepath_str)
        if not filepath.exists():
            print(f"Skipping non-existent file: {filepath}")
            continue
        
        with open(filepath, 'r') as f:
            content = f.read()
        
        modified = False
        for pattern, replacement in patterns:
            new_content = re.sub(pattern, replacement, content)
            if new_content != content:
                print(f"Fixed in {filepath.name}: {pattern[:40]}...")
                content = new_content
                modified = True
        
        if modified:
            with open(filepath, 'w') as f:
                f.write(content)
            print(f"✅ Updated {filepath}")

if __name__ == '__main__':
    print("Applying final type safety fixes...")
    apply_fixes()
    print("\n✅ Done!")