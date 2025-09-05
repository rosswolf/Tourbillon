extends Entity
class_name BattlegroundEntity
static func _get_type_string():
	return "BattlegroundEntity"

func _get_type() -> Entity.EntityType:
	return Entity.EntityType.BATTLEGROUND

func __generate_instance_id() -> String:
	return "battleground_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())

func __requires_template_id() -> bool:
	return false

class BattlegroundEntityBuilder extends Entity.EntityBuilder:

	func build() -> BattlegroundEntity:
		var battleground: BattlegroundEntity = BattlegroundEntity.new()
		super.build_entity(battleground)
		return battleground
