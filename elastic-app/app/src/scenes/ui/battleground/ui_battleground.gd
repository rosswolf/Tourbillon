extends UiEntity
class_name UiBattleground

var slots: Array[UiBattlegroundSlot] = []
var last_preview_slot: int = -1


func _ready():
	GlobalSignals.ui_started_game.connect(__on_start_game)
	GlobalSignals.core_arena_created.connect(__on_arena_created)
	GlobalSignals.core_arena_destroyed.connect(__on_arena_destroyed)
	GlobalSignals.core_battleground_targeting_preview_changed.connect(__on_targeting_preview_changed)
	
func __on_targeting_preview_changed(on_index: int):
	for slot_index in range(0, slots.size()):
		slots[slot_index].remove_targeting_preview_icon()
		if on_index == slot_index:
			slots[slot_index].add_targeting_preview_icon()

func __on_arena_created(size: int):
	var UI_BATTLEGROUND_SLOT: PackedScene = preload("res://src/scenes/ui/battleground/ui_battleground_slot.tscn")
	for i in range(size):
		var slot: UiBattlegroundSlot = UI_BATTLEGROUND_SLOT.instantiate()
		slots.append(slot)
		%SlotsContainer.add_child(slot)

func __on_arena_destroyed(instance_id: String):
	__clear_slots()
			
func __clear_slots():
	for slot in slots:
		%SlotsContainer.remove_child(slot)
		slot.queue_free()
	
	slots.clear()

func __on_start_game():
	set_entity_data(BattlegroundEntity.BattlegroundEntityBuilder.new().build())



	
func get_desired_slot(entity: Entity):
	return GlobalGameManager.battleground.arena.unit_position_bimap.get_position(entity.instance_id)

func get_slot_x(slot_index: int):
	var result = slots[slot_index].get_global_rect().position
#	print("slot index: " + str(slot_index) + " slot center: " + str(slots[slot_index].get_global_rect()))
	return result.x
	
func get_default_y():
	return %ArenaPanelControl.get_global_rect().position.y + %ArenaPanelControl.get_global_rect().size.y - 240
	
func get_position_for_character(slot_index: int):
	var desired_x = get_slot_x(slot_index)	
	var desired_y = get_default_y()	
	
	return Vector2(desired_x, desired_y)
