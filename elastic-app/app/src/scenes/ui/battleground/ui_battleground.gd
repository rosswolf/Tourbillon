extends UiEntity
class_name UiBattleground

var next_slot: int = 0

func _ready() -> void:
	GlobalSignals.ui_started_game.connect(__on_start_game)
	
func __on_start_game() -> void:
	# Don't create a battleground entity since cards should target engine slots directly
	# set_entity_data(BattlegroundEntity.BattlegroundEntityBuilder.new().build())
	
	for i in range(15*7):
		var engine_slot_scene: PackedScene = preload("res://src/scenes/ui/entities/engine/ui_engine_slot.tscn")
		var slot_instance: EngineSlot = engine_slot_scene.instantiate()
		%SlotGridContainer.add_child(slot_instance)



	
