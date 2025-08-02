extends UiEntity
class_name UiBattleground

@export var rows: int = 3
@export var columns: int = 5

var next_slot: int = 0

func _ready():
	GlobalSignals.ui_started_game.connect(__on_start_game)
	GlobalSignals.core_card_slotted.connect(__on_card_slotted)
	
func __on_card_slotted(instance_id: String):
	var card: Card = GlobalGameManager.instance_catalog.get_instance(instance_id)
	if card == null:
		assert(false, "can't find card in instance catalog")
		return
	
	var engine_slot_scene: PackedScene = preload("res://src/scenes/ui/entities/engine/ui_engine_slot.tscn")
	var slot_instance: EngineSlot = engine_slot_scene.instantiate()
	
	#slot_instance.slot_activated.connect(func(): card.__slot_effect.activate(card))
	%SlotGridContainer.add_child(slot_instance)
	slot_instance.attach_card(card)
	
func __on_start_game():
	set_entity_data(BattlegroundEntity.BattlegroundEntityBuilder.new().build())



	
